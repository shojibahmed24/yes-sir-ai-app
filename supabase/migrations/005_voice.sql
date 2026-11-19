-- 005: voice sessions + minute budgets. NO audio column on purpose.
-- Never add an audio column without a PRD amendment.
create table if not exists public.voice_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  minutes_used int not null default 0,
  started_at timestamptz not null default now(),
  ended_at timestamptz
);
create table if not exists public.voice_minute_budgets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  period_start date not null,
  minutes_used int not null default 0,
  minutes_cap int not null default 30,
  unique (user_id, period_start)
);
alter table public.voice_sessions enable row level security;
alter table public.voice_minute_budgets enable row level security;
create policy "own voice sessions" on public.voice_sessions for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own voice budget" on public.voice_minute_budgets for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
