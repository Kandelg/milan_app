-- ===========================================================================
-- Bihe & Date — Requests / Likes / Notifications migration
-- Run this AFTER schema.sql and features_migration.sql in the Supabase SQL
-- Editor.
--
-- Adds:
--   1. swipes.direction widened to also allow 'request'
--   2. notifications table (like / request / match) + indexes + realtime
--   3. RLS for notifications
--   4. record_swipe() extended to write notifications + treat requests as
--      mutual-positive signals
--   5. get_liked_me() / get_my_requests() / get_sent_requests() SECURITY
--      DEFINER RPCs so inbound likes & requests can be listed without leaking
--      the private swipes table (whose RLS only ever exposes a user's OWN
--      swipes)
--   6. mark_notifications_read()
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- 1. swipes.direction — allow the new 'request' status
-- ---------------------------------------------------------------------------
alter table public.swipes
  drop constraint if exists swipes_direction_check;

alter table public.swipes
  add constraint swipes_direction_check
  check (direction in ('pass', 'like', 'super_like', 'request'));

-- ---------------------------------------------------------------------------
-- 2. notifications
-- ---------------------------------------------------------------------------
-- One row per actionable event for the receiver (`user_id`). `actor_id` is
-- whoever caused it. `type` is 'like' | 'request' | 'match'. The unique key
-- de-dupes so re-swiping never spams the same notification.

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  actor_id uuid not null references public.profiles (id) on delete cascade,
  type text not null check (type in ('like', 'request', 'match')),
  is_read boolean not null default false,
  created_at timestamptz not null default now(),
  check (user_id <> actor_id),
  unique (user_id, actor_id, type)
);

-- List view: everything for a user, newest first, unread first.
create index if not exists notifications_user_idx
  on public.notifications (user_id, is_read, created_at desc);

create index if not exists notifications_actor_idx
  on public.notifications (actor_id);

-- ---------------------------------------------------------------------------
-- 3. Row Level Security
-- ---------------------------------------------------------------------------
-- You may only ever see / touch your OWN notifications. Inserts are done by
-- the SECURITY DEFINER functions below, never directly by clients.

alter table public.notifications enable row level security;

drop policy if exists "users read their own notifications" on public.notifications;
create policy "users read their own notifications"
  on public.notifications for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "users update their own notifications" on public.notifications;
create policy "users update their own notifications"
  on public.notifications for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "users delete their own notifications" on public.notifications;
create policy "users delete their own notifications"
  on public.notifications for delete
  to authenticated
  using (auth.uid() = user_id);

-- Realtime: let the app push new notifications / likes into the UI live.
alter publication supabase_realtime add table public.notifications;


-- ---------------------------------------------------------------------------
-- 4. record_swipe() — extended
-- ---------------------------------------------------------------------------
-- Same public contract as before ({ "matched": bool, "match_id": uuid|null }).
-- Differences:
--   * accepts 'request' as a direction
--   * treats an inbound 'like' OR 'request' as a positive reciprocation, so
--     accepting a request by liking back creates a match
--   * writes a notification on every meaningful action:
--       - mutual positive -> 'match' notification to BOTH users
--       - one-sided like -> 'like' notification to the target
--       - request         -> 'request' notification to the target

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
  v_is_request boolean := p_direction = 'request';
  v_reciprocated boolean := false;
  v_match_id uuid;
begin
  if v_me is null then
    raise exception 'Not authenticated';
  end if;

  if p_direction not in ('pass', 'like', 'super_like', 'request') then
    raise exception 'Invalid swipe direction: %', p_direction;
  end if;

  -- Idempotent: swiping the same person twice updates the direction.
  insert into public.swipes (swiper_id, target_id, direction)
  values (v_me, p_target_id, p_direction)
  on conflict (swiper_id, target_id)
  do update set direction = excluded.direction;

  -- A mutual connection happens when they already liked OR requested me.
  if v_is_positive then
    select exists (
      select 1 from public.swipes s
      where s.swiper_id = p_target_id
        and s.target_id = v_me
        and s.direction in ('like', 'super_like', 'request')
    ) into v_reciprocated;
  end if;

  if v_reciprocated then
    insert into public.matches (user_a, user_b)
    values (least(v_me, p_target_id), greatest(v_me, p_target_id))
    on conflict do nothing
    returning id into v_match_id;

    -- `on conflict do nothing` leaves the variable null when the row already
    -- existed; fall back to the existing id so the app can still open the chat.
    if v_match_id is null then
      select m.id into v_match_id
      from public.matches m
      where (m.user_a = least(v_me, p_target_id)
             and m.user_b = greatest(v_me, p_target_id));
    end if;

    -- Notify both sides that they are now connected.
    insert into public.notifications (user_id, actor_id, type)
    values (v_me, p_target_id, 'match')
    on conflict (user_id, actor_id, type) do nothing;

    insert into public.notifications (user_id, actor_id, type)
    values (p_target_id, v_me, 'match')
    on conflict (user_id, actor_id, type) do nothing;

  elsif v_is_positive then
    -- One-sided like: tell the target someone liked them.
    insert into public.notifications (user_id, actor_id, type)
    values (p_target_id, v_me, 'like')
    on conflict (user_id, actor_id, type) do nothing;

  elsif v_is_request then
    -- Connection request: tell the target they have a pending request.
    insert into public.notifications (user_id, actor_id, type)
    values (p_target_id, v_me, 'request')
    on conflict (user_id, actor_id, type) do nothing;
  end if;

  return json_build_object(
    'matched', v_reciprocated,
    'match_id', v_match_id
  );
end;

-- ---------------------------------------------------------------------------
-- 5. get_liked_me() — profiles that liked me, not yet matched
-- ---------------------------------------------------------------------------
-- Returns the same profile JSON shape as discover_profiles so the Flutter
-- model can reuse Profile.fromJson.

create or replace function public.get_liked_me(
  p_limit int default 30,
  p_offset int default 0
)
returns json
language sql
security definer
set search_path = public
as $$
  with me as (select auth.uid() as id),
  matched_ids as (
    select case when m.user_a = me.id then m.user_b else m.user_a end as id
    from public.matches m, me
    where me.id in (m.user_a, m.user_b)
  ),
  candidates as (
    select
      p.id, p.full_name, p.birth_date, p.gender, p.interested_in,
      p.bio, p.city, p.occupation, p.interests, p.photo_urls,
      extract(year from age(current_date, p.birth_date))::int as age
    from public.swipes s
    join public.profiles p on p.id = s.swiper_id
    cross join me
    where s.target_id = me.id
      and s.direction in ('like', 'super_like')
      and s.swiper_id not in (select id from matched_ids)
      and not exists (
        select 1 from public.blocks b
        where (b.blocker_id = me.id and b.blocked_id = p.id)
           or (b.blocker_id = p.id and b.blocked_id = me.id)
      )
    order by s.created_at desc
    limit p_limit offset p_offset
  )
  select coalesce(json_agg(to_json(candidates)), '[]'::json) from candidates;
$$;

-- ---------------------------------------------------------------------------
-- 6. get_my_requests() — pending inbound requests (not yet matched)
-- ---------------------------------------------------------------------------

create or replace function public.get_my_requests(
  p_limit int default 30,
  p_offset int default 0
)
returns json
language sql
security definer
set search_path = public
as $$
  with me as (select auth.uid() as id),
  matched_ids as (
    select case when m.user_a = me.id then m.user_b else m.user_a end as id
    from public.matches m, me
    where me.id in (m.user_a, m.user_b)
  ),
  candidates as (
    select
      p.id, p.full_name, p.birth_date, p.gender, p.interested_in,
      p.bio, p.city, p.occupation, p.interests, p.photo_urls,
      extract(year from age(current_date, p.birth_date))::int as age
    from public.swipes s
    join public.profiles p on p.id = s.swiper_id
    cross join me
    where s.target_id = me.id
      and s.direction = 'request'
      and s.swiper_id not in (select id from matched_ids)
      and not exists (
        select 1 from public.blocks b
        where (b.blocker_id = me.id and b.blocked_id = p.id)
           or (b.blocker_id = p.id and b.blocked_id = me.id)
      )
    order by s.created_at desc
    limit p_limit offset p_offset
  )
  select coalesce(json_agg(to_json(candidates)), '[]'::json) from candidates;
$$;

-- ---------------------------------------------------------------------------
-- 6b. get_sent_requests() — people I sent a pending 'request' to
-- ---------------------------------------------------------------------------
-- Only requests that have NOT yet become a match (once they accept, the pair
-- appears in `matches` and is dropped here). Although `swiper_id = auth.uid()`
-- is already RLS-readable, this RPC keeps the response shape identical to the
-- other tab functions and applies the matched / block filtering server-side.

create or replace function public.get_sent_requests(
  p_limit int default 30,
  p_offset int default 0
)
returns json
language sql
security definer
set search_path = public
as $$
  with me as (select auth.uid() as id),
  matched_ids as (
    select case when m.user_a = me.id then m.user_b else m.user_a end as id
    from public.matches m, me
    where me.id in (m.user_a, m.user_b)
  ),
  candidates as (
    select
      p.id, p.full_name, p.birth_date, p.gender, p.interested_in,
      p.bio, p.city, p.occupation, p.interests, p.photo_urls,
      extract(year from age(current_date, p.birth_date))::int as age
    from public.swipes s
    join public.profiles p on p.id = s.target_id
    cross join me
    where s.swiper_id = me.id
      and s.direction = 'request'
      and s.target_id not in (select id from matched_ids)
      and not exists (
        select 1 from public.blocks b
        where (b.blocker_id = me.id and b.blocked_id = p.id)
           or (b.blocker_id = p.id and b.blocked_id = me.id)
      )
    order by s.created_at desc
    limit p_limit offset p_offset
  )
  select coalesce(json_agg(to_json(candidates)), '[]'::json) from candidates;
$$;

-- ---------------------------------------------------------------------------
-- 7. mark_notifications_read()
-- ---------------------------------------------------------------------------

create or replace function public.mark_notifications_read()
returns void
language sql
security definer
set search_path = public
as $$
  update public.notifications
  set is_read = true
  where user_id = auth.uid()
    and is_read = false;
$$;
