// Yes Sir AI — Edge grounding helper: matched-unit-only chunk fetch.
//
// Extracted from explain-question/index.ts so the selection rule is
// unit-testable (grounding.test.ts). No supabase-js import here on
// purpose: the caller passes its client, so this module (and its
// tests) run offline.
//
// RULE (user order 2026-10-30, no previous-chunk fallback in ANY
// subject): grounding returns ONLY chunks that overlap the
// question's own printed page. NEVER neighbours: no before/after
// fill, no "nearest in reading order" fill, no chapter-first or
// chapter-opening filler. Fewer overlapping rows => fewer chunks
// returned, never padded. A genuinely matched multi-chunk unit
// (several chunks overlapping the same page) is kept whole —
// the limit is 3 overlapping rows, not 1. On any query failure
// the result is [] so the caller can still return its question
// with chunkReason 'no-chunks' (never a substitute, never a
// guess).

export interface ChunkDb {
  from: (table: string) => any;
}

export interface GroundedChunk {
  text: string;
  pageStart: number;
  pageEnd: number;
}

// The ONE prose chunk a question is tagged as depending on
// (migration 010: guide_questions.linked_prose_chunk_id). Max 1,
// by id only — never a neighbour, never chapter filler, never a
// search. Returns null when the tag is absent, the row is absent,
// or the query fails, so the caller returns fallbackChunk null
// exactly as before. The caller fetches the tag itself in a
// separate try/catch (a missing column on a pre-migration server
// must not break the whole Mode G response); this helper only
// resolves an already-known id.
export async function fetchLinkedChunk(
  db: ChunkDb,
  table: string,
  chunkId: string | null,
): Promise<GroundedChunk | null> {
  if (chunkId === null || chunkId === '') return null;
  try {
    const { data } = await db
      .from(table)
      .select('chunk_text, page_start, page_end')
      .eq('id', chunkId)
      .limit(1);
    const row = (data ?? [])[0] as Record<string, unknown> | undefined;
    if (!row || typeof row.chunk_text !== 'string') return null;
    return {
      text: row.chunk_text as string,
      pageStart: row.page_start as number,
      pageEnd: row.page_end as number,
    };
  } catch {
    return null;
  }
}

// Options normalizer for Mode G (2026-11-03 explanation fix):
// the guide_questions.options jsonb reaches the explanation
// prompt verbatim. Same semantics as guide-bank's optionsToArray
// (string array as-is; Bengali-key object in ক/খ/গ/ঘ/ঙ order;
// anything else []), so a prompt never invents option wording.
// Options are QUESTION CONTENT (as in guide-bank `list`), not a
// key — Mode G already returns answerKey for explanation.
const BENGALI_OPTION_ORDER = ["ক", "খ", "গ", "ঘ", "ঙ"];

export function normalizeGuideOptions(raw: unknown): string[] {
  if (Array.isArray(raw)) return raw.map((e) => String(e));
  if (raw !== null && typeof raw === "object") {
    const obj = raw as Record<string, unknown>;
    const ordered: string[] = [];
    for (const key of BENGALI_OPTION_ORDER) {
      if (typeof obj[key] === "string") ordered.push(obj[key] as string);
    }
    if (ordered.length > 0) return ordered;
    return Object.values(obj).map((e) => String(e));
  }
  return [];
}

// Page-overlapping book_chunks rows for one book + chapter
// around one printed page, in reading order, up to 3. If the
// chapter-scoped lookup finds nothing (e.g. chunk rows with a
// null chapter_id), one book-scoped page-overlap lookup is
// tried — still page-overlapping only, never a whole book or
// chapter dump. Returns [] on any failure.
export async function fetchChunks(
  db: ChunkDb,
  bookId: string,
  chapterId: string | null,
  page: number,
): Promise<GroundedChunk[]> {
  const pick = (r: Record<string, unknown>): GroundedChunk => ({
    text: r.chunk_text as string,
    pageStart: r.page_start as number,
    pageEnd: r.page_end as number,
  });
  const byIndex = (a: GroundedChunk, b: GroundedChunk) =>
    a.pageStart - b.pageStart;
  try {
    if (chapterId) {
      const { data: containing } = await db
        .from("book_chunks")
        .select("chunk_text, page_start, page_end, chunk_index")
        .eq("book_id", bookId)
        .eq("chapter_id", chapterId)
        .lte("page_start", page)
        .gte("page_end", page)
        .order("chunk_index")
        .limit(3);
      const found = (containing ?? []).map(pick);
      if (found.length > 0) {
        // chunk_index order == page order within one chapter.
        return found.sort(byIndex).slice(0, 3);
      }
    }
    const { data: bookOverlap } = await db
      .from("book_chunks")
      .select("chunk_text, page_start, page_end")
      .eq("book_id", bookId)
      .lte("page_start", page)
      .gte("page_end", page)
      .order("page_start")
      .limit(3);
    return (bookOverlap ?? []).map(pick);
  } catch {
    return [];
  }
}
