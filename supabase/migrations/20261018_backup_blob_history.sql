-- Raga: backup blob history (run in the Supabase SQL Editor, AFTER
-- restore-migration.sql / 20261018_backup_restamp.sql).
--
-- Why: save_backup_blob() is SECURITY DEFINER granted to anon, so anyone
-- holding a backup code can overwrite the victim's blob (profiles, goals,
-- settings) with no trace. This keeps every overwritten blob in
-- backup_blob_history first — a leaked code can no longer permanently
-- destroy the backup. History is capped at 20 rows per code.

create table if not exists backup_blob_history (
  id bigint generated always as identity primary key,
  backup_code text not null,
  profiles jsonb,
  goals jsonb,
  settings jsonb,
  saved_at timestamptz not null default now()
);

create index if not exists backup_blob_history_code_idx
  on backup_blob_history (backup_code, saved_at desc);

alter table backup_blob_history enable row level security;
-- No policies: like backup_blobs, only touched via SECURITY DEFINER.

create or replace function save_backup_blob(
  p_code text, p_profiles jsonb, p_goals jsonb, p_settings jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Salvage the row being overwritten (no-op on first save).
  insert into backup_blob_history (backup_code, profiles, goals, settings)
  select b.backup_code, b.profiles, b.goals, b.settings
  from backup_blobs b
  where b.backup_code = p_code;

  -- Bound the history so one code can't grow the table forever.
  delete from backup_blob_history h
  where h.backup_code = p_code
    and h.id not in (
      select id from backup_blob_history
      where backup_code = p_code
      order by saved_at desc, id desc
      limit 20
    );

  insert into backup_blobs (backup_code, profiles, goals, settings, updated_at)
  values (p_code, p_profiles, p_goals, p_settings, now())
  on conflict (backup_code) do update
    set profiles = excluded.profiles,
        goals = excluded.goals,
        settings = excluded.settings,
        updated_at = now();
end;
$$;

-- Grants survive CREATE OR REPLACE; re-assert for fresh setups.
grant execute on function save_backup_blob(text, jsonb, jsonb, jsonb)
  to anon;
