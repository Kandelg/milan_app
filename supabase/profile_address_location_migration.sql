-- Rename the old public city field to the user's fixed/permanent address.
-- Keep a separate current-location field for the user's selected/derived area.
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'profiles'
      and column_name = 'city'
  ) and not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'profiles'
      and column_name = 'permanent_address'
  ) then
    alter table public.profiles rename column city to permanent_address;
  elsif not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'profiles'
      and column_name = 'permanent_address'
  ) then
    alter table public.profiles
      add column permanent_address text not null default '';
  end if;
end $$;

alter table public.profiles
  add column if not exists current_location text not null default '';

-- Existing city values represented the discoverable city, so preserve them as
-- current location when the new column is first introduced or still blank.
update public.profiles
set current_location = permanent_address
where current_location = '' and permanent_address <> '';

drop index if exists public.profiles_city_idx;
create index if not exists profiles_current_location_idx
  on public.profiles (current_location);

-- Keep the old RPC parameter and JSON city key compatible with app versions,
-- but use current_location for filtering and profile-card location display.
create or replace function public.discover_profiles(
  p_min_age int default 18,
  p_max_age int default 60,
  p_gender text default null,
  p_city text default null,
  p_interests text[] default null,
  p_limit int default 20,
  p_offset int default 0
)
returns json
language sql
security invoker
stable
as $$
  with me as (
    select id, gender, interested_in
    from public.profiles
    where id = auth.uid()
  ),
  candidates as (
    select
      p.id, p.full_name, p.birth_date, p.gender, p.interested_in, p.bio,
      p.current_location as city, p.occupation, p.interests, p.photo_urls,
      p.height_cm, p.religion, p.education, p.diet, p.smoking,
      p.marital_status, p.zodiac_sign,
      extract(year from age(current_date, p.birth_date))::int as age
    from public.profiles p
    cross join me
    where p.id <> me.id
      and p.birth_date is not null
      and p.gender is not null
      and array_length(p.photo_urls, 1) >= 1
      and extract(year from age(current_date, p.birth_date))::int
          between p_min_age and p_max_age
      and (p.interested_in = 'everyone' or p.interested_in = me.gender)
      and (me.interested_in = 'everyone' or me.interested_in = p.gender)
      and (p_gender is null or p.gender = p_gender)
      and (p_city is null or p.current_location ilike '%' || p_city || '%')
      and (p_interests is null or p.interests && p_interests)
      and not exists (
        select 1 from public.swipes s
        where s.swiper_id = me.id and s.target_id = p.id
      )
      and not exists (
        select 1 from public.matches m
        where (m.user_a = me.id and m.user_b = p.id)
           or (m.user_b = me.id and m.user_a = p.id)
      )
      and not exists (
        select 1 from public.blocks b
        where (b.blocker_id = me.id and b.blocked_id = p.id)
           or (b.blocker_id = p.id and b.blocked_id = me.id)
      )
    order by p.updated_at desc
    limit p_limit offset p_offset
  )
  select coalesce(json_agg(to_json(candidates)), '[]'::json)
  from candidates;
$$;

-- Recreate match view JSON with the new columns, retaining `city` as a legacy
-- alias for clients that still expect it.
create or replace view public.matches_with_details
with (security_invoker = true) as
select
  m.id,
  m.created_at,
  jsonb_build_object(
    'id', pa.id, 'full_name', pa.full_name, 'birth_date', pa.birth_date,
    'gender', pa.gender, 'interested_in', pa.interested_in, 'bio', pa.bio,
    'city', pa.current_location, 'permanent_address', pa.permanent_address,
    'current_location', pa.current_location, 'occupation', pa.occupation,
    'height_cm', pa.height_cm, 'religion', pa.religion,
    'education', pa.education, 'diet', pa.diet, 'smoking', pa.smoking,
    'marital_status', pa.marital_status, 'zodiac_sign', pa.zodiac_sign,
    'interests', pa.interests, 'photo_urls', pa.photo_urls
  ) as user_a,
  jsonb_build_object(
    'id', pb.id, 'full_name', pb.full_name, 'birth_date', pb.birth_date,
    'gender', pb.gender, 'interested_in', pb.interested_in, 'bio', pb.bio,
    'city', pb.current_location, 'permanent_address', pb.permanent_address,
    'current_location', pb.current_location, 'occupation', pb.occupation,
    'height_cm', pb.height_cm, 'religion', pb.religion,
    'education', pb.education, 'diet', pb.diet, 'smoking', pb.smoking,
    'marital_status', pb.marital_status, 'zodiac_sign', pb.zodiac_sign,
    'interests', pb.interests, 'photo_urls', pb.photo_urls
  ) as user_b,
  case
    when lm.id is null then '[]'::jsonb
    else jsonb_build_array(jsonb_build_object(
      'id', lm.id, 'match_id', lm.match_id, 'sender_id', lm.sender_id,
      'body', lm.body, 'created_at', lm.created_at, 'read_at', lm.read_at
    ))
  end as last_message,
  (
    select count(*)::int
    from public.messages msg
    where msg.match_id = m.id
      and msg.read_at is null
      and msg.sender_id <> auth.uid()
  ) as unread_count
from public.matches m
join public.profiles pa on pa.id = m.user_a
join public.profiles pb on pb.id = m.user_b
left join lateral (
  select * from public.messages msg
  where msg.match_id = m.id
  order by msg.created_at desc
  limit 1
) lm on true;

grant select on public.matches_with_details to authenticated;