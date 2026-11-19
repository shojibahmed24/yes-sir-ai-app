-- 001: core users/profiles + parent links. Run FIRST.
-- Supabase Auth owns auth.users; profiles.id references it.
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null default '',
  nickname text not null default '',
  gender text check (gender in ('', 'boy', 'girl')),
  school_class int check (school_class between 1 and 10),
  medium text check (medium in ('', 'bn', 'en')),
  school_name text not null default '',
  district text not null default '',
  phone text not null default '',
  email text not null default '',
  daily_goal_minutes int not null default 30,
  created_at timestamptz not null default now()
);
create table if not exists public.parent_links (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles (id) on delete cascade,
  guardian_name text not null default '',
  guardian_phone text not null default '',
  created_at timestamptz not null default now()
);
alter table public.profiles enable row level security;
alter table public.parent_links enable row level security;
-- A user sees/edits only their own profile.
create policy "own profile read" on public.profiles
  for select using (auth.uid() = id);
create policy "own profile write" on public.profiles
  for all using (auth.uid() = id) with check (auth.uid() = id);
-- A parent link is readable by its student; parents read via the
-- linked student id (parent dashboard uses the student's auth).
create policy "own parent links" on public.parent_links
  for all using (auth.uid() = student_id) with check (auth.uid() = student_id);
