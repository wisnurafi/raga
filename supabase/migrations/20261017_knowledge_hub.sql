-- Raga Knowledge Hub: content tables (public read, published only)
-- + user tables (RLS-locked to owner) + quiz RPCs.
--
-- Run ONCE in the Supabase SQL Editor (safe to re-run: every statement
-- is idempotent). Apply BEFORE installing an APK built with the matching
-- client code — until these exist, Knowledge Hub calls fail loudly.
--
-- Security model:
-- - Official content: clients may SELECT published rows only. No
--   insert/update/delete policies exist for clients — content is managed
--   through the Supabase Dashboard or seed scripts (service_role),
--   never from the app.
-- - Quiz answers never leave the server before submit: the questions
--   table has NO select policy; access goes through the SECURITY
--   DEFINER functions below (same pattern as get_leaderboard).
-- - Bookmarks/progress: RLS-locked to auth.uid() = user_id, like the
--   existing bmi_records / records tables.

-- ------------------------------------------------------------ categories
create table if not exists public.knowledge_categories (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  title text not null,
  description text not null default '',
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.knowledge_categories enable row level security;

drop policy if exists "knowledge categories public read"
  on public.knowledge_categories;
create policy "knowledge categories public read"
  on public.knowledge_categories for select
  to public
  using (true);

-- ------------------------------------------------------------ articles
create table if not exists public.knowledge_articles (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  category_id uuid not null
    references public.knowledge_categories(id) on delete restrict,
  title text not null,
  summary text not null default '',
  content_md text not null default '',
  cover_image_url text,
  reading_minutes integer not null default 0,
  status text not null default 'draft'
    check (status in ('draft', 'published', 'archived')),
  featured boolean not null default false,
  published_at timestamptz,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.knowledge_articles enable row level security;

drop policy if exists "knowledge articles published read"
  on public.knowledge_articles;
create policy "knowledge articles published read"
  on public.knowledge_articles for select
  to public
  using (status = 'published');

create index if not exists knowledge_articles_published_idx
  on public.knowledge_articles (published_at desc)
  where status = 'published';
create index if not exists knowledge_articles_category_idx
  on public.knowledge_articles (category_id);
create index if not exists knowledge_articles_featured_idx
  on public.knowledge_articles (featured)
  where status = 'published' and featured = true;

-- ------------------------------------------------------------ tags
create table if not exists public.knowledge_tags (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  label text not null,
  created_at timestamptz not null default now()
);

alter table public.knowledge_tags enable row level security;

drop policy if exists "knowledge tags public read"
  on public.knowledge_tags;
create policy "knowledge tags public read"
  on public.knowledge_tags for select
  to public
  using (true);

create table if not exists public.knowledge_article_tags (
  article_id uuid not null
    references public.knowledge_articles(id) on delete cascade,
  tag_id uuid not null
    references public.knowledge_tags(id) on delete cascade,
  primary key (article_id, tag_id)
);

alter table public.knowledge_article_tags enable row level security;

drop policy if exists "knowledge article tags public read"
  on public.knowledge_article_tags;
create policy "knowledge article tags public read"
  on public.knowledge_article_tags for select
  to public
  using (true);

-- ------------------------------------------------------------ sources
create table if not exists public.knowledge_sources (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  publisher text not null default '',
  url text not null,
  accessed_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.knowledge_sources enable row level security;

drop policy if exists "knowledge sources public read"
  on public.knowledge_sources;
create policy "knowledge sources public read"
  on public.knowledge_sources for select
  to public
  using (true);

create table if not exists public.knowledge_article_sources (
  article_id uuid not null
    references public.knowledge_articles(id) on delete cascade,
  source_id uuid not null
    references public.knowledge_sources(id) on delete cascade,
  sort_order integer not null default 0,
  primary key (article_id, source_id)
);

alter table public.knowledge_article_sources enable row level security;

drop policy if exists "knowledge article sources public read"
  on public.knowledge_article_sources;
create policy "knowledge article sources public read"
  on public.knowledge_article_sources for select
  to public
  using (true);

-- ------------------------------------------------------------ glossary
create table if not exists public.knowledge_glossary (
  id uuid primary key default gen_random_uuid(),
  term text not null unique,
  definition text not null,
  related_article_id uuid
    references public.knowledge_articles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.knowledge_glossary enable row level security;

drop policy if exists "knowledge glossary public read"
  on public.knowledge_glossary;
create policy "knowledge glossary public read"
  on public.knowledge_glossary for select
  to public
  using (true);

create index if not exists knowledge_glossary_term_idx
  on public.knowledge_glossary (term);

-- ------------------------------------------------------------ quizzes
create table if not exists public.knowledge_quizzes (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  title text not null,
  description text not null default '',
  article_id uuid
    references public.knowledge_articles(id) on delete set null,
  status text not null default 'draft'
    check (status in ('draft', 'published', 'archived')),
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.knowledge_quizzes enable row level security;

drop policy if exists "knowledge quizzes published read"
  on public.knowledge_quizzes;
create policy "knowledge quizzes published read"
  on public.knowledge_quizzes for select
  to public
  using (status = 'published');

create table if not exists public.knowledge_quiz_questions (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null
    references public.knowledge_quizzes(id) on delete cascade,
  sort_order integer not null default 0,
  prompt text not null,
  options jsonb not null,
  correct_index integer not null,
  explanation text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- No select policy on purpose: answers must never be readable
-- directly. Clients go through the RPCs below.
alter table public.knowledge_quiz_questions enable row level security;

create index if not exists knowledge_quiz_questions_quiz_idx
  on public.knowledge_quiz_questions (quiz_id, sort_order);

-- ------------------------------------------------------------ quiz RPCs
-- get_quiz_questions returns prompt + options only: correct_index and
-- explanation never leave the server before submit.
create or replace function public.get_quiz_questions(p_quiz_id uuid)
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
  order by q.sort_order;
end;
$$;

grant execute on function public.get_quiz_questions(uuid)
  to anon, authenticated;

-- submit_quiz_answer grades on the server and only then reveals the
-- explanation. Draft/archived quizzes are rejected.
create or replace function public.submit_quiz_answer(
  p_question_id uuid,
  p_chosen_index integer
)
returns table (
  correct boolean,
  correct_index integer,
  explanation text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_correct integer;
  v_expl text;
  v_published boolean;
begin
  select q.correct_index, q.explanation, (z.status = 'published')
    into v_correct, v_expl, v_published
  from knowledge_quiz_questions q
  join knowledge_quizzes z on z.id = q.quiz_id
  where q.id = p_question_id;

  if not found or not v_published then
    raise exception 'question not found';
  end if;

  return query
  select (p_chosen_index = v_correct), v_correct, v_expl;
end;
$$;

grant execute on function public.submit_quiz_answer(uuid, integer)
  to anon, authenticated;

-- ------------------------------------------------------------ user tables
create table if not exists public.user_knowledge_bookmarks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  article_id uuid not null
    references public.knowledge_articles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, article_id)
);

alter table public.user_knowledge_bookmarks enable row level security;

drop policy if exists "own rows" on public.user_knowledge_bookmarks;
create policy "own rows"
  on public.user_knowledge_bookmarks
  for all
  to public
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create index if not exists user_knowledge_bookmarks_user_idx
  on public.user_knowledge_bookmarks (user_id, created_at desc);

create table if not exists public.user_knowledge_progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  article_id uuid not null
    references public.knowledge_articles(id) on delete cascade,
  completed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, article_id)
);

alter table public.user_knowledge_progress enable row level security;

drop policy if exists "own rows" on public.user_knowledge_progress;
create policy "own rows"
  on public.user_knowledge_progress
  for all
  to public
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ------------------------------------------------------------ updated_at
drop trigger if exists trg_knowledge_categories_touch
  on public.knowledge_categories;
create trigger trg_knowledge_categories_touch
  before update on public.knowledge_categories
  for each row execute function public.touch_updated_at();

drop trigger if exists trg_knowledge_articles_touch
  on public.knowledge_articles;
create trigger trg_knowledge_articles_touch
  before update on public.knowledge_articles
  for each row execute function public.touch_updated_at();

drop trigger if exists trg_knowledge_glossary_touch
  on public.knowledge_glossary;
create trigger trg_knowledge_glossary_touch
  before update on public.knowledge_glossary
  for each row execute function public.touch_updated_at();

drop trigger if exists trg_knowledge_quizzes_touch
  on public.knowledge_quizzes;
create trigger trg_knowledge_quizzes_touch
  before update on public.knowledge_quizzes
  for each row execute function public.touch_updated_at();

drop trigger if exists trg_knowledge_quiz_questions_touch
  on public.knowledge_quiz_questions;
create trigger trg_knowledge_quiz_questions_touch
  before update on public.knowledge_quiz_questions
  for each row execute function public.touch_updated_at();

drop trigger if exists trg_user_knowledge_progress_touch
  on public.user_knowledge_progress;
create trigger trg_user_knowledge_progress_touch
  before update on public.user_knowledge_progress
  for each row execute function public.touch_updated_at();
