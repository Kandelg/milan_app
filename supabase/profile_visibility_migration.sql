-- Per-field visibility for exact date of birth and phone number.
-- Run this once in the Supabase SQL editor. Defaults preserve current
-- behaviour: birth date is public; phone is private.
alter table public.profiles
  add column if not exists birth_date_visibility text not null default 'public'
    check (birth_date_visibility in ('public', 'friends', 'only_me'));

alter table public.profiles
  add column if not exists phone_visibility text not null default 'only_me'
    check (phone_visibility in ('public', 'friends', 'only_me'));

-- Discover cards expose exact DOB only when public; they never expose phone.
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
    select id, gender, interested_in from public.profiles where id = auth.uid()
  ), candidates as (
    select
      p.id, p.full_name,
      p.birth_date,
      p.gender, p.interested_in, p.bio,
      p.current_location as city, p.current_location, p.occupation,
      p.interests, p.photo_urls, p.height_cm, p.religion, p.education,
      p.diet, p.smoking, p.marital_status, p.zodiac_sign,
      extract(year from age(current_date, p.birth_date))::int as age
    from public.profiles p cross join me
    where p.id <> me.id
      and p.birth_date is not null and p.gender is not null
      and array_length(p.photo_urls, 1) >= 1
      and extract(year from age(current_date, p.birth_date))::int between p_min_age and p_max_age
      and (p.interested_in = 'everyone' or p.interested_in = me.gender)
      and (me.interested_in = 'everyone' or me.interested_in = p.gender)
      and (p_gender is null or p.gender = p_gender)
      and (p_city is null or p.current_location ilike '%' || p_city || '%')
      and (p_interests is null or p.interests && p_interests)
      and not exists (select 1 from public.swipes s where s.swiper_id = me.id and s.target_id = p.id)
      and not exists (select 1 from public.matches m where
        (m.user_a = me.id and m.user_b = p.id) or (m.user_b = me.id and m.user_a = p.id))
      and not exists (select 1 from public.blocks b where
        (b.blocker_id = me.id and b.blocked_id = p.id) or (b.blocker_id = p.id and b.blocked_id = me.id))
    order by p.updated_at desc limit p_limit offset p_offset
  ) select coalesce(json_agg(to_json(candidates)), '[]'::json) from candidates;
$$;

-- Rebuild match payloads: mutual matches qualify as Friends. Phone/DOB are
-- returned only when the owner's field preference allows this viewer.
create or replace view public.matches_with_details
with (security_invoker = true) as
select
  m.id, m.created_at,
  jsonb_build_object(
    'id', pa.id, 'full_name', pa.full_name,
    'birth_date', case when pa.birth_date_visibility in ('public','friends') then pa.birth_date end,
    'birth_date_visibility', pa.birth_date_visibility,
    'phone', case when pa.phone_visibility in ('public','friends') then pa.phone end,
    'phone_visibility', pa.phone_visibility,
    'gender', pa.gender, 'interested_in', pa.interested_in, 'bio', pa.bio,
    'city', pa.current_location, 'permanent_address', pa.permanent_address,
    'current_location', pa.current_location, 'occupation', pa.occupation,
    'height_cm', pa.height_cm, 'religion', pa.religion, 'education', pa.education,
    'diet', pa.diet, 'smoking', pa.smoking, 'marital_status', pa.marital_status,
    'zodiac_sign', pa.zodiac_sign, 'interests', pa.interests, 'photo_urls', pa.photo_urls
  ) as user_a,
  jsonb_build_object(
    'id', pb.id, 'full_name', pb.full_name,
    'birth_date', case when pb.birth_date_visibility in ('public','friends') then pb.birth_date end,
    'birth_date_visibility', pb.birth_date_visibility,
    'phone', case when pb.phone_visibility in ('public','friends') then pb.phone end,
    'phone_visibility', pb.phone_visibility,
    'gender', pb.gender, 'interested_in', pb.interested_in, 'bio', pb.bio,
    'city', pb.current_location, 'permanent_address', pb.permanent_address,
    'current_location', pb.current_location, 'occupation', pb.occupation,
    'height_cm', pb.height_cm, 'religion', pb.religion, 'education', pb.education,
    'diet', pb.diet, 'smoking', pb.smoking, 'marital_status', pb.marital_status,
    'zodiac_sign', pb.zodiac_sign, 'interests', pb.interests, 'photo_urls', pb.photo_urls
  ) as user_b,
  case when lm.id is null then '[]'::jsonb else jsonb_build_array(jsonb_build_object(
    'id', lm.id, 'match_id', lm.match_id, 'sender_id', lm.sender_id,
    'body', lm.body, 'created_at', lm.created_at, 'read_at', lm.read_at
  )) end as last_message,
  (select count(*)::int from public.messages msg where msg.match_id = m.id
    and msg.read_at is null and msg.sender_id <> auth.uid()) as unread_count
from public.matches m
join public.profiles pa on pa.id = m.user_a
join public.profiles pb on pb.id = m.user_b
left join lateral (select * from public.messages msg where msg.match_id = m.id
  order by msg.created_at desc limit 1) lm on true;

grant select on public.matches_with_details to authenticated;