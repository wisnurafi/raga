-- Raga Knowledge Hub: content internationalization.
--
-- Adds a `locale` column ('id' default, 'en' for translations) to every
-- user-facing content table. Existing rows backfill to 'id'. Unique
-- constraints become (slug, locale) / (term, locale) so each locale has
-- its own row with a STABLE slug shared across locales — all slug-based
-- references (related articles, quiz links, tags) keep working per
-- locale without any remapping.
--
-- get_quiz_questions gains p_locale (default 'id': old clients keep
-- working). submit_quiz_answer is language-independent, unchanged.
--
-- Safe to re-run. Run in the Supabase SQL Editor AFTER
-- 20261017_knowledge_hub.sql.

-- ------------------------------------------------------------ articles
alter table public.knowledge_articles
  add column if not exists locale text not null default 'id';

alter table public.knowledge_articles
  drop constraint if exists knowledge_articles_slug_key;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'knowledge_articles_slug_locale_key'
  ) then
    alter table public.knowledge_articles
      add constraint knowledge_articles_slug_locale_key
      unique (slug, locale);
  end if;
end $$;

-- ------------------------------------------------------------ categories
alter table public.knowledge_categories
  add column if not exists locale text not null default 'id';

alter table public.knowledge_categories
  drop constraint if exists knowledge_categories_slug_key;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'knowledge_categories_slug_locale_key'
  ) then
    alter table public.knowledge_categories
      add constraint knowledge_categories_slug_locale_key
      unique (slug, locale);
  end if;
end $$;

-- ------------------------------------------------------------ glossary
alter table public.knowledge_glossary
  add column if not exists locale text not null default 'id';

alter table public.knowledge_glossary
  drop constraint if exists knowledge_glossary_term_key;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'knowledge_glossary_term_locale_key'
  ) then
    alter table public.knowledge_glossary
      add constraint knowledge_glossary_term_locale_key
      unique (term, locale);
  end if;
end $$;

-- ------------------------------------------------------------ quizzes
alter table public.knowledge_quizzes
  add column if not exists locale text not null default 'id';

alter table public.knowledge_quizzes
  drop constraint if exists knowledge_quizzes_slug_key;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'knowledge_quizzes_slug_locale_key'
  ) then
    alter table public.knowledge_quizzes
      add constraint knowledge_quizzes_slug_locale_key
      unique (slug, locale);
  end if;
end $$;

-- Questions inherit their quiz's locale through the join; no column
-- needed there.

-- ------------------------------------------------------------ quiz RPC (locale-aware)
create or replace function public.get_quiz_questions(
  p_quiz_id uuid,
  p_locale text default 'id'
)
returns table (
  id uuid,
  quiz_id uuid,
  sort_order integer,
  prompt text,
  options jsonb
)
language plpgsql
security definer
set search_path = public
as $$
begin
  return query
  select q.id, q.quiz_id, q.sort_order, q.prompt, q.options
  from knowledge_quiz_questions q
  join knowledge_quizzes z on z.id = q.quiz_id
  where q.quiz_id = p_quiz_id
    and z.status = 'published'
    and z.locale = p_locale
  order by q.sort_order;
end;
$$;

grant execute on function public.get_quiz_questions(uuid, text)
  to anon, authenticated;
