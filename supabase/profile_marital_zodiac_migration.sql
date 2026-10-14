-- Add the required onboarding profile fields.
alter table public.profiles
  add column if not exists marital_status text,
  add column if not exists zodiac_sign text;

-- Keep persisted values aligned with the Flutter dropdown options.
alter table public.profiles
  drop constraint if exists profiles_marital_status_check;
alter table public.profiles
  add constraint profiles_marital_status_check
  check (
    marital_status is null
    or marital_status in ('Unmarried', 'Divorced', 'Widowed')
  );

alter table public.profiles
  drop constraint if exists profiles_zodiac_sign_check;
alter table public.profiles
  add constraint profiles_zodiac_sign_check
  check (
    zodiac_sign is null
    or zodiac_sign in (
      'Aries (मेष)', 'Taurus (वृष)', 'Gemini (मिथुन)', 'Cancer (कर्कट)',
      'Leo (सिंह)', 'Virgo (कन्या)', 'Libra (तुला)', 'Scorpio (वृश्चिक)',
      'Sagittarius (धनु)', 'Capricorn (मकर)', 'Aquarius (कुम्भ)', 'Pisces (मीन)'
    )
  );

-- Users can update only their own profile row. This replaces the existing
-- equivalent policy so the migration is self-contained and repeatable.
alter table public.profiles enable row level security;
drop policy if exists "users update their own profile" on public.profiles;
create policy "users update their own profile"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);