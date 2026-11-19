# Supabase migrations - run order

Run these in the Supabase Dashboard -> SQL Editor, in this exact order.
Do NOT skip a file, do NOT reorder them (later files reference earlier tables).

1. `migrations/001_core_profiles.sql` - profiles, parent_links, RLS
2. `migrations/002_books.sql` - classes, subjects, books, chapters,
   book_questions (server-only), books_public view, seed classes/subjects
3. `migrations/003_learning.sql` - practice, quiz, tests, attempts, AI generations
4. `migrations/004_progress_subscriptions.sql` - progress, streaks,
   saved questions, subscription products + entitlements
5. `migrations/005_voice.sql` - voice sessions + minute budgets (NO audio column)

Notes:
- `book_questions` has NO client read policy on purpose. Only the
  service-role key / Edge Function may query it. If you add a client
  read policy, the book index can be scraped from the app - do not do it.
- `subscription_entitlements` must NEVER be written by the app.
  Only the Play-verification server writes it, with a Play token HASH
  (never a raw purchase token).
- After running all 5, the app still works in DEMO mode until the
  keys in BACKEND_DETAILS_LIST.md are plugged in via --dart-define.
- Next step after migrations: insert Class 6 books into `books`
  (supplied=true) and chapters/questions into `book_questions`
  from the already-downloaded NCTB PDFs, via the service role only.
