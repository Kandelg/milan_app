-- ===========================================================================
-- Bihe & Date — matches_with_details view migration
-- Run this in the Supabase SQL Editor.
--
-- Fixes: PostgresException PGRST205 "Could not find the table
--        'public.matches_with_details' in the schema cache".
--
-- This view flattens a match into both participant profiles (as JSON), the
-- newest message (as a JSON array) and the unread count, so the Flutter
-- realtime stream (MatchRepository.watchMatches) can read one row per match.
--
-- IMPORTANT: the view is created WITH (security_invoker = true) so the
-- row-level policies on `matches`, `profiles` and `messages` STILL APPLY to
-- the calling user. Without this, the view would run as its owner (postgres)
-- and leak every user's matches and messages.
-- ===========================================================================

create or replace view public.matches_with_details
with (security_invoker = true) as
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
-- Grants: let signed-in users read the view.
-- ---------------------------------------------------------------------------
-- A view does not carry RLS itself; with security_invoker the SELECT runs
-- under the caller and the base-table policies filter the rows. We only need
-- to grant SELECT on the view object to `authenticated`.
grant select on public.matches_with_details to authenticated;

-- ---------------------------------------------------------------------------
-- Realtime: publish the view so the Dart `.stream()` receives live updates.
-- ---------------------------------------------------------------------------
-- Idempotent: only add it if it is not already a member of the publication
-- (avoids the "already member of publication" error on re-runs).
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'matches_with_details'
  ) then
    alter publication supabase_realtime add table public.matches_with_details;
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- Verify (should return 1 row):
--   select table_name, table_type
--   from information_schema.tables
--   where table_name = 'matches_with_details';   -- 'matches_with_details' | VIEW
--
-- Verify security mode is invoker (should be 't' for security_invoker):
--   select relname, reloptions
--   from pg_class where relname = 'matches_with_details';
-- ---------------------------------------------------------------------------
