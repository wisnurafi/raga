-- Arena: community leaderboard foundations.
--
-- The leaderboard is strictly opt-in (default off): health data must
-- never leak implicitly. RLS on `records` stays airtight — the board
-- is served through a SECURITY DEFINER function that only exposes
-- display name, avatar and the computed metric, never raw weights.
--
-- How to apply: paste this file into the Supabase SQL Editor and Run.

alter table public.profiles
  add column if not exists leaderboard_opt_in boolean not null default false,
  add column if not exists current_streak integer not null default 0;

-- Community board. p_metric is 'pct_loss' (% weight lost over the
-- current calendar week, Mon-Sun Asia/Jakarta, needs >= 2 weigh-ins)
-- or 'streak' (weekly weigh-in streak, kept fresh by the client on
-- every record save). Only opted-in users appear.
create or replace function public.get_leaderboard(
  p_metric text,
  p_limit int default 50
)
returns table (
  display_name text,
  avatar_url text,
  value numeric
)
language plpgsql
security definer
set search_path = public
as $$
declare
  week_start timestamptz :=
    (date_trunc('week', now() at time zone 'Asia/Jakarta')
      at time zone 'Asia/Jakarta');
begin
  if p_metric = 'pct_loss' then
    return query
    with bounds as (
      select r.user_id,
        (array_agg(r.weight_kg order by r.created_at asc))[1]  as w_first,
        (array_agg(r.weight_kg order by r.created_at desc))[1] as w_last
      from records r
      join profiles p on p.user_id = r.user_id
      where p.leaderboard_opt_in
        and r.created_at >= week_start
      group by r.user_id
      having count(*) >= 2
    )
    -- Anti-abuse: the counted loss is capped at 3%/week. Absurd drops
    -- are water weight or fake logs — capping kills the incentive to
    -- fabricate them, while no honest fat loss ever exceeds 3%/week.
    select
      p.display_name,
      p.avatar_url,
      least(
        round(
          ((b.w_first - b.w_last) / nullif(b.w_first, 0) * 100)::numeric, 1
        ),
        3.0
      )
    from bounds b
    join profiles p on p.user_id = b.user_id
    order by 3 desc
    limit p_limit;
  elsif p_metric = 'streak' then
    return query
    select p.display_name, p.avatar_url, p.current_streak::numeric
    from profiles p
    where p.leaderboard_opt_in and p.current_streak > 0
    order by p.current_streak desc
    limit p_limit;
  end if;
  return;
end;
$$;

-- Authenticated users may call the board; anonymous users never see it
-- (the feature itself is login-gated in the app).
grant execute on function public.get_leaderboard(text, int) to authenticated;
