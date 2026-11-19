# Edge Deploy Plan — Yes Sir AI (explain-question + guide-bank)

## Goal

Deploy the two existing Edge Functions to the live Supabase project so the
app's live-data paths stop returning 404. No code changes, no database
changes, no app changes in this deploy.

## Current state (verified 2026-10-30)

- Live check: `guide-bank` and `explain-question` both return HTTP 404 —
  neither function is deployed yet.
- Supabase CLI is NOT installed in the VM (checked 2026-10-29 and again
  2026-10-30).
- No `config.toml` exists (neither per-function nor project-level). The
  platform default applies: `verify_jwt = true` for both functions.
  Post-deploy verification will prove this with an unauthenticated call
  (must return 401, not data).
- Both functions read ONLY `SUPABASE_URL` and
  `SUPABASE_SERVICE_ROLE_KEY` from the environment. Both are
  platform-provided built-in secrets for Edge Functions — no manual
  secret setting is needed, and neither function calls OpenRouter or any
  other external service. (AI text answers stay client-side and still
  need the build-time OpenRouter key; that is a separate step, not part
  of this deploy.)

## What is deployed (code as-is)

- `explain-question` — server-side grounding lookup via the service role:
  book questions + book chunks (Mode A), guide question units + max 1
  prose fallback chunk (Mode G), book-index probe (Mode D). It returns
  grounding only; the AI explanation itself happens client-side.
- `guide-bank` — chapter lists (`list` action, max 20 rows/page
  server-side) and model-test set metadata (`sets` action). It NEVER
  returns `answer_key` or `guide_solution` (only `has_key`); missing
  tables return HTTP 500 `guide-tables-missing`.

## Steps

1. **Install the Supabase CLI** — DONE 2026-10-30: version 2.122.0,
   installed manually from the official GitHub release tarball
   (`supabase_2.122.0_linux_amd64.tar.gz`, sha256 verified against the
   release checksums.txt) to `$HOME/.supabase/bin/supabase` (home
   persists). Note: the official install script route failed twice
   (first `sh` is dash, not bash; then a transient HTTP 403 on the
   asset download) — the manual tarball route worked immediately
   after, so the 403 was transient, not a block.
2. **Authenticate the CLI.** The CLI needs a Supabase access token
   (`SUPABASE_ACCESS_TOKEN` env var, used transiently for this deploy
   only, never stored). The token is created by the user in the
   Supabase Dashboard: Account → Access Tokens → Generate new token.
   (The token grants full account access, so it is used once and the
   user may revoke it from the dashboard after the deploy.)
3. **Deploy both functions** (single command, project ref
   `vvyiwyzredqoulufqgmg`):
   `supabase functions deploy explain-question guide-bank
   --project-ref vvyiwyzredqoulufqgmg`
4. **Verify live** (no credentials beyond the public anon key):
   - Unauthenticated call to each function → HTTP 401 (proves
     `verify_jwt` is on).
   - `guide-bank` list call with a valid anon JWT but missing/invalid
     params → a validation error (400-style), NOT 404 (proves the
     function runs and reaches its code).
   - `explain-question` probe call → a structured response/error, NOT
     404.
   - On any failure, read the function logs (`supabase functions logs`
     or the dashboard) before retrying; do not redeploy blindly.
5. **Report**: new function status, verification results, and what the
   deploy unlocked (guide bank lists, guide model-test sets, book
   grounding) versus what is still pending (OpenRouter key at build,
   premium/voice, APK deferral, device test).

## Rollback / risk

- There is no prior deployed version: right now both functions are 404.
  A failed deploy leaves that 404 state unchanged — no regression is
  possible from the deploy itself.
- A bad deploy is fixed by redeploying the same code or deleting the
  function from the dashboard/CLI. The deploy touches no database
  tables, rows, or app code.

## Explicitly out of scope

- No database migrations, no data imports, no app code changes.
- No OpenRouter/Gemini key wiring (build-time / later steps).
- No APK build (still deferred by the user's 2026-10-29 order).
- No Play Store release.

## Result (2026-10-30, user order + transient access token via env only)

- DEPLOYED: `explain-question` + `guide-bank`, both ACTIVE v1
  (CLI list, updated 2026-10-29 19:35:02 UTC). Deploy exit 0; the
  Docker warning is irrelevant (no local stack needed for remote deploy).
- VERIFIED LIVE:
  - Unauthenticated POST to both functions → HTTP 401 (was 404 before
    deploy) — proves the functions exist and `verify_jwt` is on.
  - Authenticated (anon JWT) probes → HTTP 400 validation errors, not
    404/401/500: guide-bank `list`/`sets` → `{"error":"bad-request"}`;
    explain-question `{}` →
    `{"error":"subject and numeric classId are required"}` — proves
    both functions execute their code and validate input.
- Access token was used once via env for the deploy + list + key lookup
  only; it was never stored, printed, or written to any file, and the
  user may revoke it from the dashboard now that the deploy is done.
- Still pending after this deploy: OpenRouter key at build time (AI text
  answers), premium/voice wiring, APK deferral lift, device test.

## Result (2026-10-30, v4 redeploy — no-neighbour grounding, user order + transient access token via env only)
- REDEPLOYED: explain-question only → ACTIVE v4 (2026-10-30 07:52:40 UTC). Uploaded assets: index.ts (603 lines) + grounding.ts (78 lines, new module). guide-bank untouched at v2.
- First attempt from the supabase/ subdir failed (entrypoint path error; v3 unchanged — no regression); retry from the project root succeeded, exit 0.
- VERIFIED LIVE: functions list shows v4 ACTIVE; unauthenticated POST → 401 (verify_jwt on). Live Mode A grounding probe NOT run — dart_defines.json (anon key source) was not found on disk at deploy time.
- Token used transiently via env only; never stored, printed, or written to any file; user may revoke it from the dashboard now that the deploy is done.
- NOTE: dart_defines.json is missing from the workspace — APK builds need it restored (SUPABASE_URL + SUPABASE_ANON_KEY) or the app builds in DEMO mode.

## Update (2026-10-30, after v4 deploy — live Mode A probe PASSED)
- Live Mode A probe run with user-supplied anon key: { subject math, classId 7, chapter 6, page 97, problem 1, language bn } → found: true, book গণিত, chapter 6, questionText matched exactly, chunks: 2 (both page-overlapping: 94-97 and 97-100, both contain page 97; count ≤ 3; NO neighbour chunk; no fallbackChunk/textbookChunks fields in Mode A response). No-neighbour grounding PROVEN live on v4.
- dart_defines.json restored at project root (SUPABASE_URL + SUPABASE_ANON_KEY, public values only) from user-supplied values — APK build blocker removed.

## v5 — 2026-10-30 ~21:0x +06 (second step: Mode L listByChapter + Mode Q by-id)
- Deploy: `supabase functions deploy explain-question --project-ref vvyiwyzredqoulufqgmg` from project root, user-supplied fresh scoped token (transient env only, value not recorded).
- Live: explain-question ACTIVE VERSION 5 (was 4); guide-bank unchanged v2; unauthenticated POST -> 401.
- Mode L probe (class6 math ch3, bn): found=true, book class6-math-bn, chapter 3 পূর্ণসংখ্যা, 25 questions, types mcq 5 / short 3 / creative 1 / null 16, pages 64,65,69,74,75, no solution/key/chunk leak in list payload.
- Mode Q probe (null-problem row class6-math-bn-ch3-p75-e1): found=true, 1 page-overlapping chunk (71-75).
- Mode A regression probe (class7 math ch6 p97 q1): found=true, 2 chunks, no neighbour change.
