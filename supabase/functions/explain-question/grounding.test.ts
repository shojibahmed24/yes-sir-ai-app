// Regression tests for the no-neighbour grounding rule
// (user order 2026-10-30): fetchChunks must return ONLY chunks
// overlapping the question's own printed page — never before/
// after neighbours, never chapter-first filler, never padded
// to a count. No external imports on purpose: `deno test` runs
// this file fully offline (only the relative grounding import).
import { fetchChunks, fetchLinkedChunk, normalizeGuideOptions } from "./grounding.ts";

type Row = {
  chunk_text: string;
  page_start: number;
  page_end: number;
  chunk_index: number;
  book_id: string;
  chapter_id: string | null;
};

function assertEquals<T>(actual: T, expected: T, label: string): void {
  const a = JSON.stringify(actual);
  const e = JSON.stringify(expected);
  if (a !== e) throw new Error(`${label}: expected ${e}, got ${a}`);
}

function assert(cond: boolean, label: string): void {
  if (!cond) throw new Error(`assertion failed: ${label}`);
}

// Minimal in-memory stand-in for the Supabase query builder:
// supports the select/eq/lte/gte/order/limit chain fetchChunks
// uses, evaluated over canned rows.
class FakeQuery {
  private filters: Array<(r: Row) => boolean> = [];
  private sortKey: string | null = null;
  private sortAsc = true;
  constructor(private rows: Row[]) {}
  select(..._args: unknown[]): FakeQuery {
    return this;
  }
  eq(col: string, val: unknown): FakeQuery {
    this.filters.push((r) => (r as unknown as Record<string, unknown>)[col] === val);
    return this;
  }
  lte(col: string, val: number): FakeQuery {
    this.filters.push((r) => (r as unknown as Record<string, number>)[col] <= val);
    return this;
  }
  gte(col: string, val: number): FakeQuery {
    this.filters.push((r) => (r as unknown as Record<string, number>)[col] >= val);
    return this;
  }
  order(col: string, opts?: { ascending?: boolean }): FakeQuery {
    this.sortKey = col;
    this.sortAsc = opts?.ascending !== false;
    return this;
  }
  limit(n: number): Promise<{ data: Row[] }> {
    let out = this.rows.filter((r) => this.filters.every((f) => f(r)));
    if (this.sortKey) {
      const k = this.sortKey;
      const asc = this.sortAsc;
      out = [...out].sort((a, b) => {
        const d = (a as unknown as Record<string, number>)[k] -
          (b as unknown as Record<string, number>)[k];
        return asc ? d : -d;
      });
    }
    return Promise.resolve({ data: out.slice(0, n) });
  }
}

class FakeDb {
  constructor(private rows: Row[]) {}
  from(_table: string): FakeQuery {
    return new FakeQuery(this.rows);
  }
}

const B1 = "BEFORE-NEIGHBOUR";
const A1 = "AFTER-NEIGHBOUR";
const C1 = "CONTAINING-1";
const C2 = "CONTAINING-2";
const X1 = "OTHER-CHAPTER-OVERLAP";

function rows(): Row[] {
  return [
    { chunk_text: B1, page_start: 5, page_end: 6, chunk_index: 0, book_id: "b1", chapter_id: "c1" },
    { chunk_text: C1, page_start: 10, page_end: 12, chunk_index: 1, book_id: "b1", chapter_id: "c1" },
    { chunk_text: C2, page_start: 12, page_end: 13, chunk_index: 2, book_id: "b1", chapter_id: "c1" },
    { chunk_text: A1, page_start: 20, page_end: 21, chunk_index: 3, book_id: "b1", chapter_id: "c1" },
    { chunk_text: X1, page_start: 11, page_end: 13, chunk_index: 1, book_id: "b1", chapter_id: "c2" },
  ];
}

const texts = (cs: Array<{ text: string }>) => cs.map((c) => c.text);

Deno.test("matched unit with neighbours present yields only the matched unit", async () => {
  const got = await fetchChunks(new FakeDb(rows()) as never, "b1", "c1", 12);
  assertEquals(texts(got), [C1, C2], "containing only, in order");
  assert(!texts(got).includes(B1), "before neighbour must not appear");
  assert(!texts(got).includes(A1), "after neighbour must not appear");
});

Deno.test("one containing chunk is never padded to 3", async () => {
  const only = rows().filter((r) => r.chunk_text !== C2);
  const got = await fetchChunks(new FakeDb(only) as never, "b1", "c1", 12);
  assertEquals(texts(got), [C1], "single containing row, no fill");
});

Deno.test("empty chapter falls back to book-scoped page overlap only", async () => {
  const got = await fetchChunks(new FakeDb(rows()) as never, "b1", "cX", 12);
  assertEquals(texts(got), [C1, X1, C2], "book overlap, page_start order");
  assert(!texts(got).includes(B1), "before neighbour must not appear");
  assert(!texts(got).includes(A1), "after neighbour must not appear");
});

Deno.test("null chapter uses book overlap only", async () => {
  const got = await fetchChunks(new FakeDb(rows()) as never, "b1", null, 12);
  assertEquals(texts(got), [C1, X1, C2], "book overlap, page_start order");
  assert(!texts(got).includes(B1), "before neighbour must not appear");
  assert(!texts(got).includes(A1), "after neighbour must not appear");
});

Deno.test("query failure returns empty grounding, never neighbours", async () => {
  const broken = { from: (_t: string): never => { throw new Error("db down"); } };
  const got = await fetchChunks(broken as never, "b1", "c1", 12);
  assertEquals(got, [], "failure degrades to []");
});

// ---- Phase 2 (2026-10-31): linked-prose fetch ----
// fetchLinkedChunk resolves AT MOST ONE row, by id only. It must
// never return a neighbour, a chapter-first row, or a second row.
type LinkRow = {
  id: string;
  chunk_text: string;
  page_start: number;
  page_end: number;
};

class LinkQuery {
  private idVal: string | null = null;
  constructor(private rows: LinkRow[]) {}
  select(..._args: unknown[]): LinkQuery {
    return this;
  }
  eq(col: string, val: unknown): LinkQuery {
    if (col === "id") this.idVal = val as string;
    return this;
  }
  limit(_n: number): Promise<{ data: LinkRow[] }> {
    const out = this.idVal === null
      ? []
      : this.rows.filter((r) => r.id === this.idVal);
    return Promise.resolve({ data: out.slice(0, 1) });
  }
}

class LinkDb {
  constructor(private rows: LinkRow[]) {}
  from(_table: string): LinkQuery {
    return new LinkQuery(this.rows);
  }
}

Deno.test("linked prose resolves exactly the tagged row", async () => {
  const db = new LinkDb([
    { id: "p1", chunk_text: "PROSE-1", page_start: 3, page_end: 4 },
    { id: "p2", chunk_text: "PROSE-2", page_start: 5, page_end: 6 },
  ]);
  const got = await fetchLinkedChunk(db as never, "guide_chunks", "p2");
  assertEquals(got?.text, "PROSE-2", "tagged row only");
});

Deno.test("linked prose absent tag or absent row yields null, never filler", async () => {
  const db = new LinkDb([
    { id: "p1", chunk_text: "PROSE-1", page_start: 3, page_end: 4 },
  ]);
  assertEquals(
    await fetchLinkedChunk(db as never, "guide_chunks", null),
    null,
    "null tag",
  );
  assertEquals(
    await fetchLinkedChunk(db as never, "guide_chunks", "missing"),
    null,
    "missing row",
  );
  assertEquals(
    await fetchLinkedChunk(
      { from: (_t: string): never => { throw new Error("db down"); } } as never,
      "guide_chunks",
      "p1",
    ),
    null,
    "failure degrades to null",
  );
});

// normalizeGuideOptions (2026-11-03 explanation fix): Mode G
// must carry the EXACT stored option texts into the prompt —
// never paraphrased, never invented, never dropped.
Deno.test("normalizeGuideOptions: string array passes through verbatim", () => {
  assertEquals(
    normalizeGuideOptions(["laughs loudly", "cries out sharply"]),
    ["laughs loudly", "cries out sharply"],
    "string array",
  );
});

Deno.test("normalizeGuideOptions: Bengali-key object orders ক/খ/গ/ঘ/ঙ", () => {
  assertEquals(
    normalizeGuideOptions({ "গ": "third", "ক": "first", "খ": "second" }),
    ["first", "second", "third"],
    "bengali-key object",
  );
});

Deno.test("normalizeGuideOptions: null, string and number give []", () => {
  assertEquals(normalizeGuideOptions(null), [], "null");
  assertEquals(normalizeGuideOptions("no options"), [], "string");
  assertEquals(normalizeGuideOptions(4), [], "number");
});

Deno.test("normalizeGuideOptions: empty array stays empty (honest absent state)", () => {
  assertEquals(normalizeGuideOptions([]), [], "empty array");
});
