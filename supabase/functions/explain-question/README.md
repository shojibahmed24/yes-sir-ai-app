# Edge Function: `explain-question`

Server-side reader for `book_questions`. The Flutter app must never
query that table directly (migration `002_books.sql` gives it no
client read policy on purpose). This function is the only path from
a lesson/quiz question to book-verified context.

## What it does

- Mode A (lesson / search / chat): given
  `{ subject, classId, chapter, page, problem, language }`, it finds
  the supplied book row, the chapter row, then the exact
  `book_questions` row — and returns its verbatim `question_text`
  plus book/chapter titles.
- Mode B (quiz / model test): given
  `{ subject, classId, questionText, language }`, it substring-matches
  `question_text` (case-insensitive) within that class/subject/
  language's supplied books and returns the first match.
- Mode C (book lookup screen): given
  `{ listByPage: true, bookId, page }`, it returns EVERY indexed
  question on that printed page of that supplied book, in problem
  order (unnumbered items last), with public fields only
  (`chapterNumber`, `chapterTitle`, `page`, `problem` which is
  `null` for unnumbered items, verbatim `questionText`). The
  book's own `language` decides the chapter-title language.
  Empty page => `found: false, reason: 'not-indexed'`; unknown or
  unsupplied book => `reason: 'no-book'`. It never returns
  `source_link` (that column is never selected).
- Mode D (question generation pool, batch 2 items 8/9): given
  `{ generateQuiz: true, subject, classId, language }`, it returns
  EVERY indexed question of that class + subject + language
  (supplied books only, max 500 rows), ordered by page/problem,
  with `chapterNumber`/`chapterTitle` and verbatim `questionText`.
  The app selects from this pool with its own seeded,
  chapter-covering selector. NOTE: rows carry `question_text`
  ONLY — no options, no verified answer — so the app must NOT
  present them as scored MCQs until a verified-options source
  exists (see `QUESTION_GENERATION.md` in the project root).
  Empty index => `found: false, reason: 'not-indexed'`. Mode D is
  SOURCE-ONLY until redeployed (see below) and until
  `book_questions` rows land; today both are still pending.
- It returns `found: false` with `reason` (`no-book` | `no-chapter` |
  `not-indexed`) when nothing matches. It never guesses, never
  substitutes another question, and never returns `source_link`
  (that column is never selected).
- Mode G (guide bank, code only — NOT deployed by this change):
  given `{ guideQuestionId, language }`, it returns the verbatim
  guide question + its question-wise unit (printed key for
  MCQ/short; worked solution as HIDDEN grounding for
  creative/long/Math) + at most 1 prose fallback chunk only when
  the unit lacks context + at most 2 textbook chapter-opening
  chunks + marks facts (`marks`, `marksPrinted`, `budget` bands).
  Until migration `008_guide_tables.sql` is applied, Mode G
  returns `found: false, reason: 'guide-unavailable'` — the
  client-side guide resolver (`structured_explanation_service`)
  treats that as not-indexed. The worked solution is NEVER
  rendered verbatim: it goes into the AI prompt only.
- Mode GEN (server-side generation, 2026-10-30 — keys moved
  server-side): given `{ generate: true, systemPrompt,
  userPrompt }`, it proxies one OpenRouter chat completion with
  the pinned test model (`nvidia/nemotron-3-ultra-550b-a55b:free`)
  using the `OPENROUTER_API_KEY` function secret, and returns
  `{ generated: true, text }`. Missing secret => HTTP 500
  `{ error: 'openrouter-key-missing' }`; upstream failure =>
  HTTP 502 `{ error: 'openrouter-failed' }`. The app NEVER calls
  OpenRouter directly and NEVER holds the key — prompt
  construction stays client-side, only the key and the HTTP call
  moved here. Set the secret before this mode can answer:
  `supabase secrets set OPENROUTER_API_KEY=<key>`, then redeploy
  the function.

## Deploy (needs the Supabase CLI + a project the user owns)

```sh
cd yes-sir-ai-app
supabase link --project-ref <project-ref>
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=<service-role-key>
# SUPABASE_URL is provided to Edge Functions automatically.
supabase functions deploy explain-question
```

- Use the **secure vault / secure flow** for the service-role key.
  Never paste it in chat, never commit it, never bake it into the app.
- `verify_jwt` stays `true` (the default): only signed-in users can
  call the function. The service-role key is used only inside the
  function, never exposed to the client.
- The app finds the function automatically: it derives
  `$SUPABASE_URL/functions/v1/explain-question` from the
  `--dart-define=SUPABASE_URL=...` build flag (override with
  `--dart-define=EXPLAIN_FUNCTION_URL=...` if needed).

## Verify after deploy

```sh
# Signed-in user's JWT as $TOKEN (from the app session or dashboard):
curl -i "$SUPABASE_URL/functions/v1/explain-question" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"subject":"math","classId":6,"chapter":3,"page":45,"problem":5,"language":"bn"}'
```

- Expect `found: true` only after that exact question row exists in
  `book_questions` (see `BOOK_IMPORT_CONTRACT.md` — today the table
  holds no imported question rows yet, so `found: false` /
  `not-indexed` is the honest result until an import lands).
- Expect `found: false`, never a fabricated question, for anything
  not imported.
- Mode C check for the same page:
  `-d '{"listByPage":true,"bookId":"class6-math-bn","page":45}'`
  (expect `found: false` / `not-indexed` until that page's rows
  are imported; after import, expect the page's full question
  list under `questions`).
- Mode D check (generation pool):
  `-d '{"generateQuiz":true,"subject":"math","classId":6,"language":"bn"}'`
  (expect `found: false` / `not-indexed` until rows are imported;
  after import, expect `questions[]` with `chapterNumber`,
  `chapterTitle`, `page`, `problem`, verbatim `questionText` —
  and NO options/answer fields, by design).

- Mode A chunks check: a found Mode A response also carries
  `chunks[]` (max 3 objects `{text, pageStart, pageEnd}` from the
  same book + chapter around the question's page) and
  `chunkReason` (`chunks-found` / `no-chunks`). No chunks for
  that book + chapter => `chunks: []`, never a whole book or
  chapter. Modes B/C/D return no `chunks` field.

## What the app does when the function is NOT deployed

The app does not crash and does not fake grounding:

- Lesson/chat: it falls back to the real `chapters` table check.
  A real chapter with an unverifiable question shows the honest
  "chapter exists, exact question not verified" path (no-match
  screen asking for the exact question / a photo).
- Quiz: with no server path at all it shows the local worked
  solution labelled DEMO / not book-verified. Once the function is
  live, a live-but-unmatched quiz question shows "not in the book
  index" instead — the DEMO bank is never substituted for a live
  lookup result.

## App wiring

- `lib/core/services/explanation_service.dart` — resolution +
  OpenRouter call with full context.
- `lib/core/services/ai_text_service.dart` — thin adapter used by
  the lesson screen.
- `lib/features/learn/lesson_screen.dart`, `chat_screen.dart`,
  `lib/features/practice/quiz_question_screen.dart` — UI call sites.
- OpenRouter key: an Edge Function secret, NEVER a build flag —
  `supabase secrets set OPENROUTER_API_KEY=<key>` (set it, then
  redeploy). Without it, Mode GEN answers HTTP 500
  `openrouter-key-missing` and the app shows an honest
  not-configured error, never a fabricated answer. Without the
  function, question-level grounding is unavailable and the UI
  says so.
