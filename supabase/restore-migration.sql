-- Raga: backup-code restore (run ONCE in the Supabase SQL Editor).
--
-- Why: anonymous sign-ins get a FRESH auth.users id on every install,
-- so rows are also stamped with a backup_code the user keeps. These two
-- functions (SECURITY DEFINER) let the app save and restore by code
-- without opening the tables to the world.

alter table bmi_records
  add column if not exists backup_code text;

-- Profiles, goals, and settings travel with the code (not per user_id,
-- so a reinstall can adopt them under its fresh anonymous identity).
create table if not exists backup_blobs (
  backup_code text primary key,
  profiles jsonb not null default '[]',
  goals jsonb not null default '{}',
  settings jsonb not null default '{}',
  updated_at timestamptz not null default now()
);

alter table backup_blobs enable row level security;
-- No policies on backup_blobs: the anon key can't touch it directly,
-- only through the functions below.

create or replace function restore_backup(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  result jsonb;
begin
  select jsonb_build_object(
    'records', coalesce(
      (select jsonb_agg(to_jsonb(r) order by r.created_at desc)
       from bmi_records r
       where r.backup_code = p_code),
      '[]'::jsonb),
    'profiles', coalesce(
      (select b.profiles from backup_blobs b where b.backup_code = p_code),
      '[]'::jsonb),
    'goals', coalesce(
      (select b.goals from backup_blobs b where b.backup_code = p_code),
      '{}'::jsonb),
    'settings', coalesce(
      (select b.settings from backup_blobs b where b.backup_code = p_code),
      '{}'::jsonb)
  ) into result;
  return result;
end;
$$;

create or replace function save_backup_blob(
  p_code text, p_profiles jsonb, p_goals jsonb, p_settings jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into backup_blobs (backup_code, profiles, goals, settings, updated_at)
  values (p_code, p_profiles, p_goals, p_settings, now())
  on conflict (backup_code) do update
    set profiles = excluded.profiles,
        goals = excluded.goals,
        settings = excluded.settings,
        updated_at = now();
end;
$$;

grant execute on function restore_backup(text) to anon;
grant execute on function save_backup_blob(text, jsonb, jsonb, jsonb) to anon;

-- Optional: tag rows pushed BEFORE the app started stamping codes, so they
-- restore too. (Find your code in the app: Profile → Cloud backup →
-- Backup code.) On a private project, tagging every unstamped row is fine.
-- update bmi_records set backup_code = 'XXXX-XXXX-XXXX-XXXX'
-- where backup_code is null;
