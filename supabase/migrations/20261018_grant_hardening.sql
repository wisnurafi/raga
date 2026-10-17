-- Raga: grant hardening (run in the Supabase SQL Editor).
--
-- L1: restamp_backup_code() was granted to anon. The app always holds a
-- session when it calls this (CloudSync.init signs in anonymously when no
-- session exists, and restamp is a no-op without a ready session), so
-- restricting to authenticated callers changes nothing for the app while
-- shrinking the exposed surface.
-- L2: documents the real get_leaderboard access model (the old comment
-- claimed anonymous users "never see it", but Supabase counts anonymous
-- sign-ins as authenticated).

revoke execute on function restamp_backup_code(text, text) from anon;

comment on function public.get_leaderboard(text, int) is
'Community leaderboard, opt-in only. Callable by any authenticated user '
'— including anonymous sign-ins, which Supabase counts as authenticated. '
'The app gates the board screen behind its own login check; an anonymous '
'user who opts in appears like anyone else. Only display_name, '
'avatar_url, and the capped metric are exposed.';
