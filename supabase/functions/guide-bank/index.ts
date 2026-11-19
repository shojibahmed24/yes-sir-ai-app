// Yes Sir AI — Edge Function: guide-bank.
//
// WHY THIS EXISTS: public.guide_questions / public.guide_chunks
// have deliberately NO client read policy (migration 008). The
// Flutter app must never query them directly, and the anon key
// must never be able to scrape the guide bank. Only this function,
// running with the SERVICE ROLE key (server-side secret, never
// shipped in the app), reads guide rows — and list responses carry
// NO answer_key and NO guide_solution, only hasKey/hasSolution
// booleans.
// Detail/answer fetching stays with explain-question Mode G, which
// enforces the key-check gate and the paywall gate.
//
// AUTH: deploy with verify_jwt = true (the default), so Supabase
// only forwards requests from signed-in users. This function also
// requires an Authorization header to be present.
//
// BOTH-SYSTEMS CHAPTER RESOLUTION (2026-10-31): a guide row is
// found by chapter NUMBER through EITHER system, because the
// guide chapter and the textbook chapter carry the SAME number
// (user-confirmed: the names are the same). System 1 = textbook
// chapters (chapters.number under the class+subject books,
// guide row chapter_id pointing at one). System 2 = guide-native
// chapter numbers (guide_questions.chapter_number, migration
// 011; used when no textbook chapters exist yet, e.g. Talimit
// class-9 guides whose textbook books are not in the DB). The
// list filter is (chapter_id IN textbook ids for that number)
// OR (chapter_number = that number), so one number serves both.
// Model-test set rows are chapter-free by design (chapter_id
// NULL, chapter_number NULL, set_id set) and are served by
// book_id + set_id, never by a chapter filter.
//
// REQUEST (JSON, POST, body.action):
//   list — chapter bank list (or one model-test set's rows, or
//     a chapter-less bank list):
//     { action: 'list', classId, subject, chapter?, setId?,
//       chapterless?, type?, importantOnly?, marks?, page?,
//       pageSize?, lesson?, section?, offset?, limit? }
//     classId (int) and subject (subject id string) are required.
//     chapter (chapter number, int) is required UNLESS setId is
//     given (a model-test set is subject-wide, not chapter-bound)
//     OR chapterless is true (a chapter-less bank list: bank
//     rows with chapter_number NULL, e.g. English, whose rows
//     carry no chapter number at all) OR board is true (the
//     flagged-board scope, migration 018: out_of_syllabus rows
//     with section board-mcq/board-creative only, any
//     set/chapter — presented as Board sub-sections, not an
//     "Others" bucket). Precedence (see
//     resolveListScope in list.ts): board wins over setId,
//     setId wins over chapterless, chapterless wins over
//     chapter. Normal scopes exclude flagged rows, so a row is
//     never shown twice. A board request on a pre-migration
//     server returns found:false pilot-columns-missing, never
//     an unfiltered retry. A legacy others=true request is
//     rejected with 400, never silently re-routed. A chapterless
//     request on a pre-migration server (chapter_number absent)
//     returns found:false pilot-columns-missing, never an
//     unfiltered retry — the retry cannot express the filter.
//     type: 'mcq' | 'short' | 'creative' | 'problem' | ... (exact
//     match on question_type, lowercase canonical).
//     importantOnly: true => only guide-printed important rows.
//     marks: int => only rows with exactly those printed marks.
//     lesson: "__none__" = rows with NULL/blank lesson;
//     otherwise string like "2.1" (exact match on guide_questions
//     .lesson); null/omitted/"" = all lessons. A non-string
//     lesson is HTTP 400, never silently dropped.
//     section: one of LIST_SECTION_VALUES in list.ts (72 values;
//     see list.ts for the per-subject breakdown; exact match on
//     guide_questions.section); omitted/"" = all sections. Any
//     other value is HTTP 400, never silently treated as all.
//     Pagination (new model): offset (default 0, clamped >= 0)
//     and limit (default 20, clamped 1..50). The legacy page
//     (1-based, default 1) / pageSize (default 20, capped at 20)
//     still work: when offset is absent, from = (page - 1) *
//     limit; when limit is absent, pageSize's cap (20) applies.
//     When both models are sent, offset wins over page and
//     limit wins over pageSize. Response echoes offset, limit,
//     lesson and section so the client can verify the filter.
//     total is the EXACT full filtered count (PostgREST
//     count: 'exact' on the same filtered query — never the
//     page length, never a capped sample), so "আরো দেখুন"
//     paging is honest: hasMore = offset + questions.length
//     < total.
//     Pre-migration (42703) rule: unfiltered requests retry
//     without pilot fields (old behaviour); FILTERED requests
//     (lesson or section given) return { found: false, reason:
//     'pilot-columns-missing' } — never unfiltered rows.
//   sets — per-subject model-test set metadata (no rows):
//     { action: 'sets', classId, subject }
//     Returns distinct non-null set_ids with total/keyed counts.
//     Filtered by book_id (subject-wide), NOT by chapter: set
//     rows carry chapter_id NULL by design and a chapter filter
//     would hide them entirely.
//   guideChapters — guide-native chapter list (no rows):
//     { action: 'guideChapters', classId, subject }
//     Returns [{ chapter, totalCount, keyedCount }] for bank
//     rows (set_id NULL) grouped by guide chapter number,
//     plus `board: { totalCount, keyedCount, mcqCount,
//     creativeCount } | null` — the flagged-board counts
//     (migration 018), counted across sets/chapters, never a
//     guessed chapter number. The two sub-section counts sum
//     to totalCount. Null = none or pre-migration server,
//     never a wrong count.
//     Counts are EXACT: distinct chapters are paged first,
//     then one exact head-count per chapter (total + keyed) —
//     never a capped row sample (the old grouping summed to
//     exactly 1000 on class 9 math). Rows with chapter_number
//     NULL are excluded, so classes whose old rows lack the
//     column (class 7) return empty until a backfill decision.
//     This is what lets the app show guide chapters — and build
//     a quiz pool — for a class+subject whose textbook chapters
//     do not exist yet. Pre-migration servers (chapter_number
//     absent) fall back to textbook-chapter grouping.
//   guideLessons — guide-native lesson list (no rows):
//     { action: 'guideLessons', classId, subject }
//     Returns [{ lesson, totalCount, keyedCount }] for bank
//     rows (set_id NULL) grouped by guide lesson value (see
//     lessons.ts: exact paged distinct scan + head-counts, never
//     a capped row sample; values grouped verbatim, NULL/blank
//     excluded; code-unit order, since book order is not
//     stored). This is what lets the app show a lesson picker
//     for a chapter-less book (Bangla 1st Paper), whose rows
//     carry lessons but no chapter numbers. Pre-migration
//     servers (lesson column absent) return { found: false,
//     reason: 'pilot-columns-missing' } — there is no textbook
//     fallback, because lessons exist only on guide rows; the
//     client then hides the picker and lesson stays optional.
//   search — whole-guide substring search (no rows beyond the
//     cap, no chapter filter):
//     { action: 'search', classId, subject, query, limit? }
//     Returns at most 50 rows (limit clamped 1..50, default 50)
//     of bank rows (set_id NULL) whose question_text contains
//     the query (case-insensitive substring; LIKE wildcards in
//     the query are escaped so they match literally), ordered
//     by chapter_number then id. A blank query returns an
//     empty list, NEVER the whole guide. Payload safety is the
//     same as `list`: id, questionText, questionType, options,
//     marks, chapterNumber, hasKey, guideError — NEVER
//     answer_key, NEVER guide_solution. Pre-migration servers
//     (guide_error/chapter_number absent) retry without those
//     columns and report guideError false, chapterNumber null.
//
// RESPONSE (JSON):
//   list: { found: true, action: 'list', total, page, pageSize,
//           offset, limit, lesson, section,
//           questions: [{ id, questionText, questionType, options,
//             marks, important, setId, hasKey, guideError, lesson,
//             section, stimulusId, stimulusText, stimulusRef, flagNote,
//             hasSolution }] }
//     lesson/section in the response echo the applied filter
//     (null = all). total is the exact filtered count (see the
//     request docs above), not questions.length.
//     Pilot fields (lesson 2.1 phase, 2026-10-31; migration 013):
//     lesson/section/stimulusId/stimulusText come from the row
//     (null when untagged); hasSolution is true iff a solution
//     is stored (non-null and non-empty), false when the guide
//     prints none, null on pre-migration servers (unknown, NOT
//     "no solution"). The solution text itself never appears.
//     guideError (Phase 2, 2026-10-31): true when the row's printed
//     key/solution is proven wrong (guide_questions.guide_error).
//     The client quiz pool excludes guideError rows, so future
//     guides' error rows no longer depend on a hardcoded id list.
//     Pre-migration servers (column absent) answer with
//     guideError: false for every row and the client keeps its
//     hardcoded guard — never a 500 for a missing column.
//     options: ordered array from the stored options JSON (object
//     keyed ক/খ/গ/ঘ => array in that order; stored array =>
//     as-is; null => []). Options are QUESTION CONTENT, not a
//     key: hasKey is the only key-related field, and it is a
//     boolean (answer_key non-empty), never the key itself.
//     Pagination order is id order (stable, deterministic) —
//     NOT printed-page order (guide ids are page-bearing but
//     do not sort lexically by page, e.g. p9 vs p10).
//     Empty chapter / empty bank => found: true, total: 0,
//     questions: [] — an honest empty list, NOT an error.
//   sets: { found: true, action: 'sets',
//           sets: [{ setId, totalCount, keyedCount, gradeBands }] }
//     Ordered by setId. keyedCount counts rows with a non-empty
//     answer_key (the only rows that may ever be scored).
//     gradeBands is the set's printed bands ({A:[lo,hi],...})
//     from guide_set_metadata, or null when no metadata exists.
//   guideLessons: { found: true, action: 'guideLessons',
//           lessons: [{ lesson, totalCount, keyedCount }] }
//     Ordered by lesson value (code-unit order). keyedCount as
//     for sets. Empty book => lessons: [] (honest empty, not an
//     error). Pre-migration server => { found: false, reason:
//     'pilot-columns-missing' } (see the request docs above).
//   Unknown class/subject => { found: false, reason: 'no-book' }.
//   Tables missing (008 not applied) => HTTP 500
//     { error: 'guide-tables-missing' } — an error, never an
//     empty list, so the client shows unavailable, not empty.
//   Errors: { error } with HTTP 400 (bad request) or 500
//     (server misconfiguration — no secret is ever echoed).
//
// DEPLOY: see README.md in this folder. No key is stored here.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { fetchNativeGuideChapterCounts } from './chapters.ts';
import { fetchNativeGuideLessonCounts } from './lessons.ts';
import {
  clampSearchLimit,
  escapeLikePattern,
  shapeSearchRow,
} from './search.ts';
import {
  clampListLimit,
  clampListOffset,
  expandListSection,
  isFilteredListRequest,
  isValidListSection,
  listPreMigrationOutcome,
  NO_LESSON_FILTER,
  normalizeListLesson,
  PILOT_COLUMNS_MISSING_REASON,
  resolveListScope,
  shapeListRow,
  shapeSlimListRow,
} from './list.ts';

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

function isMissingTable(error: { code?: string } | null): boolean {
  return !!error && error.code === '42P01';
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
    return json({ error: 'bad-request' }, 400);
  }
  const action = body.action;
  if (action !== 'list' && action !== 'sets' &&
      action !== 'guideChapters' && action !== 'guideLessons' &&
      action !== 'search' && action !== 'get') {
    return json({ error: 'bad-request' }, 400);
  }
  const supabase = createClient(supabaseUrl, serviceKey);

  // 'get' is id-only by contract (quick-load Phase 3): it runs
  // before classId/subject validation, which applies to the
  // scoped actions below.
  if (action === 'get') {
    // Full single row by id (quick-load Phase 3): list screens
    // show slim rows; opening one fetches its full row here.
    // Ids are globally unique, so no book/scope resolution.
    // On a pre-migration server the pilot-column select fails
    // honestly (500) and the client falls back to the slim row
    // instead of blocking the open.
    const id = body.id;
    if (typeof id !== 'string' || id === '') {
      return json({ error: 'bad-request' }, 400);
    }
    const { data, error } = await supabase
      .from('guide_questions')
      .select(
        'id, question_text, question_type, options, marks, important, ' +
          'set_id, answer_key, guide_error, chapter_number, lesson, ' +
          'section, stimulus_id, stimulus_text, stimulus_ref, ' +
          'flag_note, guide_solution, model_question_id, mcq_group, marks_parts',
      )
      .eq('id', id)
      .maybeSingle();
    if (error) {
      if (isMissingTable(error)) {
        return json({ error: 'guide-tables-missing' }, 500);
      }
      return json({ error: 'query-failed' }, 500);
    }
    if (!data) {
      return json({ found: false, action: 'get' });
    }
    return json({
      found: true,
      action: 'get',
      question: shapeListRow(data as unknown as Record<string, unknown>, true),
    });
  }

  const classId = body.classId;
  const subject = body.subject;
  if (typeof classId !== 'number' || !Number.isInteger(classId) ||
      typeof subject !== 'string' || subject === '') {
    return json({ error: 'bad-request' }, 400);
  }

  // Resolve the class+subject book rows (any language: a guide row
  // points at one textbook book row, bn or en, via book_id).
  // Class 9-10 shared-book fallback (user-confirmed: classes 9
  // and 10 use the SAME book): when class 10 has no book row of
  // its own for the subject, the class-9 book serves it. This
  // only fills a gap — a real class-10 book always wins.
  let books: { id: unknown }[] | null = null;
  {
    const res = await supabase
      .from('books')
      .select('id')
      .eq('class_id', classId)
      .eq('subject_id', subject);
    if (res.error) {
      if (isMissingTable(res.error)) {
        return json({ error: 'guide-tables-missing' }, 500);
      }
      return json({ error: 'query-failed' }, 500);
    }
    books = res.data;
    if ((!books || books.length === 0) && classId === 10) {
      const fallback = await supabase
        .from('books')
        .select('id')
        .eq('class_id', 9)
        .eq('subject_id', subject);
      if (fallback.error) {
        return json({ error: 'query-failed' }, 500);
      }
      books = fallback.data;
    }
  }
  if (!books || books.length === 0) {
    return json({ found: false, reason: 'no-book' });
  }
  const bookIds = books.map((b) => b.id as string);

  if (action === 'search') {
    // Whole-guide search: bank rows only (set_id NULL), no
    // chapter filter — this is what lets a query find
    // questions in chapters the user has not opened. A blank
    // query returns an empty list, NEVER the whole guide.
    const rawQuery = body.query;
    const query = typeof rawQuery === 'string' ? rawQuery.trim() : '';
    if (query === '') {
      return json({ found: true, action: 'search', total: 0, questions: [] });
    }
    const limit = clampSearchLimit(body.limit);
    const pattern = `%${escapeLikePattern(query)}%`;
    const buildSearch = (withNewCols: boolean) => {
      let q = supabase
        .from('guide_questions')
        .select(
          'id, question_text, question_type, options, marks, answer_key' +
            (withNewCols
              ? ', guide_error, chapter_number, marks_parts'
              : ''),
        )
        .in('book_id', bookIds)
        .is('set_id', null)
        .ilike('question_text', pattern);
      // Chapter-first order (null chapter numbers last), then
      // stable id order. Pre-migration servers have no
      // chapter_number column, so they order by id only.
      if (withNewCols) q = q.order('chapter_number').order('id');
      else q = q.order('id');
      return q.limit(limit);
    };
    type SearchRow = Record<string, unknown>;
    let searchData: SearchRow[] | null = null;
    let searchError: { code?: string } | null = null;
    {
      const res = await buildSearch(true);
      searchData = res.data as SearchRow[] | null;
      searchError = res.error as { code?: string } | null;
    }
    let guideErrorKnown = true;
    if (searchError && searchError.code === '42703') {
      // Pre-migration server: retry without the new columns.
      guideErrorKnown = false;
      const res = await buildSearch(false);
      searchData = res.data as SearchRow[] | null;
      searchError = res.error as { code?: string } | null;
    }
    if (searchError) {
      if (isMissingTable(searchError)) {
        return json({ error: 'guide-tables-missing' }, 500);
      }
      return json({ error: 'query-failed' }, 500);
    }
    const questions = (searchData ?? []).map((r) =>
      shapeSearchRow(r, guideErrorKnown));
    return json({ found: true, action: 'search', total: questions.length, questions });
  }

  if (action === 'guideChapters') {
    // Exact native counts (chapters.ts): distinct chapters via
    // paged chapter_number values, then one exact head-count
    // per chapter (total + keyed). The old code grouped a
    // capped row fetch, so totals were sample counts (class 9
    // math summed to exactly 1000). On 42703 (chapter_number
    // absent) the pre-migration fallback below runs unchanged.
    // Board (migration 018): exact head-counts for flagged
    // board rows, any set/chapter. Any error (incl. 42703 on
    // a pre-migration server) degrades to null, never a 500:
    // no Board entry means "none or unknown", never a
    // wrong count. Zero flagged rows also yields null.
    let board: {
      totalCount: number;
      keyedCount: number;
      mcqCount: number;
      creativeCount: number;
    } | null = null;
    try {
      // Flagged BOARD rows only: the section filter makes
      // totalCount exactly mcqCount + creativeCount, so the
      // Board tile and its two sub-sections can never disagree.
      const flagged = (section?: string) => {
        let q = supabase
          .from('guide_questions')
          .select('id', { count: 'exact', head: true })
          .in('book_id', bookIds)
          .eq('out_of_syllabus', true)
          .in('section', ['board-mcq', 'board-creative']);
        if (section !== undefined) q = q.eq('section', section);
        return q;
      };
      const totalRes = await flagged();
      const keyedRes = await flagged()
        .not('answer_key', 'is', null)
        .neq('answer_key', '');
      const mcqRes = await flagged('board-mcq');
      const creativeRes = await flagged('board-creative');
      if (
        !totalRes.error && !keyedRes.error &&
        !mcqRes.error && !creativeRes.error &&
        typeof totalRes.count === 'number' &&
        typeof keyedRes.count === 'number' &&
        typeof mcqRes.count === 'number' &&
        typeof creativeRes.count === 'number' && totalRes.count > 0
      ) {
        board = {
          totalCount: totalRes.count,
          keyedCount: keyedRes.count,
          mcqCount: mcqRes.count,
          creativeCount: creativeRes.count,
        };
      }
    } catch {
      board = null;
    }
    const nativeResult = await fetchNativeGuideChapterCounts({
      fetchChapterNumberPage: async (from, to) => {
        const res = await supabase
          .from('guide_questions')
          .select('chapter_number')
          .in('book_id', bookIds)
          .is('set_id', null)
          .not('chapter_number', 'is', null)
          .range(from, to);
        return { data: res.data, error: res.error };
      },
      countTotal: async (chapter) => {
        const res = await supabase
          .from('guide_questions')
          .select('id', { count: 'exact', head: true })
          .in('book_id', bookIds)
          .is('set_id', null)
          .eq('chapter_number', chapter);
        return { count: res.count, error: res.error };
      },
      countKeyed: async (chapter) => {
        const res = await supabase
          .from('guide_questions')
          .select('id', { count: 'exact', head: true })
          .in('book_id', bookIds)
          .is('set_id', null)
          .eq('chapter_number', chapter)
          .not('answer_key', 'is', null)
          .neq('answer_key', '');
        return { count: res.count, error: res.error };
      },
    });
    if (nativeResult.kind === 'fallback') {
      const { data: chapters, error: chError } = await supabase
        .from('chapters')
        .select('id, number')
        .in('book_id', bookIds);
      if (chError) {
        if (isMissingTable(chError)) {
          return json({ error: 'guide-tables-missing' }, 500);
        }
        return json({ error: 'query-failed' }, 500);
      }
      const numberById = new Map<string, number>();
      for (const c of chapters ?? []) {
        numberById.set(c.id as string, c.number as number);
      }
      const { data: rows, error: rowsError } = await supabase
        .from('guide_questions')
        .select('chapter_id, answer_key')
        .in('book_id', bookIds)
        .is('set_id', null)
        .limit(5000);
      if (rowsError) {
        if (isMissingTable(rowsError)) {
          return json({ error: 'guide-tables-missing' }, 500);
        }
        return json({ error: 'query-failed' }, 500);
      }
      const counts = new Map<number, { total: number; keyed: number }>();
      for (const r of rows ?? []) {
        const n = numberById.get(r.chapter_id as string);
        if (n === undefined) continue;
        const entry = counts.get(n) ?? { total: 0, keyed: 0 };
        entry.total += 1;
        const key = r.answer_key as string | null;
        if (key !== null && key !== '') entry.keyed += 1;
        counts.set(n, entry);
      }
      const guideChapters = [...counts.entries()]
        .sort((a, b) => a[0] - b[0])
        .map(([chapter, c]) => ({
          chapter,
          totalCount: c.total,
          keyedCount: c.keyed,
        }));
      return json({
        found: true,
        action: 'guideChapters',
        guideChapters,
        board,
      });
    }
    if (nativeResult.kind === 'missing-table') {
      return json({ error: 'guide-tables-missing' }, 500);
    }
    if (nativeResult.kind === 'failed') {
      return json({ error: 'query-failed' }, 500);
    }
    return json({
      found: true,
      action: 'guideChapters',
      guideChapters: nativeResult.chapters,
      board,
    });
  }

  if (action === 'guideLessons') {
    // Exact native counts (lessons.ts): distinct lesson values
    // via paged lesson values, then one exact head-count per
    // lesson (total + keyed) — same shape as guideChapters, but
    // for the lesson column, which is what chapter-less books
    // (Bangla) browse by. Bank rows only (set_id NULL); rows
    // with lesson NULL or blank carry no lesson and are
    // excluded. Values group VERBATIM: the app sends the
    // returned string back as the list lesson filter, and the
    // list .eq() matches it exactly. On 42703 (lesson column
    // absent) there is no textbook fallback — lessons exist
    // only on guide rows — so the client gets an honest
    // found:false and the lesson picker stays hidden (lesson
    // is optional for chapter-less browsing).
    const nativeResult = await fetchNativeGuideLessonCounts({
      fetchLessonPage: async (from, to) => {
        const res = await supabase
          .from('guide_questions')
          .select('lesson')
          .in('book_id', bookIds)
          .is('set_id', null)
          .not('lesson', 'is', null)
          .range(from, to);
        return { data: res.data, error: res.error };
      },
      countTotal: async (lesson) => {
        const res = await supabase
          .from('guide_questions')
          .select('id', { count: 'exact', head: true })
          .in('book_id', bookIds)
          .is('set_id', null)
          .eq('lesson', lesson);
        return { count: res.count, error: res.error };
      },
      countKeyed: async (lesson) => {
        const res = await supabase
          .from('guide_questions')
          .select('id', { count: 'exact', head: true })
          .in('book_id', bookIds)
          .is('set_id', null)
          .eq('lesson', lesson)
          .not('answer_key', 'is', null)
          .neq('answer_key', '');
        return { count: res.count, error: res.error };
      },
    });
    if (nativeResult.kind === 'fallback') {
      return json({
        found: false,
        action: 'guideLessons',
        reason: PILOT_COLUMNS_MISSING_REASON,
      });
    }
    if (nativeResult.kind === 'missing-table') {
      return json({ error: 'guide-tables-missing' }, 500);
    }
    if (nativeResult.kind === 'failed') {
      return json({ error: 'query-failed' }, 500);
    }
    return json({
      found: true,
      action: 'guideLessons',
      lessons: nativeResult.lessons,
    });
  }

  if (action === 'sets') {
    // Subject-wide by book_id: set rows carry chapter_id NULL
    // by design, so a chapter filter would hide them entirely.
    // Distinct set_ids with counts. Supabase-js has no GROUP BY,
    // so fetch the two light columns and aggregate here. Fetched
    // in pages: a single request is clamped by the server's
    // max-rows (observed live: exactly 1000 rows despite
    // .limit(5000)), which silently truncated set counts once a
    // subject passed 1000 set rows (English Paper-I: 3299 test
    // rows). Pagination removes the cap; the loop stops at a
    // short page.
    // Flagged rows (migration 018) are excluded from set
    // counts: they live under Board, not their board set —
    // otherwise a set's count and its list rows would
    // disagree. On a pre-migration server the flag column is
    // absent (42703), so the filtered fetch retries
    // unfiltered — correct there, because no flagged rows
    // can exist yet.
    const fetchSetRows = async (excludeFlagged: boolean) => {
      const out: { set_id: unknown; answer_key: unknown }[] = [];
      const PAGE = 1000;
      for (let offset = 0;; offset += PAGE) {
        let q = supabase
          .from('guide_questions')
          .select('set_id, answer_key')
          .in('book_id', bookIds)
          .not('set_id', 'is', null);
        if (excludeFlagged) {
          q = q.or('out_of_syllabus.is.null,out_of_syllabus.eq.false');
        }
        const { data: page, error: rowsError } = await q
          .range(offset, offset + PAGE - 1);
        if (rowsError) throw rowsError;
        if (!page || page.length === 0) break;
        out.push(...page);
        if (page.length < PAGE) break;
      }
      return out;
    };
    let rows: { set_id: unknown; answer_key: unknown }[] = [];
    let setRowsError: { code?: string } | null = null;
    try {
      rows = await fetchSetRows(true);
    } catch (e) {
      if ((e as { code?: string }).code === '42703') {
        try {
          rows = await fetchSetRows(false);
        } catch (e2) {
          setRowsError = e2 as { code?: string };
        }
      } else {
        setRowsError = e as { code?: string };
      }
    }
    if (setRowsError) {
      if (isMissingTable(setRowsError)) {
        return json({ error: 'guide-tables-missing' }, 500);
      }
      return json({ error: 'query-failed' }, 500);
    }
    const counts = new Map<string, { total: number; keyed: number }>();
    for (const r of rows ?? []) {
      const setId = r.set_id as string;
      const entry = counts.get(setId) ?? { total: 0, keyed: 0 };
      entry.total += 1;
      const key = r.answer_key as string | null;
      if (key !== null && key !== '') entry.keyed += 1;
      counts.set(setId, entry);
    }
    // Phase 3: per-set metadata (grade bands) from the new
    // guide_set_metadata table. A missing table (pre-migration)
    // or any error degrades to null bands, never a 500:
    // counts are this action's contract, bands are additive.
    const meta = new Map<string, unknown>();
    try {
      const { data: metaRows, error: metaError } = await supabase
        .from('guide_set_metadata')
        .select('set_id, grade_bands')
        .in('book_id', bookIds);
      if (!metaError && metaRows) {
        for (const m of metaRows) {
          meta.set(m.set_id as string, m.grade_bands as unknown);
        }
      }
    } catch {
      // No metadata: every set reports gradeBands null.
    }
    const sets = [...counts.entries()]
      .sort((a, b) => (a[0] < b[0] ? -1 : 1))
      .map(([setId, c]) => ({
        setId,
        totalCount: c.total,
        keyedCount: c.keyed,
        gradeBands: meta.get(setId) ?? null,
      }));
    return json({ found: true, action: 'sets', sets });
  }

  // ---- action: 'list' ----
  const setId = body.setId;
  const chapter = body.chapter;
  const setIdGiven = typeof setId === 'string' && setId !== '';
  const chapterGiven = typeof chapter === 'number' &&
    Number.isInteger(chapter);
  // chapterless counts only when exactly boolean true; any
  // other truthy value is ignored, never treated as a scope.
  // board likewise: only exactly true selects the Board scope.
  // The removed Others scope is rejected outright: a legacy
  // others=true request must never silently fall through to
  // another scope and return the wrong rows.
  if (body.others === true) {
    return json({ error: 'bad-request' }, 400);
  }
  const chapterless = body.chapterless === true;
  const boardScope = body.board === true;
  const listScope = resolveListScope(
    setIdGiven,
    chapterless,
    chapterGiven,
    boardScope,
  );
  if (listScope === null) {
    return json({ error: 'bad-request' }, 400);
  }
  const type = body.type;
  const importantOnly = body.importantOnly === true;
  const marks = body.marks;
  // Server-side lesson/section filters (new search-flow UI).
  // Invalid values are 400 — a filter is never silently dropped,
  // because dropping it would return unfiltered rows as if they
  // were filtered. Empty string means "all", like type '' below.
  const lessonRaw = body.lesson;
  if (
    lessonRaw !== null && lessonRaw !== undefined &&
    typeof lessonRaw !== 'string'
  ) {
    return json({ error: 'bad-request' }, 400);
  }
  const lesson = normalizeListLesson(lessonRaw);
  const sectionRaw = body.section;
  let section: string | null = null;
  if (typeof sectionRaw === 'string' && sectionRaw !== '') {
    if (!isValidListSection(sectionRaw)) {
      return json({ error: 'bad-request' }, 400);
    }
    section = sectionRaw;
  } else if (
    sectionRaw !== null && sectionRaw !== undefined &&
    sectionRaw !== ''
  ) {
    return json({ error: 'bad-request' }, 400);
  }
  const filteredRequest = isFilteredListRequest(lesson, section);
  // Quick-load: bulk (one call for a whole scope) and slim
  // (small rows for list screens). Bulk forces offset 0 and a
  // 2000-row cap; the remainder loop below covers PostgREST's
  // per-request clamp. Slim only changes shaping, never rows.
  const bulk = body.bulk === true;
  const slim = body.slim === true;
  // Pagination: new offset/limit model, legacy page/pageSize
  // still honoured (see the header docs for precedence).
  const pageRaw = body.page;
  const page = typeof pageRaw === 'number' && Number.isInteger(pageRaw) &&
      pageRaw >= 1
    ? pageRaw
    : 1;
  const offsetGiven = typeof body.offset === 'number' &&
    Number.isInteger(body.offset) && body.offset >= 0;
  const limitGiven = typeof body.limit === 'number' &&
    Number.isInteger(body.limit);
  const pageSizeRaw = body.pageSize;
  const pageSize = limitGiven
    ? clampListLimit(body.limit)
    : typeof pageSizeRaw === 'number' && Number.isInteger(pageSizeRaw)
    ? Math.min(Math.max(pageSizeRaw, 1), 20)
    : 20;
  const offset = offsetGiven ? clampListOffset(body.offset) : (page - 1) * pageSize;
  const effectivePage = offsetGiven
    ? Math.floor(offset / pageSize) + 1
    : page;
  const from = bulk ? 0 : offset;
  const queryLimit = bulk ? 2000 : pageSize;

  // Textbook chapter ids for this number (system 1). Empty is
  // normal when no textbook chapters exist yet — system 2
  // (chapter_number) still finds the guide rows, so there is no
  // early empty return here. Looked up only for the chapter
  // scope: set and chapterless scopes never use it.
  let chapterIds: string[] = [];
  if (listScope === 'chapter') {
    const { data: chapters, error: chError } = await supabase
      .from('chapters')
      .select('id')
      .in('book_id', bookIds)
      .eq('number', chapter);
    if (chError) {
      if (isMissingTable(chError)) {
        return json({ error: 'guide-tables-missing' }, 500);
      }
      return json({ error: 'query-failed' }, 500);
    }
    chapterIds = (chapters ?? []).map((c) => c.id as string);
  }

  const buildQuery = (withNewCols: boolean) => {
    // Pilot columns (migration 013) ride with the other new
    // columns: guide_solution is selected ONLY to derive the
    // hasSolution boolean and never reaches the payload.
    let q = supabase
      .from('guide_questions')
      .select(
        'id, question_text, question_type, options, marks, important, ' +
          'set_id, answer_key' +
          (withNewCols
            ? ', guide_error, chapter_number, lesson, section, ' +
              'stimulus_id, stimulus_text, stimulus_ref, flag_note, ' +
              'guide_solution, model_question_id, mcq_group, marks_parts, ' +
              'suggestion_kind, suggestion_star, suggestion_poricched, ' +
              'suggestion_shironam, linked_directive_ids'
            : ''),
        { count: 'exact' },
      )
      .in('book_id', bookIds);
    if (listScope === 'board') {
      // Board scope: flagged BOARD rows only, any
      // set/chapter. The section filter below narrows this
      // to one sub-section (board-mcq or board-creative).
      q = q.eq('out_of_syllabus', true)
        .in('section', ['board-mcq', 'board-creative']);
    } else if (listScope === 'set') {
      // Sets are subject-wide: book_id + set_id only. A chapter
      // filter here would hide set rows (chapter_id NULL).
      q = q.eq('set_id', setId);
    } else if (listScope === 'chapterless') {
      // Chapter-less bank lists bank rows only (set_id NULL)
      // with no guide-native chapter number. On the
      // pre-migration retry path this branch is unreachable:
      // a 42703 on a chapterless request returns
      // pilot-columns-missing before any retry (see below),
      // so withNewCols is always true here.
      q = q.is('set_id', null);
      if (withNewCols) {
        q = q.is('chapter_number', null);
      }
    } else {
      // Chapter bank lists bank rows only; model-test rows (set_id
      // set) are served through the sets action + setId filter.
      q = q.is('set_id', null);
      if (withNewCols) {
        // Both systems, one number: textbook chapter_id OR the
        // guide-native chapter_number.
        if (chapterIds.length > 0) {
          q = q.or(
            `chapter_id.in.(${chapterIds.join(',')}),` +
              `chapter_number.eq.${chapter}`,
          );
        } else {
          q = q.eq('chapter_number', chapter);
        }
      } else {
        // Pre-migration fallback: textbook chapters only. An
        // empty id list means an honest empty list, not an error.
        if (chapterIds.length === 0) {
          q = q.eq('chapter_id', '__none__');
        } else {
          q = q.in('chapter_id', chapterIds);
        }
      }
    }
    if (listScope !== 'board' && withNewCols) {
      // Normal scopes exclude flagged rows (NULL = never
      // flagged): flagged rows live under Board alone, never
      // duplicated here. Only in the withNewCols query: on the
      // pre-migration retry the column does not exist, and no
      // flagged rows can exist there either.
      q = q.or('out_of_syllabus.is.null,out_of_syllabus.eq.false');
    }
    if (typeof type === 'string' && type !== '') {
      q = q.eq('question_type', type);
    }
    if (importantOnly) {
      q = q.eq('important', true);
    }
    if (typeof marks === 'number' && Number.isInteger(marks)) {
      q = q.eq('marks', marks);
    }
    if (withNewCols) {
      // Exact-equality filters on the pilot columns (migration
      // 013). Only applied when the columns exist: on the
      // pre-migration retry path these filters are never added
      // — and a filtered request never reaches that retry (see
      // the 42703 branch below), so no filtered request can
      // silently degrade to unfiltered rows.
      if (lesson === NO_LESSON_FILTER) {
        q = q.or('lesson.is.null,lesson.eq.');
      } else if (lesson !== null) {
        q = q.eq('lesson', lesson);
      }
      if (section !== null) {
        const raw = expandListSection(section) as string[];
        q = raw.length === 1 ? q.eq('section', raw[0]) : q.in('section', raw);
      }
    }
    return q;
  };
  // Explicitly typed (not destructured): the two buildQuery
  // variants have different select shapes, and destructuring
  // let-bindings from the first await mis-types the retry.
  type GuideRow = Record<string, unknown>;
  let data: GuideRow[] | null = null;
  let count: number | null = null;
  let error: { code?: string } | null = null;
  {
    const res = await buildQuery(true)
      .order('id')
      .range(from, from + queryLimit - 1);
    data = res.data as GuideRow[] | null;
    count = res.count;
    error = res.error as { code?: string } | null;
  }
  let guideErrorKnown = true;
  if (error && error.code === '42703') {
    // Pre-migration server: guide_error and/or chapter_number
    // (and the pilot lesson/section columns) absent.
    // FILTERED requests must NOT retry: the retry query cannot
    // express the lesson/section filter, so it would return
    // unfiltered rows disguised as a filtered list. Return an
    // honest found:false instead, so the client shows an
    // unavailable state. CHAPTERLESS requests must NOT retry
    // either: the retry query has no chapter_number column, so
    // it cannot express 'chapter_number IS NULL' — retrying on
    // chapter_id alone would return rows that DO carry a
    // guide-native chapter number.
    if (
      listPreMigrationOutcome(filteredRequest) === 'pilot-columns-missing' ||
      listScope === 'chapterless' ||
      listScope === 'board'
    ) {
      return json({
        found: false,
        action: 'list',
        reason: PILOT_COLUMNS_MISSING_REASON,
      });
    }
    // Unfiltered: retry with the old columns only; every row
    // then reports guideError: false and the client's hardcoded
    // guard still applies. Any other error is a real failure.
    guideErrorKnown = false;
    const res = await buildQuery(false)
      .order('id')
      .range(from, from + queryLimit - 1);
    data = res.data as GuideRow[] | null;
    count = res.count;
    error = res.error as { code?: string } | null;
  }
  if (error) {
    if (isMissingTable(error)) {
      return json({ error: 'guide-tables-missing' }, 500);
    }
    return json({ error: 'query-failed' }, 500);
  }
  // Bulk remainder: PostgREST clamps a single request (default
  // 1000 rows), so a bulk scope larger than one range needs
  // follow-up ranges. Same query variant (guideErrorKnown)
  // and same id order, so bulk rows match paged rows exactly.
  // A remainder failure fails honestly (client falls back to
  // paging) instead of serving a partial scope as complete.
  if (bulk && count !== null) {
    let allRows = data ?? [];
    while (allRows.length < count && allRows.length < 2000) {
      const res2 = await buildQuery(guideErrorKnown)
        .order('id')
        .range(allRows.length, Math.min(allRows.length + 999, 1999));
      if (res2.error) {
        return json({ error: 'query-failed' }, 500);
      }
      const more = (res2.data as unknown as GuideRow[] | null) ?? [];
      if (more.length === 0) break;
      allRows = [...allRows, ...more];
    }
    data = allRows;
  }
  // Shaped by shapeListRow (see list.ts): pilot fields plus the
  // same key/solution safety as before. On the pre-migration
  // retry, pilot fields report null and hasSolution reports
  // null (unknown); guideError keeps its false retry semantics.
  // Slim only changes shaping (Phase 3), never the rows.
  const questions = (data ?? []).map((r) =>
    slim ? shapeSlimListRow(r, guideErrorKnown) : shapeListRow(r, guideErrorKnown));
  // total is the EXACT filtered count from PostgREST
  // count: 'exact' on the filtered query above (set in
  // buildQuery's select) — the full filtered count, not the page
  // length and not a capped sample. count falls back to the page
  // length only if the server returns no count at all.
  return json({
    found: true,
    action: 'list',
    total: count ?? questions.length,
    page: bulk ? 1 : effectivePage,
    pageSize: queryLimit,
    offset: from,
    limit: queryLimit,
    lesson,
    section,
    board: listScope === 'board',
    bulk,
    questions,
  });
});
