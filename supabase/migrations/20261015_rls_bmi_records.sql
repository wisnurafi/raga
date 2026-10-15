-- Raga: RLS policies for bmi_records.
--
-- Why this file exists: the policies were created in the Supabase dashboard
-- and never version-controlled. This migration mirrors the dashboard state
-- as of 2026-10-15 so the security boundary is auditable and re-appliable.
-- Safe to run multiple times (e.g. paste into the SQL Editor once).

alter table public.bmi_records enable row level security;

drop policy if exists "own rows" on public.bmi_records;

create policy "own rows"
  on public.bmi_records
  for all
  to public
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
