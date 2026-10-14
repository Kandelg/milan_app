-- ===========================================================================
-- Bihe & Date — feature migration
-- Run this AFTER the base schema.sql in the Supabase SQL Editor.
--
-- Adds:
--   1. blocks   — user A hides user B (bidirectional filtering)
--   2. reports  — user A reports user B with a reason
--   3. RLS policies for both tables
--   4. discover_profiles() updated to skip blocked users
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- 1. blocks
-- ---------------------------------------------------------------------------

create table if not exists public.blocks (
  id uuid primary key default gen_random_uuid(),
  blocker_id uuid not null references public.profiles (id) on delete cascade,
  blocked_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);

create index if not exists blocks_blocked_idx on public.blocks (blocked_id);

-- ---------------------------------------------------------------------------
-- 2. reports
-- ---------------------------------------------------------------------------

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles (id) on delete cascade,
  reported_id uuid not null references public.profiles (id) on delete cascade,
  reason text not null default '',
  created_at timestamptz not null default now(),
  unique (reporter_id, reported_id),
  check (reporter_id <> reported_id),
  check (length(reason) <= 500)
);

create index if not exists reports_reported_idx on public.reports (reported_id);

-- ---------------------------------------------------------------------------
-- 3. Row Level Security
-- ---------------------------------------------------------------------------

alter table public.blocks enable row level security;
alter table public.reports enable row level security;

-- blocks: you manage only your own block list.
drop policy if exists "users read their own blocks" on public.blocks;
create policy "users read their own blocks"
  on public.blocks for select
  to authenticated
  using (auth.uid() = blocker_id);

drop policy if exists "users insert their own blocks" on public.blocks;
create policy "users insert their own blocks"
  on public.blocks for insert
  to authenticated
  with check (auth.uid() = blocker_id);

drop policy if exists "users delete their own blocks" on public.blocks;
create policy "users delete their own blocks"
  on public.blocks for delete
  to authenticated
  using (auth.uid() = blocker_id);

-- reports: you can only create and view your own reports (admins use the
-- service role to review them).
drop policy if exists "users read their own reports" on public.reports;
create policy "users read their own reports"
  on public.reports for select
  to authenticated
  using (auth.uid() = reporter_id);

drop policy if exists "users insert their own reports" on public.reports;
create policy "users insert their own reports"
  on public.reports for insert
  to authenticated
  with check (auth.uid() = reporter_id);


-- ---------------------------------------------------------------------------
-- 4. discover_profiles() — updated to skip blocked users (both directions)
-- ---------------------------------------------------------------------------
-- Replaces the base definition. Everything else is identical; we only add the
-- "not blocked either way" predicate so blocked people never show up again.

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
      and (p_city is null or p.city ilike '%' || p_city || '%')
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
      -- NEW: never show anyone blocked in either direction.
      and not exists (
        select 1 from public.blocks b
        where (b.blocker_id = me.id and b.blocked_id = p.id)
           or (b.blocker_id = p.id and b.blocked_id = me.id)
      )
    order by p.updated_at desc
    limit p_limit offset p_offset
  )
  select coalesce(json_agg(to_json(candidates)), '[]'::json) from candidates;
$$;
