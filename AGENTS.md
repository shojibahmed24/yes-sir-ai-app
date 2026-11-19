# Yes Sir AI — OpenCode master prompt (AGENTS.md)

Save this file as `AGENTS.md` in the project root on the user's Windows PC
(OpenCode reads it automatically at startup). Or paste the whole thing into
OpenCode. The user speaks Bangla; answer the user in Bangla, write code
comments in English. Model: **DeepSeek V4 Pro** for heavy work (this
lesson-mapping task — strongest reasoning); **DeepSeek V4.1 Flash 1017**
for small daily edits (cheapest, fastest). Switch anytime with `/models`.

## SETUP FIRST — do this before anything else

1. Get the project on this PC. If the folder does not exist yet, clone it:
   `git clone https://github.com/shojibahmed24/yes-sir-ai-app.git`
   Then `cd yes-sir-ai-app`. If the folder already exists, go inside it and
   run `git checkout main` and then `git pull` so you have the latest code.
2. Run OpenCode INSIDE the `yes-sir-ai-app` folder — never from another folder.
3. Check the download worked. The folder MUST contain `lib/`,
   `supabase/functions/guide-bank/`, `supabase/functions/explain-question/`
   and `supabase/migrations/` (19 files, 001–019). If any of these is
   missing, STOP and tell the user — do not guess, do not work from another
   copy. The old repo https://github.com/shojibahmed24/EducationalApp is
   NOT the project — never clone or use it.
4. Supabase is already the project's backend — nothing to install or connect
   by hand. Project ref `vvyiwyzredqoulufqgmg`, URL
   https://vvyiwyzredqoulufqgmg.supabase.co. The Edge functions and the
   migrations are IN the repo you just cloned. Verify the connection with one
   read-only probe (details in "Supabase (live project)" below) before you
   start coding. If the probe fails, STOP and tell the user.

---

You are the coding agent for **Yes Sir AI**, a Flutter app: a private-tuition
replacement for classes 1–10, all subjects in ONE app. A student enters a
book page, chapter or problem number and gets an easy explanation grounded
ONLY in the supplied guide books. Package: `com.yessirai.app`.

## Repos (read these first)

- App code (ONLY repo to use): https://github.com/shojibahmed24/yes-sir-ai-app
  — branch `main`. Everything is here now: the search-flow redesign WIP,
  the picker merge, both Edge functions and all migrations.
- Old mirror (do NOT use): https://github.com/shojibahmed24/EducationalApp
  — its `main` is an old Nov 8 snapshot and its `feat/picker-type-counts`
  branch (`2cbe0da`) is merged into yes-sir-ai-app main. Kept for history only.
- Guide chunks (book text): https://github.com/shojibahmed24/book-chank
  — all chunks pushed (including Class 9 Chemistry, 114 chunks).

## Supabase (live project)

- Project ref: `vvyiwyzredqoulufqgmg`
  (https://vvyiwyzredqoulufqgmg.supabase.co).
- Edge functions `guide-bank` (serves guide questions) and `explain-question`
  (AI explanations). Their source (`supabase/functions/`) IS on GitHub
  (commit `b020dc9b`). Both are deployed and ACTIVE live (guide-bank v28,
  explain-question v17).
- Migrations `supabase/migrations/` 001–019 ARE on GitHub. Migrations 018
  (biology out-of-syllabus) and 019 (subjects anon read) are NOT yet confirmed
  live — check the Supabase dashboard before relying on them.
- The 662 MB import data (book JSON/SQL, chunks, tools) is NOT on GitHub and
  stays local; the live database already holds all of it (57 subjects live).
  Do NOT re-import. Work against the live database for reads.
- Live probe (read-only, free): POST
  `https://vvyiwyzredqoulufqgmg.supabase.co/functions/v1/guide-bank` with
  the anon key from `dart_defines.json` (`SUPABASE_ANON_KEY`, public by
  design). Body: `{"action":"list","classId":<int>,"subject":"<id>",
  "chapter":<int>,"section":"<section-or-grp>","limit":1}`. The parameter is
  `section`, NOT `type`; `chapter` is required unless `setId`/`chapterless`/
  `board` is given. `list` never returns answers/solutions (only `has_key`).
- Database WRITES: STOP and ask the user first. A write needs the database
  password, which the user gives for that ONE task only — never store it,
  never reuse it, never write it into code, chat or files.
- If you need the book/question data, read it from the live database through
  guide-bank — never ask the user for the 662 MB import files. They are not
  part of this project folder.

## How to work

1. Before changing anything: run `git status` and `git log --oneline -5`.
   Tell the user which branch you are on and what is uncommitted.
2. Work on a feature branch, never directly on `main`. Commit with a clear
   message. Push to the branch and tell the user the commit hash.
3. After every change run `flutter analyze` and `flutter test` and report
   the exact results (pass/fail counts). Do not claim success without running
   them. On the user's PC, Flutter is wherever it is installed; JDK 17.
4. If a step needs a secret, a password or a token, STOP and ask the user —
   never invent one, never write one into code, chat or files.
5. You write the code and run the tests. The user's assistant Muse verifies
   your work against the rules below before anything goes live. Report
   honestly: what changed (files), test results, and what still needs the
   user's decision.

## Superpowers skills (installed 2026-11-20)

- Global OpenCode V2 plugin: `superpowers@git+https://github.com/obra/superpowers.git`;
  the skills are available through the native `skill` tool.
- For substantial work use the matching skill: `brainstorming` before new
  features, `writing-plans` for multi-step work, `executing-plans` (inline —
  cheapest) for implementation, `test-driven-development`,
  `systematic-debugging`, and `verification-before-completion`.
- Token budget: prefer `executing-plans` over subagent-heavy flows; do not
  re-read files or repeat completed work; keep the final report short (files,
  analyze, test counts, commit, decisions).

## HARD RULES — never break these

- Every Dart file MAX 250 lines (target 150–200). Split widgets if over.
- Bilingual Bangla + English. i18n is page-wise into `lib/l10n`, never all
  at once, never later.
- UI FIRST from login, then backend. Never stop mid-work.
- Everything follows the supplied books — each subject's guide, nothing
  outside the books. A subject without its book does NOT launch (Locked).
  One guide per subject; any other guide is correction-reference ONLY, never
  imported.
- Guide answers are verbatim-first. Fallback is NEVER an adjacent/previous
  chunk — only relevant prose the question depends on (max 1 unit), and the
  unit's dependency must be tagged. Items that cannot be read, have no
  answer, cannot be understood, or carry defects that could cause error if
  read are PERMANENTLY DROPPED — never guessed.
- AI explanations are WRITTEN/text only and served server-side (Supabase
  Edge `explain-question`). Voice is PREMIUM-ONLY via Gemini Live, isolated
  to the Voice Tutor screen only. Premium is $5/month via Google Play
  Billing ONLY, 30 voice minutes/month. No bKash, no other payment.
- English Paper-II is ALWAYS a separate subject. True/false items always
  stay true/false.
- Creative marks: ক=1, খ=2, গ=3, ঘ=4.
- Secrets: NEVER put keys/tokens/passwords in code. SUPABASE_URL +
  SUPABASE_ANON_KEY are public by design (build-time `--dart-define` only).
  The Supabase SERVICE_ROLE key stays server-side only. The OpenRouter key
  is client-side for testing only and must move server-side before Play
  release. A Supabase access token the user sends is for ONE deploy only —
  never reuse it, never store it.
- NEVER delete files, NEVER publish to the Play Store, NEVER send messages
  to people, NEVER touch other projects (Livocal, JannatIT, AiCart24, Ludo).
- Do NOT create zip files.

## Current state (verified 2026-11-19)

- DONE — picker types: Chemistry + Civics got 5 new guide types
  (`grp_one_word`, `grp_knowledge`, `grp_comprehension`, `grp_math_problem`,
  `grp_other_practice`); Higher Math got 3 (`grp_exercise`, `grp_activity`,
  `grp_exercise_mcq`). Server deployed and live-verified: HM totals
  grp_exercise 144, grp_activity 93, grp_exercise_mcq 50 — exact match with
  the database. MERGED into yes-sir-ai-app `main` 2026-11-19 (commit
  `e7297c40`, flutter analyze clean + test 768/768 green).
- DONE — Supabase code on GitHub: both Edge functions + migrations 001–019
  (commit `b020dc9b`, 41 files). `.gitignore` now ignores only the import
  data and work dirs, so your changes to functions/migrations are trackable.
- WIP COMMITTED + PUSHED: the search-flow redesign (365 files) is on
  yes-sir-ai-app `main` (commit `64a58d45`). Local main is clean. One file
  the redesign deleted (`search_flow_number_input.dart`) still exists on
  GitHub — a snapshot push cannot delete files, so remove it with a normal
  `git push` from this PC when you next push.
- OPEN DECISION (user decides, do NOT decide yourself): `conceptual-creative`
  — keep separate or merge into creative? (Chemistry 12 rows, Higher Math 8
  rows.)
- KNOWN APP BLOCKER: `lessonsForChapter` is hardcoded math-only. Other
  subjects get no lesson step in the picker without a per-subject lesson map
  (or serverLessons).
- 7 OWNER DECISIONS (decided 2026-11-09, NOT yet implemented — implement
  them when your task touches them): (1) Chemistry word-variant rows: keep
  the printed guide wording unless proven wrong; if the print is proven
  wrong, the correct form wins. (2) Chemistry board held-near rows (4):
  content-matching re-pass; keep held if unproven. (3) Chemistry board
  out-of-syllabus rows (148): flag OOS, exclude from browsing, still
  findable by search/number. (4) Chemistry chapter 7 activity rows (2):
  practice-work type; drop permanently if defective. (5) Bangla meta.notes:
  the 197 on disk are the set; verify as guide_error candidates. (6)
  English 158 Paper-II-header rows go to a future English Paper-II subject,
  never into English 1st. (7) Civics knowledge/comprehension marks are
  ক=1, খ=2 — confirmed.
- OTHER OPEN ITEMS: Chemistry chapter 11 MCQ has identical ক and গ options —
  needs a database fix. Class 9 Chemistry chunks file has 114 chunks, live
  database has 92 — the extra 22 are unidentified dropped chunks. Class 6
  lesson plan exists as a doc (`goals/yes-sir-ai-education-app/files/
  class6-lesson-plan.md` is NOT in this repo — ask the user for it); its
  build has not started.

## Your next task (unless the user says otherwise)

Group B/C lesson mapping, starting with **Economics and Science**: look at
the live database lesson values and decide from the DATA which values are
real lessons and which are compilation names — then build the per-subject
lesson map so the picker shows a lesson step for those subjects. Ask the user
before any database write; reads are free.

## What to report back

For every task: files changed, `flutter analyze` result, `flutter test`
result (exact counts), the commit hash and branch pushed, and the exact
questions that need the user's decision. Never present test results as phone
behaviour — tests run on desktop; only the user's phone or PC emulator proves
phone behaviour.
