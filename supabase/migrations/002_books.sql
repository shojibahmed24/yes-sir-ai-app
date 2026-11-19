-- 002: classes, subjects, books, chapters, book_questions.
-- book_questions is SERVER-ONLY: never expose source_link to clients.
-- The books_public view hides source_link; clients query the view.
create table if not exists public.classes (
  id int primary key,
  name_bn text not null,
  name_en text not null
);
create table if not exists public.subjects (
  id text primary key,
  name_bn text not null,
  name_en text not null
);
create table if not exists public.books (
  id text primary key,
  class_id int not null references public.classes (id),
  subject_id text not null references public.subjects (id),
  language text not null check (language in ('bn', 'en')),
  title text not null,
  supplied boolean not null default false,
  source_link text, -- SERVER-ONLY, never sent to the app
  created_at timestamptz not null default now()
);
create table if not exists public.chapters (
  id text primary key,
  book_id text not null references public.books (id) on delete cascade,
  number int not null,
  title_bn text not null,
  title_en text not null
);
create table if not exists public.book_questions (
  id text primary key,
  book_id text not null references public.books (id) on delete cascade,
  chapter_id text references public.chapters (id),
  page_number int not null,
  problem_number int,
  question_text text not null
);
create or replace view public.books_public as
  select id, class_id, subject_id, language, title, supplied, created_at
  from public.books;
alter table public.classes enable row level security;
alter table public.subjects enable row level security;
alter table public.books enable row level security;
alter table public.chapters enable row level security;
alter table public.book_questions enable row level security;
-- Reference data is readable by any signed-in user.
-- REVIEW FIX: there is deliberately NO read policy on public.books.
-- The old policy let any authenticated client read books.source_link
-- directly, defeating the books_public view that hides it. Clients
-- must query books_public (a view, which runs as its owner and
-- returns only the listed columns); direct table reads stay blocked
-- by RLS with no policy.
create policy "reference read" on public.classes for select using (auth.role() = 'authenticated');
create policy "reference read" on public.subjects for select using (auth.role() = 'authenticated');
create policy "reference read" on public.chapters for select using (auth.role() = 'authenticated');
-- book_questions: NO client read policy on purpose. Only the
-- server / Edge Function (service role) may query it, so the AI
-- grounding index cannot be scraped from the app.
insert into public.classes (id, name_bn, name_en) values
  (1,'ক্লাস ১','Class 1'),(2,'ক্লাস ২','Class 2'),
  (3,'ক্লাস ৩','Class 3'),(4,'ক্লাস ৪','Class 4'),
  (5,'ক্লাস ৫','Class 5'),(6,'ক্লাস ৬','Class 6'),
  (7,'ক্লাস ৭','Class 7'),(8,'ক্লাস ৮','Class 8'),
  (9,'ক্লাস ৯','Class 9'),(10,'ক্লাস ১০','Class 10')
on conflict (id) do nothing;
insert into public.subjects (id, name_bn, name_en) values
  ('math','গণিত','Mathematics'),('science','বিজ্ঞান','Science'),
  ('bangla','বাংলা','Bangla'),('english','ইংরেজি','English'),
  ('bgs','বাংলাদেশ ও বিশ্বপরিচয়','Bangladesh & Global Studies'),
  ('ict','তথ্য ও যোগাযোগ প্রযুক্তি','ICT')
on conflict (id) do nothing;
