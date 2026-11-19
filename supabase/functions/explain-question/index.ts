// Yes Sir AI — Edge Function: explain-question.
//
// WHY THIS EXISTS: public.book_questions has deliberately NO client
// read policy (supabase/migrations/002_books.sql). The Flutter app
// must never query it directly, and the anon key must never be able
// to scrape the grounding index. Only this function, running with
// the SERVICE ROLE key (server-side secret, never shipped in the
// app), reads book_questions — and it returns ONLY the single
// matched question's public fields (book/chapter titles, page,
// problem, verbatim question text). books.source_link is NEVER
// selected and NEVER returned.
//
// AUTH: deploy with verify_jwt = true (the default), so Supabase
// only forwards requests from signed-in users. This function also
// requires an Authorization header to be present.
//
// REQUEST (JSON, POST):
//   Mode A — by position (lesson/search/chat):
//     { subject, classId, chapter, page, problem, language }
//   Mode B — by wording (quiz / model-test banks, which carry no
//     page/problem):
//     { subject, classId, questionText, language }
//   Mode C — page listing (book lookup screen): given one book and
//     one printed page, return EVERY matched question on that page:
//     { listByPage: true, bookId, page }
//     The book's own language decides chapter-title language. The
//     response lists public fields only (never source_link), in
//     problem order with unnumbered items last. Empty page =>
//     found: false, reason 'not-indexed' — never a substitute.
//   Mode L — chapter listing (second-step chapter list,
//     2026-10-30): given class + subject + chapter number, return
//     EVERY indexed question of that chapter:
//     { listByChapter: true, subject, classId, chapter, language }
//     => { found: true, bookId, bookTitle, language,
//     chapterNumber, chapterTitle, questions: [{ id,
//     questionText, page, problem (number | null), questionType
//     (string | null) }] }, ordered by page asc then problem asc
//     with nulls last. Public fields ONLY — no chunks, no
//     solutions, no keys, no answers. Empty chapter => found:
//     true with questions: [] (an honest empty list, NOT
//     'not-indexed'). Missing book => found: false, reason
//     'no-book'; missing chapter => found: false, reason
//     'not-indexed'. Checked BEFORE Mode A validation, like Mode
//     C. DEPLOY ORDERING: listByChapter selects question_type,
//     so it must deploy only AFTER migration 009 + its backfill
//     are live; before 009 it retries without the column and
//     returns questionType: null for every row (correct but
//     unfiltered). See chapter_list.ts + 009 header.
//   Mode Q — by question id (second-step answer-on-demand,
//     2026-10-30): { questionId, language } => Mode-A-shaped
//     { found: true, bookTitle, chapterTitle, chapterNumber,
//     page, problem, questionText, chunks, chunkReason }.
//     Resolved by row id ONLY, so a null-problem row resolves
//     exactly; chunks are the same-book+chapter page-overlap
//     rows only (max 3, never neighbours). Missing row =>
//     found: false, reason 'not-indexed'. Selects NO
//     question_type column, so it does NOT depend on migration
//     009 and may deploy earlier. Checked BEFORE Mode A
//     validation, like Mode C.
//   Mode D — generation pool (daily quiz / model tests):
//     { generateQuiz: true, subject, classId, language }
//     Returns EVERY indexed question of that class + subject +
//     language (supplied books only), ordered by page/problem, with
//     chapter number/title. The client selects from this pool with
//     its own seeded, chapter-covering selector. Rows carry
//     question_text ONLY — no options/answers — so the client must
//     not present them as scored MCQs until a verified-options
//     source exists (see QUESTION_GENERATION.md). Empty index =>
//     found: false, reason 'not-indexed'.
//   Mode G — guide question (guide bank, locked 2026-10-29):
//     { guideQuestionId, language }. Returns the verbatim guide
//     question + its question-wise unit (printed key for
//     MCQ/short; worked solution as HIDDEN grounding for
//     creative/long/Math — never rendered verbatim) + at most 1
//     NO fallback chunks (user order 2026-10-30): matched-unit
//     only, never neighbours, never unlinked filler + marks facts
//     (marks, marksPrinted, budget). Until migration 008 lands,
//     returns found: false, reason 'guide-unavailable'.
//   language: 'bn' | 'en'. It selects the book row of that language
//   (book_questions rows inherit their language from their book).
//   Mode GEN — server-side generation (2026-10-30; provider
//   option + attribution 2026-11-04):
//     { generate: true, systemPrompt, userPrompt, provider? }.
//     provider 'openrouter' (default, previous behaviour exactly)
//     proxies one OpenRouter chat completion with the pinned test
//     model, using the OPENROUTER_API_KEY function secret.
//     provider 'gemini' runs the Gemini path in gemini.ts: model
//     gemini-3.8-flash first, one gemini-3.5-flash-lite retry on
//     429 or 503 only, using the GEMINI_API_KEY function secret.
//     Every success body also carries the provider + model
//     that ACTUALLY answered, so the client shows real
//     attribution, never the selected provider. A stale deploy
//     returns neither field, and the client must then show
//     'unknown'. Missing secret => HTTP 500
//     { error: 'openrouter-key-missing' } or
//     'gemini-key-missing'; upstream failure => HTTP 502
//     { error: 'openrouter-failed' } or 'gemini-failed'.
//     The client never calls either provider directly and
//     never holds a key.
//
// RESPONSE (JSON):
//   Found:    { found: true, bookTitle, chapterTitle,
//               chapterNumber, page, problem, questionText,
//               chunks: [{ text, pageStart, pageEnd }],
//               chunkReason: 'chunks-found' | 'no-chunks' }
//     Mode A only: chunks are the page-overlapping book_chunks
//     rows for the SAME book + chapter (page_start <= page <=
//     page_end), in reading order, up to 3. NEVER neighbours:
//     fewer overlapping rows => fewer chunks returned, never
//     filled with before/after chunks. No chunks for
//     that book+chapter => chunks: [] with chunkReason
//     'no-chunks' — NEVER a whole book or whole chapter.
//     Modes B/C/D return no chunks field (unchanged).
//   Mode G: { found: true, source: 'guide', guideQuestionId,
//             bookId, chapterId, chapterNumber, chapterTitle,
//             questionText, questionType, stimulusText (string |
//             null), stimulusRef (string | null), marks (number |
//             null),
//             marksPrinted, answerKey, unitKind ('key' |
//             'solution' | ''), groundingSolution (HIDDEN —
//             prompt only, never rendered), groundingSolutionHidden:
//             true, fallbackChunk (object | null), textbookChunks
//             (max 2), budget { marks, maxSteps, maxLines,
//             guidance } }.
//     Mode G unavailable: { found: false, reason:
//             'guide-unavailable' } (008 not applied yet).
//   Mode C:   { found: true, bookId, bookTitle, language,
//               questions: [{ chapterNumber, chapterTitle, page,
//               problem (number | null), questionText }] }
//   Mode L:   { found: true, bookId, bookTitle, language,
//               chapterNumber, chapterTitle, questions: [{ id,
//               questionText, page, problem (number | null),
//               questionType (string | null) }] } — empty chapter
//               => questions: [] with found: true.
//   Mode Q:   Mode-A-shaped (see Found above); resolved by id,
//               problem null coerced to 0 exactly as Mode A does.
//   Not found:{ found: false, reason } where reason is one of
//               'no-book' | 'no-chapter' | 'not-indexed'
//   Errors:   { error } with HTTP 400 (bad request) or 500
//             (server misconfiguration — no secret is ever echoed).
//
// DEPLOY: see README.md in this folder. No key is stored here.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { fetchChunks, fetchLinkedChunk, normalizeGuideOptions } from './grounding.ts';
import { generateWithGemini } from './gemini.ts';
import {
  handleByQuestionId,
  handleListByChapter,
} from './chapter_list.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function escapeLike(s: string): string {
  return s.replace(/[%_\\]/g, (c) => `\\${c}`);
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (req.method !== 'POST') {
    return json({ error: 'POST only' }, 405);
  }
  if (!req.headers.get('Authorization')) {
    return json({ error: 'Authorization required' }, 401);
  }
  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!supabaseUrl || !serviceKey) {
    // Misconfiguration, not a client error. Never echo env values.
    return json({ error: 'Function is not configured' }, 500);
  }
  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json({ error: 'Invalid JSON body' }, 400);
  }
  const supabase = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false },
  });

  // ---- Mode GEN: server-side generation (2026-10-30: keys moved
  // server-side; provider option 2026-11-04). Input:
  // { generate: true, systemPrompt, userPrompt, provider? }.
  // The client NEVER calls a provider directly and never holds
  // a key. provider 'gemini' delegates to gemini.ts; any other
  // value (including absent) takes the OpenRouter branch below:
  // OPENROUTER_API_KEY from the function secret, one chat
  // completion with the pinned test model. Missing secret =>
  // 500 'openrouter-key-missing' (never echoed); upstream
  // failure => 502 'openrouter-failed'. Checked FIRST: it
  // carries no subject/classId. Prompt construction stays
  // client-side (the locked structured contract + marks budget
  // live in Dart); only the keys and the provider HTTP calls
  // moved here. ----
  if (body.generate === true) {
    const systemPrompt = body.systemPrompt;
    const userPrompt = body.userPrompt;
    if (typeof systemPrompt !== 'string' || systemPrompt === '' ||
        typeof userPrompt !== 'string' || userPrompt === '') {
      return json({ error: 'systemPrompt and userPrompt are required' }, 400);
    }
    // Provider option (2026-11-04): 'gemini' delegates to
    // gemini.ts; anything else keeps the exact OpenRouter path
    // below, so the default provider is unchanged. Success
    // bodies now also carry provider + model (attribution);
    // old clients ignore the extra fields.
    if (body.provider === 'gemini') {
      const gen = await generateWithGemini(
        systemPrompt,
        userPrompt,
        Deno.env,
        fetch,
      );
      return json(gen.body, gen.status);
    }
    const openRouterKey = Deno.env.get('OPENROUTER_API_KEY');
    if (!openRouterKey) {
      return json({ error: 'openrouter-key-missing' }, 500);
    }
    let orRes: Response;
    try {
      orRes = await fetch('https://openrouter.ai/api/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${openRouterKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: 'nvidia/nemotron-3-ultra-550b-a55b:free',
          messages: [
            { role: 'system', content: systemPrompt },
            { role: 'user', content: userPrompt },
          ],
        }),
      });
    } catch {
      return json({ error: 'openrouter-failed' }, 502);
    }
    if (!orRes.ok) {
      return json({ error: 'openrouter-failed' }, 502);
    }
    let orData: Record<string, unknown>;
    try {
      orData = await orRes.json();
    } catch {
      return json({ error: 'openrouter-failed' }, 502);
    }
    const choices = orData.choices as
      | Array<Record<string, unknown>>
      | undefined;
    const msg = choices && choices.length > 0
      ? choices[0].message as Record<string, unknown> | undefined
      : undefined;
    const text = msg ? msg.content : undefined;
    return json({
      generated: true,
      text: typeof text === 'string' ? text : '',
      provider: 'openrouter',
      model: 'nvidia/nemotron-3-ultra-550b-a55b:free',
    });
  }

  // ---- Mode C: list all questions on one printed page of one
  // book. Checked FIRST: it needs no subject/classId, and must
  // not fall through into Mode A/B validation. Public fields
  // only; source_link is never selected. ----
  if (body.listByPage === true) {
    const bookId = body.bookId;
    const page = body.page;
    if (typeof bookId !== 'string' || bookId === '' ||
        typeof page !== 'number') {
      return json({ error: 'bookId and numeric page are required' }, 400);
    }
    const { data: book, error: bookError } = await supabase
      .from('books')
      .select('id, title, language, supplied')
      .eq('id', bookId)
      .maybeSingle();
    if (bookError) return json({ error: 'Book lookup failed' }, 500);
    if (!book || book.supplied !== true) {
      return json({ found: false, reason: 'no-book' });
    }
    const bookLanguage = book.language === 'en' ? 'en' : 'bn';
    const { data: rows, error: rowsError } = await supabase
      .from('book_questions')
      .select('chapter_id, page_number, problem_number, question_text')
      .eq('book_id', bookId)
      .eq('page_number', page)
      .order('problem_number', { ascending: true, nullsFirst: false });
    if (rowsError) return json({ error: 'Question lookup failed' }, 500);
    if (!rows || rows.length === 0) {
      return json({ found: false, reason: 'not-indexed' });
    }
    const chapterIds = [
      ...new Set(rows.map((r) => r.chapter_id as string | null)
        .where((c): c is string => c !== null)),
    ];
    const { data: chRows } = chapterIds.length > 0
      ? await supabase
          .from('chapters')
          .select('id, number, title_bn, title_en')
          .in('id', chapterIds)
      : { data: null };
    const chById = new Map<string, {
      number: number;
      title: string;
    }>();
    for (const c of chRows ?? []) {
      chById.set(c.id as string, {
        number: c.number as number,
        title: (bookLanguage === 'en' ? c.title_en : c.title_bn) as string,
      });
    }
    return json({
      found: true,
      bookId: book.id as string,
      bookTitle: book.title as string,
      language: bookLanguage,
      questions: rows.map((r) => {
        const ch = chById.get(r.chapter_id as string);
        return {
          chapterNumber: ch ? ch.number : 0,
          chapterTitle: ch ? ch.title : '',
          page: r.page_number as number,
          problem: r.problem_number as number | null,
          questionText: r.question_text as string,
        };
      }),
    });
  }

  // ---- Modes L + Q: chapter list + by-question-id
  // (second-step chapter list, 2026-10-30). Checked BEFORE the
  // Mode A/B subject/classId validation, like Mode C: neither
  // mode carries the full Mode A position (chapter/page/
  // problem), and Q carries no subject/classId at all. The
  // handlers live in chapter_list.ts (offline-testable); this
  // block only adapts the real Supabase client onto its Db
  // surface. Public fields only; source_link never selected.
  // Mode L selects question_type (migration 009) with a 42703
  // retry-without-column fallback; Mode Q selects no
  // question_type and is 009-independent. ----
  if (body.listByChapter === true || typeof body.questionId === 'string') {
    const db = {
      findBook: async (classId: number, subject: string, lang: string) => {
        const { data, error } = await supabase
          .from('books')
          .select('id, title')
          .eq('class_id', classId)
          .eq('subject_id', subject)
          .eq('language', lang)
          .eq('supplied', true)
          .order('title')
          .limit(1)
          .maybeSingle();
        if (error) throw error;
        return data
          ? { id: data.id as string, title: data.title as string }
          : null;
      },
      findChapter: async (bookId: string, chapterNumber: number) => {
        const { data, error } = await supabase
          .from('chapters')
          .select('id, number, title_bn, title_en')
          .eq('book_id', bookId)
          .eq('number', chapterNumber)
          .maybeSingle();
        if (error) throw error;
        if (!data) return null;
        // Title language follows the REQUEST language (the
        // caller passes it through handleListByChapter's
        // language; the adapter re-reads it from body here).
        const lang = body.language === 'en' ? 'en' : 'bn';
        return {
          id: data.id as string,
          number: data.number as number,
          title: (lang === 'en' ? data.title_en : data.title_bn) as string,
        };
      },
      listQuestions: async (
        bookId: string,
        chapterId: string,
        withType: boolean,
      ) => {
        const cols = withType
          ? 'id, page_number, problem_number, question_text, question_type'
          : 'id, page_number, problem_number, question_text';
        // cols is dynamic (with/without question_type), so the
        // supabase-js type parser cannot type the row: cast the
        // awaited result to plain records instead.
        const { data, error } = (await supabase
          .from('book_questions')
          .select(cols)
          .eq('book_id', bookId)
          .eq('chapter_id', chapterId)
          .order('page_number')
          .order('problem_number', { nullsFirst: false })) as unknown as {
            data: Array<Record<string, unknown>> | null;
            error: { code?: string } | null;
          };
        if (error) {
          return { errorCode: (error as { code?: string }).code ?? '' };
        }
        return {
          rows: (data ?? []).map((r) => ({
            id: r.id as string,
            page: r.page_number as number,
            problem: r.problem_number as number | null,
            questionText: r.question_text as string,
            questionType: withType
              ? (r.question_type as string | null) ?? null
              : undefined,
          })),
        };
      },
      findQuestionById: async (id: string, lang: string) => {
        const { data: row, error: rowError } = await supabase
          .from('book_questions')
          .select('id, book_id, chapter_id, page_number, problem_number, question_text')
          .eq('id', id)
          .maybeSingle();
        if (rowError) throw rowError;
        if (!row) return null;
        const { data: book } = await supabase
          .from('books')
          .select('id, title')
          .eq('id', row.book_id as string)
          .maybeSingle();
        const { data: ch } = row.chapter_id
          ? await supabase
              .from('chapters')
              .select('id, number, title_bn, title_en')
              .eq('id', row.chapter_id as string)
              .maybeSingle()
          : { data: null };
        return {
          row: {
            id: row.id as string,
            page: row.page_number as number,
            problem: row.problem_number as number | null,
            questionText: row.question_text as string,
          },
          book: {
            id: (book ? book.id : row.book_id) as string,
            title: (book ? book.title : '') as string,
          },
          chapter: ch
            ? {
                id: ch.id as string,
                number: ch.number as number,
                title: (lang === 'en' ? ch.title_en : ch.title_bn) as string,
              }
            : null,
        };
      },
      fetchChunks: async (
        bookId: string,
        chapterId: string | null,
        page: number,
      ) => fetchChunks(supabase, bookId, chapterId, page),
    };
    if (body.listByChapter === true) {
      const lSubject = body.subject;
      const lClassId = body.classId;
      const lChapter = body.chapter;
      if (typeof lSubject !== 'string' || lSubject === '' ||
          typeof lClassId !== 'number' || typeof lChapter !== 'number') {
        return json(
          { error: 'subject, numeric classId and numeric chapter are required' },
          400,
        );
      }
      const res = await handleListByChapter(db, {
        subject: lSubject,
        classId: lClassId,
        chapter: lChapter,
        language: body.language === 'en' ? 'en' : 'bn',
      });
      return json(res.body, res.status);
    }
    // Mode Q: a non-empty string questionId with no listByChapter.
    const qId = body.questionId as string;
    if (qId === '') {
      return json({ error: 'questionId is required' }, 400);
    }
    const res = await handleByQuestionId(db, {
      questionId: qId,
      language: body.language === 'en' ? 'en' : 'bn',
    });
    return json(res.body, res.status);
  }

  // ---- Mode D: question generation pool (batch 2, items 8/9).
  // Return EVERY indexed question of one class + subject +
  // language (supplied books only), ordered by page/problem, so
  // the app can select a daily quiz / model test from real book
  // questions with chapter coverage. The client does the seeded
  // selection (its seed carries the day/test id); this function
  // stays a dumb index reader like Modes A-C. Public fields only;
  // source_link is never selected. Rows carry question_text ONLY
  // (no options/answers), so the app must NOT turn them into
  // scored MCQs — see QUESTION_GENERATION.md. Empty index =>
  // found: false, reason 'not-indexed' — never a substitute. ----
  if (body.generateQuiz === true) {
    const gSubject = body.subject;
    const gClassId = body.classId;
    const gLanguage = body.language === 'en' ? 'en' : 'bn';
    if (typeof gSubject !== 'string' || gSubject === '' ||
        typeof gClassId !== 'number') {
      return json({ error: 'subject and numeric classId are required' }, 400);
    }
    const { data: gBooks, error: gBooksError } = await supabase
      .from('books')
      .select('id, title')
      .eq('class_id', gClassId)
      .eq('subject_id', gSubject)
      .eq('language', gLanguage)
      .eq('supplied', true)
      .order('title');
    if (gBooksError) return json({ error: 'Book lookup failed' }, 500);
    if (!gBooks || gBooks.length === 0) {
      return json({ found: false, reason: 'no-book' });
    }
    const gBookIds = gBooks.map((b) => b.id as string);
    const { data: gRows, error: gRowsError } = await supabase
      .from('book_questions')
      .select('book_id, chapter_id, page_number, problem_number, question_text')
      .in('book_id', gBookIds)
      .order('page_number')
      .order('problem_number')
      .limit(500);
    if (gRowsError) return json({ error: 'Question lookup failed' }, 500);
    if (!gRows || gRows.length === 0) {
      return json({ found: false, reason: 'not-indexed' });
    }
    const gChapterIds = [
      ...new Set(gRows.map((r) => r.chapter_id as string | null)
        .where((c): c is string => c !== null)),
    ];
    const { data: gChRows } = gChapterIds.length > 0
      ? await supabase
          .from('chapters')
          .select('id, number, title_bn, title_en')
          .in('id', gChapterIds)
      : { data: null };
    const gChById = new Map<string, {
      number: number;
      title: string;
    }>();
    for (const c of gChRows ?? []) {
      gChById.set(c.id as string, {
        number: c.number as number,
        title: (gLanguage === 'en' ? c.title_en : c.title_bn) as string,
      });
    }
    return json({
      found: true,
      bookId: gBooks[0].id as string,
      bookTitle: gBooks[0].title as string,
      language: gLanguage,
      questions: gRows.map((r) => {
        const ch = gChById.get(r.chapter_id as string);
        return {
          bookId: r.book_id as string,
          chapterNumber: ch ? ch.number : 0,
          chapterTitle: ch ? ch.title : '',
          page: r.page_number as number,
          problem: r.problem_number as number | null,
          questionText: r.question_text as string,
        };
      }),
    });
  }

  // ---- Mode G: guide question (guide bank, locked 2026-10-29).
  // Input: { guideQuestionId, language }. Returns the VERBATIM
  // guide question + its question-wise unit + marks facts for
  // the client-side marks budget + key gate. NEVER a whole guide.
  // ACTIVATION: guide_questions / guide_chunks come from
  // migration 008 (not applied yet) — until then this branch
  // returns found: false, reason 'guide-unavailable', never a
  // crash and never a substitute. Checked BEFORE the Mode A/B
  // subject/classId validation, which guide requests do not carry.
  // VERBATIM-FIRST (owner order 2026-10-31, reversing the old
  // never-verbatim rule): the client renders groundingSolution
  // as the stage-1 answer ONLY when verbatimKind is 'guide'
  // (or 'corrected' for a curated correction). In every other
  // case groundingSolution stays HIDDEN grounding for the AI
  // only — especially for guide_error rows without a correction
  // yet, whose printed answer must never be shown as trusted. ----
  if (typeof body.guideQuestionId === 'string' &&
      body.guideQuestionId !== '') {
    const gLang = body.language === 'en' ? 'en' : 'bn';
    const gqId = body.guideQuestionId;
    const { data: gq, error: gqError } = await supabase
      .from('guide_questions')
      .select('id, book_id, chapter_id, question_text, question_type, '
        + 'marks, answer_key')
      .eq('id', gqId)
      .maybeSingle();
    if (gqError) {
      return json({ found: false, reason: 'guide-unavailable' });
    }
    if (!gq) return json({ found: false, reason: 'not-indexed' });
    // Optional worked-solution column (008 carries per-problem
    // solutions only if the import includes them). Absent column
    // => empty string, NOT an error: the fallback chunk below
    // carries context instead.
    let groundingSolution = '';
    try {
      const { data: sol, error: solError } = await supabase
        .from('guide_questions')
        .select('guide_solution')
        .eq('id', gqId)
        .maybeSingle();
      if (!solError && sol && typeof sol.guide_solution === 'string') {
        groundingSolution = sol.guide_solution as string;
      }
    } catch {
      groundingSolution = '';
    }
    // Stimulus (Phase 3, 2026-11-02): the question row's own
    // stimulus text + reference, for id-only chat paths (e.g.
    // model-test Ask-AI) that never saw the guide-bank list row.
    // Fetched separately like the tag fetch below: a server
    // without stimulus_ref answers with nulls instead of failing
    // Mode G. Keys are camelCase to match the guide-bank list
    // payload and the app's GuideBankQuestion model
    // (stimulusText/stimulusRef, already read by
    // guide_question_header from list rows); the current Mode G
    // consumer ignores unknown keys, so this is additive only.
    let stimulusText: string | null = null;
    let stimulusRef: string | null = null;
    try {
      const { data: stim, error: stimError } = await supabase
        .from('guide_questions')
        .select('stimulus_text, stimulus_ref')
        .eq('id', gqId)
        .maybeSingle();
      if (!stimError && stim) {
        stimulusText = (stim.stimulus_text as string | null) ?? null;
        stimulusRef = (stim.stimulus_ref as string | null) ?? null;
      }
    } catch {
      stimulusText = null;
      stimulusRef = null;
    }
    // Printed explanation (migration 017, 2026-11-02): the
    // question row's own explanation paragraph, fetched exactly
    // like the stimulus above — a pre-migration server answers
    // with null instead of failing Mode G. Null = the guide
    // prints no explanation for this row.
    let guideExplanation: string | null = null;
    try {
      const { data: expl, error: explError } = await supabase
        .from('guide_questions')
        .select('explanation')
        .eq('id', gqId)
        .maybeSingle();
      if (!explError && expl) {
        guideExplanation = (expl.explanation as string | null) ?? null;
      }
    } catch {
      guideExplanation = null;
    }
    // Options (2026-11-03 explanation fix): the question row's
    // own option texts, fetched exactly like the stimulus above
    // — a pre-migration server answers with [] instead of
    // failing Mode G. Without these, the explanation prompt
    // carried question + key but no options, and the model
    // answered "cannot determine" (first-load bug) or invented
    // option wording (second-load bug). Normalized by the shared
    // helper; [] = genuinely option-less, and the client then
    // shows the honest not-available state instead of calling.
    let options: string[] = [];
    try {
      const { data: opt, error: optError } = await supabase
        .from('guide_questions')
        .select('options')
        .eq('id', gqId)
        .maybeSingle();
      if (!optError && opt) {
        options = normalizeGuideOptions(opt.options);
      }
    } catch {
      options = [];
    }
    const marks = (gq.marks as number | null) ?? null;
    const answerKey = (gq.answer_key as string | null) ?? '';
    const qType = (gq.question_type as string) ?? '';
    const chapterId = (gq.chapter_id as string | null) ?? '';
    // Verbatim gate (migration 012 columns, same try/catch
    // pattern as the tag fetch: a pre-migration server answers
    // with verbatimKind 'none' instead of failing Mode G).
    // guide_error + no correction => 'none' (printed wrong
    // answer is never displayed as trusted). guide_error +
    // correction => 'corrected' (corrected key + note).
    // Otherwise a non-empty solution => 'guide' (verbatim).
    // Empty solution => 'none' (client shows the AI
    // explanation with an honest no-verbatim label).
    let guideError = false;
    let correctedKey = '';
    let correctionNote = '';
    let verbatimKnown = true;
    try {
      const { data: corr, error: corrError } = await supabase
        .from('guide_questions')
        .select('guide_error, corrected_answer_key, correction_note')
        .eq('id', gqId)
        .maybeSingle();
      if (corrError) throw corrError;
      if (corr) {
        guideError = (corr.guide_error as boolean | null) ?? false;
        correctedKey = (corr.corrected_answer_key as string | null) ?? '';
        correctionNote = (corr.correction_note as string | null) ?? '';
      }
    } catch {
      verbatimKnown = false;
    }
    let verbatimKind = 'none';
    let verbatimText = '';
    if (verbatimKnown) {
      if (guideError) {
        if (correctedKey !== '') {
          verbatimKind = 'corrected';
          verbatimText = correctedKey;
        }
      } else if (groundingSolution !== '') {
        verbatimKind = 'guide';
        verbatimText = groundingSolution;
      }
    }
    // Tagged-prose fallback ONLY (Phase 2, 2026-10-31; user
    // order 2026-10-30: no previous/neighbour-chunk fallback in
    // ANY subject). The question row itself tags at most one
    // guide_chunks row it depends on (migration 010:
    // linked_prose_chunk_id, human-curated only). That one row
    // — and nothing else — becomes fallbackChunk. The tag is
    // fetched in a separate try/catch so a pre-migration server
    // (column absent) still answers with fallbackChunk null
    // instead of failing Mode G. Untagged questions keep null:
    // no filler is ever invented to fill the field, and no tag
    // exists for any row until a curation pass proves one.
    let fallbackChunk: {
      text: string; pageStart: number; pageEnd: number;
    } | null = null;
    try {
      const { data: tag, error: tagError } = await supabase
        .from('guide_questions')
        .select('linked_prose_chunk_id')
        .eq('id', gqId)
        .maybeSingle();
      if (!tagError && tag) {
        fallbackChunk = await fetchLinkedChunk(
          supabase,
          'guide_chunks',
          tag.linked_prose_chunk_id as string | null,
        );
      }
    } catch {
      fallbackChunk = null;
    }
    // NO textbook filler chunks (2026-10-30, same user order).
    // The old code returned the chapter's first 2 chunks —
    // unlinked chapter-opening filler, not prose the question
    // depends on — so it is removed outright. Same follow-up
    // as the fallback chunk above (linked-prose retrieval).
    // The response field stays (empty) for client compatibility.
    const textbookChunks: Array<{
      text: string; pageStart: number; pageEnd: number;
    }> = [];
    const { data: gch } = chapterId !== ''
      ? await supabase
        .from('chapters')
        .select('number, title_bn, title_en')
        .eq('id', chapterId)
        .maybeSingle()
      : { data: null };
    return json({
      found: true,
      source: 'guide',
      guideQuestionId: gq.id as string,
      bookId: gq.book_id as string,
      chapterId,
      chapterNumber: gch ? (gch.number as number) : 0,
      chapterTitle: gch
        ? (gLang === 'en' ? gch.title_en : gch.title_bn) as string
        : '',
      questionText: gq.question_text as string,
      questionType: qType,
      options,
      stimulusText,
      stimulusRef,
      guideExplanation,
      marks,
      marksPrinted: marks !== null,
      answerKey,
      unitKind: answerKey !== ''
        ? 'key'
        : (groundingSolution !== '' ? 'solution' : ''),
      groundingSolution,
      groundingSolutionHidden: true,
      // Verbatim-first stage-1 fields. The client renders
      // verbatimText ONLY when verbatimKind is 'guide' or
      // 'corrected'; 'none' means "no trusted verbatim text"
      // (no solution, uncorrected error, or pre-012 server).
      verbatimKind,
      verbatimText,
      correctionNote,
      guideError,
      fallbackChunk,
      textbookChunks,
      budget: marksBudget(marks, qType),
    });
  }

  const subject = body.subject;
  const classId = body.classId;
  const language = body.language === 'en' ? 'en' : 'bn';
  if (typeof subject !== 'string' || subject === '' ||
      typeof classId !== 'number') {
    return json({ error: 'subject and numeric classId are required' }, 400);
  }

  // Books of this class + subject + language that are supplied.
  // Supplied-only enforces the locked-subject rule server-side too.
  // NOTE: source_link is never selected.
  const { data: books, error: booksError } = await supabase
    .from('books')
    .select('id, title')
    .eq('class_id', classId)
    .eq('subject_id', subject)
    .eq('language', language)
    .eq('supplied', true)
    .order('title');
  if (booksError) return json({ error: 'Book lookup failed' }, 500);
  if (!books || books.length === 0) {
    return json({ found: false, reason: 'no-book' });
  }
  const bookIds = books.map((b) => b.id as string);
  const bookTitle = books[0].title as string;

  const chapterOf = async (chapterId: string | null) => {
    if (!chapterId) return null;
    const { data } = await supabase
      .from('chapters')
      .select('number, title_bn, title_en')
      .eq('id', chapterId)
      .maybeSingle();
    return data;
  };

  // ---- Mode B: match by wording (quiz banks) ----
  if (typeof body.questionText === 'string' && body.questionText !== '') {
    const needle = body.questionText.trim();
    if (needle.length < 3) {
      return json({ error: 'questionText is too short' }, 400);
    }
    const { data: rows, error } = await supabase
      .from('book_questions')
      .select('book_id, chapter_id, page_number, problem_number, question_text')
      .in('book_id', bookIds)
      .ilike('question_text', `%${escapeLike(needle)}%`)
      .order('page_number')
      .order('problem_number')
      .limit(5);
    if (error) return json({ error: 'Question lookup failed' }, 500);
    if (!rows || rows.length === 0) {
      return json({ found: false, reason: 'not-indexed' });
    }
    const row = rows[0];
    const ch = await chapterOf(row.chapter_id as string | null);
    return json({
      found: true,
      bookTitle,
      chapterTitle: ch
        ? (language === 'en' ? ch.title_en : ch.title_bn) as string
        : '',
      chapterNumber: ch ? (ch.number as number) : 0,
      page: row.page_number as number,
      problem: (row.problem_number as number | null) ?? 0,
      questionText: row.question_text as string,
    });
  }

  // ---- Mode A: match by position (chapter/page/problem) ----
  const chapter = body.chapter;
  const page = body.page;
  const problem = body.problem;
  if (typeof chapter !== 'number' || typeof page !== 'number' ||
      typeof problem !== 'number') {
    return json({ error: 'chapter, page and problem are required' }, 400);
  }
  const { data: chapters, error: chaptersError } = await supabase
    .from('chapters')
    .select('id, book_id, number, title_bn, title_en')
    .in('book_id', bookIds)
    .eq('number', chapter);
  if (chaptersError) return json({ error: 'Chapter lookup failed' }, 500);
  if (!chapters || chapters.length === 0) {
    return json({ found: false, reason: 'no-chapter' });
  }
  const chapterIds = chapters.map((c) => c.id as string);
  const ch = chapters[0];
  const { data: questions, error: questionsError } = await supabase
    .from('book_questions')
    .select('chapter_id, page_number, problem_number, question_text')
    .in('chapter_id', chapterIds)
    .eq('page_number', page)
    .eq('problem_number', problem)
    .limit(1);
  if (questionsError) return json({ error: 'Question lookup failed' }, 500);
  if (!questions || questions.length === 0) {
    return json({ found: false, reason: 'not-indexed' });
  }
  const q = questions[0];
  const qChapterId = q.chapter_id as string | null;
  const qChapter = chapters.find((c) => c.id === qChapterId);
  const qBookId = (qChapter ? qChapter.book_id : chapters[0].book_id) as string;
  // ---- Phase 3: chunk grounding for Mode A only. Same book +
  // chapter, page-overlapping rows only, reading order, up to
  // 3 — NEVER neighbours (user order 2026-10-30). A chunk
  // query failure must not hide the found question: it
  // degrades to chunks: [] + 'no-chunks'. ----
  const chunks = await fetchChunks(supabase, qBookId, qChapterId, page);
  return json({
    found: true,
    bookTitle,
    chapterTitle: (language === 'en' ? ch.title_en : ch.title_bn) as string,
    chapterNumber: ch.number as number,
    page: q.page_number as number,
    problem: (q.problem_number as number | null) ?? 0,
    questionText: q.question_text as string,
    chunks,
    chunkReason: chunks.length > 0 ? 'chunks-found' : 'no-chunks',
  });
});

// Marks budget bands (LOCKED 2026-10-29; detailed shape spec
// added 2026-10-31) — mirrors the client's marks_budget.dart
// EXACTLY, including the MCQ append. Word counts are
// approximate; step count and shape are the real control. The
// client re-checks step counts and retries once when far
// off-band. This guidance shapes AI explanations only, never
// the verbatim stage-1 display (verbatim-first, 2026-10-31).
const mcqGuidance = ' MCQ: correct option + 1-2 lines why it '
  + 'is correct; at most one line on why the rest are not; '
  + 'never present the key as something to memorize.';
function marksBudget(
  marks: number | null,
  questionType: string,
): { marks: number; maxSteps: number; maxLines: number; guidance: string } {
  let m = marks;
  if (m === null) {
    m = questionType === 'mcq' ? 1 : questionType === 'short' ? 2 : 3;
  }
  m = Math.min(10, Math.max(1, m));
  let base = '';
  let maxSteps = 14;
  let maxLines = 45;
  if (m === 1) {
    maxSteps = 2; maxLines = 4;
    base = '1 mark: direct answer first (value, name, or one '
      + 'line), then 1-2 lines why — one formula or reason in '
      + 'one line. At most 2 steps, 4 lines, about 20-40 '
      + 'words. No preamble, no conclusion, no detailed '
      + 'explanation, no alternative method.';
  } else if (m === 2) {
    maxSteps = 4; maxLines = 10;
    base = '2 marks: 2-4 steps or points, each step = work + '
      + 'one short reason; the result in one line at the end. '
      + 'At most 4 steps, 10 lines, about 40-80 words. No '
      + 'long preamble, no conclusion paragraph, never split '
      + "one step's work into three steps to pad.";
  } else if (m === 3) {
    maxSteps = 7; maxLines = 18;
    base = '3 marks: state the formula or rule, substitute '
      + 'the values, then step-by-step calculation with a '
      + 'brief reason for each step, then the result. '
      + 'Language subjects: points, each with a one-line '
      + 'reason or example. At most 7 steps, 18 lines, about '
      + '80-150 words. No irrelevant background, never repeat '
      + 'the same reason twice.';
  } else if (m === 4) {
    maxSteps = 10; maxLines = 28;
    base = '4 marks: full steps with reasoning, each step '
      + 'with its reason, plus a final VERIFICATION line as '
      + 'the closing check (plug the value back, or check '
      + 'the units) — never end abruptly without it. '
      + 'Creative parts ক/খ/গ/ঘ are written separately, each '
      + 'at its own marks length, never mixed across parts. '
      + 'At most 10 steps, 28 lines, about 150-250 words. '
      + 'No long intro paragraph.';
  } else {
    base = `${m} marks: full structure — a 3-4 line intro (what `
      + 'the question asks), full steps with reasons, '
      + 'a 3-4 line conclusion. Length grows only through '
      + 'reasoning and verification, never padding. At most '
      + '14 steps, 45 lines, about 250-400 words. Never add '
      + 'unnecessary parts.';
  }
  return { marks: m, maxSteps, maxLines,
    guidance: questionType === 'mcq' ? base + mcqGuidance : base };
}
