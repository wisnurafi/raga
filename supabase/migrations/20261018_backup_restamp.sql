-- Raga: server-side backup-code restamp.
--
-- Why this exists: after a restore-from-code, the local history contains rows
-- owned by a previous auth identity. RLS (auth.uid() = user_id) forbids this
-- device from UPDATE-ing those rows, so the client's re-stamp upsert fails
-- with 42501 ("new row violates row-level security policy (USING
-- expression)"). This SECURITY DEFINER function moves the stamp using the
-- OLD code as the ownership proof (80-bit, unguessable — anyone who knows it
-- can already restore everything via restore_backup, so this reveals nothing
-- new). It returns the moved client_ids so the client can skip re-pushing
-- them.
--
-- Run once in the Supabase SQL Editor (same manual step as
-- restore-migration.sql). Safe to run multiple times.

create or replace function restamp_backup_code(p_old_code text, p_new_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  moved jsonb;
begin
  if p_old_code is null or p_new_code is null
     or p_old_code = '' or p_new_code = '' then
    return '[]'::jsonb;
  end if;
  with moved_rows as (
    update public.bmi_records
       set backup_code = p_new_code
     where backup_code = p_old_code
    returning client_id
  )
  select coalesce(jsonb_agg(client_id), '[]'::jsonb) into moved from moved_rows;
  update public.backup_blobs
     set backup_code = p_new_code,
         updated_at = now()
   where backup_code = p_old_code;
  return moved;
end;
$$;

grant execute on function restamp_backup_code(text, text) to anon, authenticated;
