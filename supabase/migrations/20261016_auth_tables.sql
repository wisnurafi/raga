-- Raga: account tables for the optional Google login.
--
-- Run ONCE in the Supabase SQL Editor (safe to re-run: every statement is
-- idempotent). Apply BEFORE installing an APK built with the matching
-- client code — until these exist, login sync calls fail loudly.
--
-- What this adds:
--   profiles : one row per logged-in user (display name, avatar, leaderboard
--              opt-in). This is the ACCOUNT profile, unrelated to the app's
--              local multi-profile (family members) feature.
--   records  : relational per-user weight history. The cross-device source
--              of truth once logged in. The anonymous bmi_records +
--              backup-code path keeps working untouched in both modes.
--   avatars  : public Storage bucket for custom profile photos.
--
-- Security: every user table is RLS-locked to its owner
-- (auth.uid() = user_id). The avatars bucket is public-read (needed later
-- for the leaderboard) but only the owner can write/delete, enforced by
-- the <user_id>/... path convention.

-- ------------------------------------------------------------ profiles
create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  avatar_url text,
  leaderboard_opt_in boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "own rows" on public.profiles;
create policy "own rows"
  on public.profiles
  for all
  to public
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ------------------------------------------------------------ records
create table if not exists public.records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  client_id text,
  profile_id text not null,
  height_cm double precision not null,
  weight_kg double precision not null,
  bmi double precision not null,
  category text not null,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.records enable row level security;

drop policy if exists "own rows" on public.records;
create policy "own rows"
  on public.records
  for all
  to public
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Stable upsert key, same pattern as bmi_records: the app upserts with
-- onConflict: 'client_id', so a retry after a crash never duplicates rows.
create unique index if not exists records_client_id_key
  on public.records (client_id);

create index if not exists records_user_id_created_idx
  on public.records (user_id, created_at desc);

-- Keep updated_at honest without client cooperation.
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_profiles_touch on public.profiles;
create trigger trg_profiles_touch
  before update on public.profiles
  for each row execute function public.touch_updated_at();

drop trigger if exists trg_records_touch on public.records;
create trigger trg_records_touch
  before update on public.records
  for each row execute function public.touch_updated_at();

-- ------------------------------------------------------------ fix anon-only grants
-- restore_backup() and save_backup_blob() were granted to `anon` only.
-- A Google-logged-in user talks to PostgREST as `authenticated`, so
-- without this the backup-code path breaks the moment they log in —
-- and the plan requires it to work in both modes.
grant execute on function public.restore_backup(text) to authenticated;
grant execute on function public.save_backup_blob(text, jsonb, jsonb, jsonb)
  to authenticated;

-- ------------------------------------------------------------ avatars bucket
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do update set public = true;

-- Read: public (the leaderboard will need it later; harmless now).
-- Write/delete: owner only. App uploads to <user_id>/avatar.jpg, so the
-- first path segment is the owner id.
drop policy if exists "avatars public read" on storage.objects;
create policy "avatars public read"
  on storage.objects for select
  to public
  using (bucket_id = 'avatars');

drop policy if exists "avatars owner write" on storage.objects;
create policy "avatars owner write"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "avatars owner update" on storage.objects;
create policy "avatars owner update"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "avatars owner delete" on storage.objects;
create policy "avatars owner delete"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
