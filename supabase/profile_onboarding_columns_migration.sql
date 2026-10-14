-- Apply this migration to existing projects before deploying the updated app.
-- Keep these columns aligned with Profile.toUpsertJson() in lib/data/models.dart.
alter table public.profiles
  add column if not exists permanent_address text not null default '',
  add column if not exists current_location text not null default '',
  add column if not exists marital_status text,
  add column if not exists zodiac_sign text;