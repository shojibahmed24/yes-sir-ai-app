-- 004: progress, streaks, saved items, subscriptions.
-- subscription_entitlements is NEVER written by the client: only
-- the Play-verification server / Edge Function (service role) writes
-- it. The app only reads its own rows. Play token hashes only -
-- never store a raw purchase token here.
create table if not exists public.progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  streak_days int not null default 0,
  chapters_done int not null default 0,
  average_score int not null default 0,
  updated_at timestamptz not null default now(),
  unique (user_id)
);
create table if not exists public.streaks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  streak_date date not null,
  unique (user_id, streak_date)
);
create table if not exists public.saved_questions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  question_id text not null,
  created_at timestamptz not null default now(),
  unique (user_id, question_id)
);
create table if not exists public.subscription_products (
  id text primary key,
  display_price text not null,
  voice_minutes_per_period int not null default 30
);
create table if not exists public.subscription_entitlements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  product_id text not null references public.subscription_products (id),
  play_token_hash text,
  active boolean not null default false,
  period_end timestamptz,
  created_at timestamptz not null default now()
);
alter table public.progress enable row level security;
alter table public.streaks enable row level security;
alter table public.saved_questions enable row level security;
alter table public.subscription_products enable row level security;
alter table public.subscription_entitlements enable row level security;
create policy "own progress" on public.progress for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own streaks" on public.streaks for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own saved" on public.saved_questions for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "products read" on public.subscription_products for select using (auth.role() = 'authenticated');
create policy "own entitlement read" on public.subscription_entitlements for select using (auth.uid() = user_id);
insert into public.subscription_products (id, display_price, voice_minutes_per_period)
  values ('yes_sir_ai_premium_monthly', '$5 / month', 30)
on conflict (id) do nothing;
