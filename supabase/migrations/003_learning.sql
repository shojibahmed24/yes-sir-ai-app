-- 003: practice, quiz, tests, attempts, AI generations.
create table if not exists public.practice_problems (
  id text primary key,
  subject_id text not null references public.subjects (id),
  question_bn text not null,
  question_en text not null,
  answer_bn text not null,
  answer_en text not null
);
create table if not exists public.quiz_questions (
  id text primary key,
  subject_id text not null references public.subjects (id),
  question_bn text not null,
  question_en text not null,
  options jsonb not null default '[]',
  correct_index int not null default 0
);
create table if not exists public.tests (
  id text primary key,
  subject_id text not null references public.subjects (id),
  title_bn text not null,
  title_en text not null,
  duration_minutes int not null default 30,
  question_count int not null default 20,
  pass_percent int not null default 40
);
create table if not exists public.quiz_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  test_id text,
  score int not null default 0,
  total int not null default 0,
  created_at timestamptz not null default now()
);
create table if not exists public.test_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  test_id text,
  score int not null default 0,
  total int not null default 0,
  created_at timestamptz not null default now()
);
create table if not exists public.ai_generations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  book_id text,
  chapter_id text,
  page_number int,
  problem_number int,
  style text not null default 'steps',
  created_at timestamptz not null default now()
);
alter table public.practice_problems enable row level security;
alter table public.quiz_questions enable row level security;
alter table public.tests enable row level security;
alter table public.quiz_attempts enable row level security;
alter table public.test_attempts enable row level security;
alter table public.ai_generations enable row level security;
create policy "learning read" on public.practice_problems for select using (auth.role() = 'authenticated');
create policy "learning read" on public.quiz_questions for select using (auth.role() = 'authenticated');
create policy "learning read" on public.tests for select using (auth.role() = 'authenticated');
create policy "own attempts" on public.quiz_attempts for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own attempts" on public.test_attempts for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own generations" on public.ai_generations for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
