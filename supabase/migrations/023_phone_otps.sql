-- 023: phone_otps — server-only OTP store for httpSMS verification.
-- The app posts to the `phone-otp` Edge Function; only that function
-- (service role) reads/writes this table. No client policies on
-- purpose: OTP hashes must never be reachable from the app.
-- One row per send; the newest non-expired row is the valid one.
-- Wrong guesses increment attempts; 5 wrong kills that code.
create table if not exists public.phone_otps (
  id uuid primary key default gen_random_uuid(),
  -- E.164 only ("+8801721013902"); normalised by the function.
  phone text not null,
  -- sha256(pepper + ':' + otp) — never the code itself.
  otp_hash text not null,
  purpose text not null check (purpose in ('register', 'login', 'reset')),
  expires_at timestamptz not null,
  attempts int not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists phone_otps_phone_created
  on public.phone_otps (phone, created_at desc);

alter table public.phone_otps enable row level security;
-- Deliberately NO policies: service role only.
