-- 021_ai_usage_daily.sql
--
-- Server-side daily quota for Mode GEN (explain-question).
-- The function used to accept unlimited generation calls from any
-- signed-in account, billed to the owner's provider keys. One row per
-- user per UTC day; the Edge function (service role) reads/increments
-- it and refuses past the daily cap.
--
-- RLS is ON with NO policies: only the service role (the Edge
-- function) may read or write. Clients can never touch this table.
--
-- WRITE: apply only with the owner's one-time permission.

create table if not exists public.ai_usage (
  user_id uuid not null references auth.users (id) on delete cascade,
  day date not null,
  calls integer not null default 0,
  updated_at timestamptz not null default now(),
  primary key (user_id, day)
);

alter table public.ai_usage enable row level security;

comment on table public.ai_usage is
  'Mode GEN daily call counter (service-role only; no client policies).';
