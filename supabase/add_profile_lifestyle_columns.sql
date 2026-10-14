-- ===========================================================================
-- Bihe & Date — add missing lifestyle columns to `profiles`
--
-- WHY THIS EXISTS
-- The app started failing to save profiles with:
--   PostgrestException: Could not find the 'diet' column of 'profiles'
--   in the schema cache (code PGRST204)
--
-- That happens when the live database was created from an OLDER schema.sql
-- that predated these columns, so the ALTER block that ships inside
-- schema.sql was never applied. This script is the targeted, idempotent fix.
--
-- HOW TO RUN
--   1. Open your Supabase project -> SQL Editor -> New query.
--   2. Paste this entire file and click Run.
--   3. Wait a few seconds for PostgREST to reload its schema cache
--      (it usually happens automatically; if not, re-open the app).
--
-- It is 100% safe to re-run: every statement uses IF NOT EXISTS.
-- ===========================================================================

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

-- `phone` uses a NOT NULL DEFAULT so existing rows are back-filled with ''.
alter table public.profiles
  add column if not exists phone text not null default '';

-- Nudge PostgREST to reload its schema cache immediately (harmless if the
-- automatic reload already fired).
notify pgrst, 'reload schema';
