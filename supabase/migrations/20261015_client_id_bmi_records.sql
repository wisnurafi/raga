-- Raga: stable client identity for bmi_records upserts.
--
-- pushRecord upserts with onConflict: 'client_id'. Without a client-side
-- conflict target, a retry after a crash between a successful upsert and
-- the _syncedIds write inserts a duplicate row (the old payload carried
-- no id, so PostgREST could never match the existing row).
--
-- Safe to run multiple times (paste into the SQL Editor once). IMPORTANT:
-- apply BEFORE installing an APK built with the matching client code —
-- until this column exists, pushes fail with an on_conflict error.

alter table public.bmi_records
  add column if not exists client_id text;

create unique index if not exists bmi_records_client_id_key
  on public.bmi_records (client_id);
