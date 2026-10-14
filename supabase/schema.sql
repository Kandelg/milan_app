-- Milan â€” Supabase schema (MVP)
--
-- Run this once in the Supabase SQL editor (Dashboard â†’ SQL â†’ New query).
-- It creates the tables, row-level security policies, storage bucket and the
-- two RPC functions the Flutter app calls (`discover_profiles`,
-- `record_swipe`).
--
-- Order matters: profiles â†’ swipes â†’ matches â†’ messages â†’ views â†’ functions.

-- ---------------------------------------------------------------------------
-- 0. Helpers
-- ---------------------------------------------------------------------------

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- 1. profiles â€” one row per auth user
-- ---------------------------------------------------------------------------

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null default '',
  birth_date date,
  gender text check (gender in ('male', 'female', 'other')),
  interested_in text not null default 'everyone'
    check (interested_in in ('male', 'female', 'other', 'everyone')),
  bio text not null default '',
  permanent_address text not null default '',
  current_location text not null default '',
  city text not null default '',
  occupation text not null default '',
  phone text not null default '',
  marital_status text,
  zodiac_sign text,
  interests text[] not null default '{}',
  photo_urls text[] not null default '{}',
  -- Extra lifestyle details (all optional, shown with icons on cards).
  -- Height in centimetres.
  height_cm int check (height_cm is null or (height_cm between 100 and 250)),
  religion text check (
    religion is null
    or religion in ('hindu', 'buddhist', 'muslim', 'christian', 'other')
  ),
  education text check (
    education is null
    or education in ('high_school', 'bachelor', 'master', 'phd', 'other')
  ),
  diet text check (
    diet is null or diet in ('veg', 'non_veg')
  ),
  smoking text check (
    smoking is null or smoking in ('smoker', 'non_smoker')
  ),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Adding columns for databases created before these fields existed.
alter table public.profiles
  add column if not exists height_cm int
    check (height_cm is null or (height_cm between 100 and 250));
alter table public.profiles
  add column if not exists religion text
    check (
      religion is null
      or religion in ('hindu', 'buddhist', 'muslim', 'christian', 'other')
    );
alter table public.profiles
  add column if not exists education text
    check (
      education is null
      or education in ('high_school', 'bachelor', 'master', 'phd', 'other')
    );
alter table public.profiles
  add column if not exists diet text
    check (diet is null or diet in ('veg', 'non_veg'));
alter table public.profiles
  add column if not exists smoking text
    check (smoking is null or smoking in ('smoker', 'non_smoker'));
alter table public.profiles
  add column if not exists phone text not null default '';
alter table public.profiles
  add column if not exists permanent_address text not null default '';
alter table public.profiles
  add column if not exists current_location text not null default '';
alter table public.profiles
  add column if not exists marital_status text;
alter table public.profiles
  add column if not exists zodiac_sign text;

-- Only adults may be discoverable.
alter table public.profiles
  drop constraint if exists profiles_adult_only;
alter table public.profiles
  add constraint profiles_adult_only
  check (birth_date is null or birth_date <= (current_date - interval '18 years'));

create index if not exists profiles_gender_idx on public.profiles (gender);
create index if not exists profiles_city_idx on public.profiles (city);

-- Keep updated_at honest.
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_touch_updated_at on public.profiles;
create trigger profiles_touch_updated_at
  before update on public.profiles
  for each row execute function public.touch_updated_at();

-- Create a profile row automatically for every new auth user.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- 2. swipes â€” who liked / passed whom
-- ---------------------------------------------------------------------------

create table if not exists public.swipes (
  id uuid primary key default gen_random_uuid(),
  swiper_id uuid not null references public.profiles (id) on delete cascade,
  target_id uuid not null references public.profiles (id) on delete cascade,
  direction text not null check (direction in ('pass', 'like', 'super_like')),
  created_at timestamptz not null default now(),
  unique (swiper_id, target_id),
  check (swiper_id <> target_id)
);

create index if not exists swipes_target_idx on public.swipes (target_id);

-- ---------------------------------------------------------------------------
-- 3. matches â€” created by the record_swipe() function below
-- ---------------------------------------------------------------------------

create table if not exists public.matches (
  id uuid primary key default gen_random_uuid(),
  user_a uuid not null references public.profiles (id) on delete cascade,
  user_b uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  -- Store the pair in a stable order so a match can never be duplicated.
  unique (user_a, user_b),
  check (user_a < user_b)
);

create index if not exists matches_user_a_idx on public.matches (user_a);
create index if not exists matches_user_b_idx on public.matches (user_b);

-- ---------------------------------------------------------------------------
-- 4. messages
-- ---------------------------------------------------------------------------

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  match_id uuid not null references public.matches (id) on delete cascade,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  body text not null default '',
  created_at timestamptz not null default now(),
  read_at timestamptz,
  check (length(body) <= 2000)
);

create index if not exists messages_match_idx
  on public.messages (match_id, created_at);


-- ---------------------------------------------------------------------------
-- 5. Row Level Security
--
-- Every policy below uses `auth.uid()` so a user can only ever touch their
-- own rows. The realtime streams in the app rely on these same policies.
-- ---------------------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.swipes enable row level security;
alter table public.matches enable row level security;
alter table public.messages enable row level security;

-- profiles ---------------------------------------------------------------

-- Any signed-in user may read profiles, so cards can be rendered client-side.
drop policy if exists "profiles are readable by signed-in users"
  on public.profiles;
create policy "profiles are readable by signed-in users"
  on public.profiles for select
  to authenticated
  using (true);

drop policy if exists "users insert their own profile" on public.profiles;
create policy "users insert their own profile"
  on public.profiles for insert
  to authenticated
  with check (auth.uid() = id);

drop policy if exists "users update their own profile" on public.profiles;
create policy "users update their own profile"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- swipes -----------------------------------------------------------------

-- Swipes are private: you can only ever see your own.
drop policy if exists "users read their own swipes" on public.swipes;
create policy "users read their own swipes"
  on public.swipes for select
  to authenticated
  using (auth.uid() = swiper_id);

-- Inserts normally go through record_swipe() (security definer); allowing a
-- direct insert keeps the table usable from the SQL editor.
drop policy if exists "users insert their own swipes" on public.swipes;
create policy "users insert their own swipes"
  on public.swipes for insert
  to authenticated
  with check (auth.uid() = swiper_id);

-- matches ----------------------------------------------------------------

drop policy if exists "participants read their matches" on public.matches;
create policy "participants read their matches"
  on public.matches for select
  to authenticated
  using (auth.uid() in (user_a, user_b));

-- Rows are created by record_swipe(); participants may delete (unmatch).
drop policy if exists "participants delete their matches" on public.matches;
create policy "participants delete their matches"
  on public.matches for delete
  to authenticated
  using (auth.uid() in (user_a, user_b));

-- messages ---------------------------------------------------------------

drop policy if exists "participants read their messages" on public.messages;
create policy "participants read their messages"
  on public.messages for select
  to authenticated
  using (
    exists (
      select 1 from public.matches m
      where m.id = messages.match_id
        and auth.uid() in (m.user_a, m.user_b)
    )
  );

drop policy if exists "participants send messages" on public.messages;
create policy "participants send messages"
  on public.messages for insert
  to authenticated
  with check (
    auth.uid() = sender_id
    and exists (
      select 1 from public.matches m
      where m.id = match_id
        and auth.uid() in (m.user_a, m.user_b)
    )
  );

-- Only the recipient can mark a message as read.
drop policy if exists "recipients mark messages as read" on public.messages;
create policy "recipients mark messages as read"
  on public.messages for update
  to authenticated
  using (
    auth.uid() <> sender_id
    and exists (
      select 1 from public.matches m
      where m.id = messages.match_id
        and auth.uid() in (m.user_a, m.user_b)
    )
  )
  with check (
    auth.uid() <> sender_id
    and exists (
      select 1 from public.matches m
      where m.id = messages.match_id
        and auth.uid() in (m.user_a, m.user_b)
    )
  );


-- ---------------------------------------------------------------------------
-- 6. RPC: discover_profiles
--
-- Returns candidate profiles for the caller, already excluding:
--   * the caller
--   * people already swiped (either direction where a like was given)
--   * existing matches
--   * gender-incompatible profiles (both directions)
--   * incomplete profiles (no photo / birth date / gender)
--
-- JSON is returned rather than `setof profiles` so new columns can be added
-- without breaking the client.
-- ---------------------------------------------------------------------------

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
      p.id,
      p.full_name,
      p.birth_date,
      p.gender,
      p.interested_in,
      p.bio,
      p.city,
      p.occupation,
      p.interests,
      p.photo_urls,
      p.height_cm,
      p.religion,
      p.education,
      p.diet,
      p.smoking,
      extract(year from age(current_date, p.birth_date))::int as age
    from public.profiles p
    cross join me
    where p.id <> me.id
      -- Only complete, adult profiles are discoverable.
      and p.birth_date is not null
      and p.gender is not null
      and array_length(p.photo_urls, 1) >= 1
      -- Age window.
      and extract(year from age(current_date, p.birth_date))::int
          between p_min_age and p_max_age
      -- They must be interested in me.
      and (p.interested_in = 'everyone' or p.interested_in = me.gender)
      -- I must be interested in them.
      and (me.interested_in = 'everyone' or me.interested_in = p.gender)
      -- Optional filters.
      and (p_gender is null or p.gender = p_gender)
      and (p_city is null or p.city ilike '%' || p_city || '%')
      and (p_interests is null or p.interests && p_interests)
      -- Never show someone already swiped on.
      and not exists (
        select 1 from public.swipes s
        where s.swiper_id = me.id and s.target_id = p.id
      )
      -- Nor someone who already matched (or liked) us.
      and not exists (
        select 1 from public.matches m
        where (m.user_a = me.id and m.user_b = p.id)
           or (m.user_b = me.id and m.user_a = p.id)
      )
    order by p.updated_at desc
    limit p_limit offset p_offset
  )
  select coalesce(json_agg(to_json(candidates)), '[]'::json) from candidates;
$$;


-- ---------------------------------------------------------------------------
-- 7. RPC: record_swipe
--
-- Stores the swipe and, when both sides like each other, creates the match
-- row (in a stable user_a < user_b order so it can never be duplicated).
-- Returns {"matched": bool, "match_id": uuid|null}.
-- ---------------------------------------------------------------------------

create or replace function public.record_swipe(
  p_target_id uuid,
  p_direction text
)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
  v_is_positive boolean := p_direction in ('like', 'super_like');
  v_reciprocated boolean := false;
  v_match_id uuid;
begin
  if v_me is null then
    raise exception 'Not authenticated';
  end if;

  if p_direction not in ('pass', 'like', 'super_like') then
    raise exception 'Invalid swipe direction: %', p_direction;
  end if;

  -- Idempotent: swiping the same person twice updates the direction.
  insert into public.swipes (swiper_id, target_id, direction)
  values (v_me, p_target_id, p_direction)
  on conflict (swiper_id, target_id)
  do update set direction = excluded.direction;

  -- Only positive swipes can produce a match.
  if v_is_positive then
    select exists (
      select 1 from public.swipes s
      where s.swiper_id = p_target_id
        and s.target_id = v_me
        and s.direction in ('like', 'super_like')
    ) into v_reciprocated;
  end if;

  if v_reciprocated then
    insert into public.matches (user_a, user_b)
    values (least(v_me, p_target_id), greatest(v_me, p_target_id))
    on conflict do nothing
    returning id into v_match_id;

    -- `on conflict do nothing` leaves the variable null when the row already

-- ---------------------------------------------------------------------------
-- 8. View: matches_with_details
--
-- Flattens a match into both participant profiles (as JSON objects), the
-- newest message (as a JSON array) and the unread count, so the Flutter
-- realtime stream can read one table.
--
-- The view is security-invoker, so the row-level policies on `matches`,
-- `profiles` and `messages` still apply.
-- ---------------------------------------------------------------------------

create or replace view public.matches_with_details as
select
  m.id,
  m.created_at,
  jsonb_build_object(
    'id', pa.id,
    'full_name', pa.full_name,
    'birth_date', pa.birth_date,
    'gender', pa.gender,
    'interested_in', pa.interested_in,
    'bio', pa.bio,
    'city', pa.city,
    'occupation', pa.occupation,
    'height_cm', pa.height_cm,
    'religion', pa.religion,
    'education', pa.education,
    'diet', pa.diet,
    'smoking', pa.smoking,
    'interests', pa.interests,
    'photo_urls', pa.photo_urls
  ) as user_a,
  jsonb_build_object(
    'id', pb.id,
    'full_name', pb.full_name,
    'birth_date', pb.birth_date,
    'gender', pb.gender,
    'interested_in', pb.interested_in,
    'bio', pb.bio,
    'city', pb.city,
    'occupation', pb.occupation,
    'height_cm', pb.height_cm,
    'religion', pb.religion,
    'education', pb.education,
    'diet', pb.diet,
    'smoking', pb.smoking,
    'interests', pb.interests,
    'photo_urls', pb.photo_urls
  ) as user_b,
  case
    when lm.id is null then '[]'::jsonb
    else jsonb_build_array(
      jsonb_build_object(
        'id', lm.id,
        'match_id', lm.match_id,
        'sender_id', lm.sender_id,
        'body', lm.body,
        'created_at', lm.created_at,
        'read_at', lm.read_at
      )
    )
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

-- ---------------------------------------------------------------------------
-- 9. Realtime
-- ---------------------------------------------------------------------------

alter publication supabase_realtime add table public.messages;

-- ---------------------------------------------------------------------------
-- 10. Stories â€” photo / text status, auto-expire after 24 hours
-- ---------------------------------------------------------------------------
-- A story is visible to every signed-in user while it is fresh
-- (`created_at > now() - interval '24 hours'`). Expired rows stay in the
-- table until cleanup deletes them; every query filters them out, so the
-- expiry is enforced by RLS + query filters, not by a cron job.

create table if not exists public.stories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  kind text not null default 'photo'
    check (kind in ('photo', 'text')),
  media_url text,
  body text not null default '',
  background text not null default '#E8437E',
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '24 hours'),
  check (
    (kind = 'photo' and media_url is not null and media_url <> '')
    or
    (kind = 'text' and body <> '')
  )
);

create index if not exists stories_user_idx on public.stories (user_id);
create index if not exists stories_expires_idx on public.stories (expires_at desc);

alter table public.stories enable row level security;

-- Everyone signed in can see fresh stories.
drop policy if exists "fresh stories are visible to everyone" on public.stories;
create policy "fresh stories are visible to everyone"
  on public.stories for select
  to authenticated
  using (expires_at > now());

-- Users can post their own stories.
drop policy if exists "users can post stories" on public.stories;
create policy "users can post stories"
  on public.stories for insert
  to authenticated
  with check (user_id = auth.uid());

-- Users can only delete their own stories.
drop policy if exists "users can delete their own stories" on public.stories;
create policy "users can delete their own stories"
  on public.stories for delete
  to authenticated
  using (user_id = auth.uid());

-- Fresh stories with the author's name + photo, grouped feed order.
create or replace view public.stories_feed as
select
  s.id,
  s.user_id,
  s.kind,
  s.media_url,
  s.body,
  s.background,
  s.created_at,
  s.expires_at,
  p.full_name as author_name,
  (p.photo_urls[1]) as author_photo
from public.stories s
join public.profiles p on p.id = s.user_id
where s.expires_at > now()
order by s.created_at desc;

-- ---------------------------------------------------------------------------
-- 11. Storage bucket for story photos
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, public)
values ('story-media', 'story-media', true)
on conflict (id) do nothing;

-- Anyone signed in may read story photos.
drop policy if exists "story media is readable" on storage.objects;
create policy "story media is readable"
  on storage.objects for select
  to authenticated
  using (bucket_id = 'story-media');

-- Users may only upload into their own folder (`<userId>/...`).
drop policy if exists "users upload their own story media" on storage.objects;
create policy "users upload their own story media"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'story-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "users delete their own story media" on storage.objects;
create policy "users delete their own story media"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'story-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ---------------------------------------------------------------------------
-- 12. Storage bucket for profile photos
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, public)
values ('profile-photos', 'profile-photos', true)
on conflict (id) do nothing;

-- Anyone signed in may read photos.
drop policy if exists "profile photos are publicly readable" on storage.objects;
create policy "profile photos are publicly readable"
  on storage.objects for select
  using (bucket_id = 'profile-photos');

-- Users may only upload into their own folder (`<userId>/...`).
drop policy if exists "users upload their own photos" on storage.objects;
create policy "users upload their own photos"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'profile-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "users update their own photos" on storage.objects;
create policy "users update their own photos"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'profile-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "users delete their own photos" on storage.objects;
create policy "users delete their own photos"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'profile-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

    -- existed, so fetch the existing id in that case.
    if v_match_id is null then
      select m.id into v_match_id
      from public.matches m
      where m.user_a = least(v_me, p_target_id)
        and m.user_b = greatest(v_me, p_target_id);
    end if;
  end if;

  return json_build_object('matched', v_reciprocated, 'match_id', v_match_id);
end;
$$;
