-- ===========================================================================
-- Bihe & Date — feedback migration
-- Run this in the Supabase SQL Editor.
--
-- Adds a `feedbacks` table for the "Send Feedback" tile in Settings, with RLS
-- that lets any authenticated user insert their own rows. Reading feedback is
-- intentionally not granted to clients (moderators use the service role).
-- ===========================================================================

create table if not exists public.feedbacks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles (id) on delete set null,
  message text not null check (length(message) between 1 and 2000),
  created_at timestamptz not null default now()
);

-- Newest first, and fast lookups per user.
create index if not exists feedbacks_created_idx
  on public.feedbacks (created_at desc);
create index if not exists feedbacks_user_idx
  on public.feedbacks (user_id);

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table public.feedbacks enable row level security;

-- Authenticated users may insert feedback. The row must carry either their own
-- id or be anonymous (user_id null) — they cannot forge someone else's id.
drop policy if exists "users insert their own feedback" on public.feedbacks;
create policy "users insert their own feedback"
  on public.feedbacks for insert
  to authenticated
  with check (auth.uid() = user_id or user_id is null);

-- No SELECT/UPDATE/DELETE policies are added: clients can only write, never
-- read feedback back. Review happens with the service role on the server.
