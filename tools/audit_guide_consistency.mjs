// Guide consistency audit v2 — matches the CURRENT UI system.
//
// v1 compared the chapter aggregate (all rows) with the offered type
// sums; that aggregate is no longer shown (it never could match). v2
// checks what the student actually sees:
//  1. every offered type (mcq/short/creative) returns a real total
//  2. lesson counts == the chapter-scoped list they open
//  3. creative parts: ka/kha/ga/gha order and 1/2/3/4 marks
//  4. sets with zero keyed MCQs (locked — informational, not an error)
//
// Usage: node tools/audit_guide_consistency.mjs 6 7 8 9 10
import fs from 'node:fs';

const defines = JSON.parse(
  fs.readFileSync(new URL('../dart_defines.json', import.meta.url), 'utf8'),
);
const BASE = defines.SUPABASE_URL;
const KEY = defines.SUPABASE_ANON_KEY;
const H = {
  apikey: KEY,
  Authorization: `Bearer ${KEY}`,
  'Content-Type': 'application/json',
};

async function post(body) {
  const r = await fetch(`${BASE}/functions/v1/guide-bank`, {
    method: 'POST',
    headers: H,
    body: JSON.stringify(body),
  });
  try {
    return await r.json();
  } catch {
    return {};
  }
}

async function typeTotal(cls, subject, ch, section) {
  const j = await post({
    action: 'list',
    classId: cls,
    subject,
    chapter: ch,
    section,
    slim: true,
    limit: 1,
    offset: 0,
  });
  return j.found === true && typeof j.total === 'number' ? j.total : null;
}

async function auditSubject(cls, subject) {
  const issues = [];
  const chs = await post({ action: 'guideChapters', classId: cls, subject });
  const chapters = (chs.guideChapters || []).slice(0, 20);
  for (const c of chapters) {
    const totals = {};
    for (const type of ['mcq', 'short', 'creative']) {
      totals[type] = await typeTotal(cls, subject, c.chapter, type);
      if (totals[type] === null) {
        issues.push({ kind: 'type-total-missing', chapter: c.chapter, type });
      }
    }
  }
  // Lessons: chapter-scoped count must equal the chapter-scoped list.
  for (const c of chapters.slice(0, 3)) {
    const ls = await post({
      action: 'guideLessons',
      classId: cls,
      subject,
      chapter: c.chapter,
    });
    for (const l of (ls.lessons || []).slice(0, 3)) {
      const list = await post({
        action: 'list',
        classId: cls,
        subject,
        chapter: c.chapter,
        lesson: l.lesson,
        slim: true,
        limit: 1,
        offset: 0,
      });
      const total = list.total;
      if (typeof total !== 'number') {
        issues.push({ kind: 'lesson-list-missing', chapter: c.chapter, lesson: l.lesson });
      } else if (total !== l.totalCount) {
        issues.push({
          kind: 'lesson-count-mismatch',
          chapter: c.chapter,
          lesson: l.lesson,
          count: l.totalCount,
          list: total,
        });
      }
    }
  }
  // Creative parts: letter order + locked marks.
  const creative = await post({
    action: 'list',
    classId: cls,
    subject,
    chapter: chapters[0]?.chapter ?? 1,
    type: 'creative',
    limit: 8,
    offset: 0,
  });
  const expected = { ka: 1, kha: 2, ga: 3, gha: 4 };
  for (const q of creative.questions || []) {
    const tail = String(q.id).split('-').pop().toLowerCase();
    const want = expected[tail];
    if (want != null && q.marks !== want) {
      issues.push({
        kind: 'creative-mark-mismatch',
        id: q.id,
        marks: q.marks,
        expected: want,
      });
    }
    if (q.marksParts != null && typeof q.marksParts !== 'object') {
      issues.push({ kind: 'marks-parts-bad-shape', id: q.id });
    }
  }
  const sets = await post({ action: 'sets', classId: cls, subject });
  const unkeyedSets = (sets.sets || []).filter((s) => !(s.keyedCount > 0));
  return {
    cls,
    subject,
    chapters: chapters.length,
    issues,
    lockedSets: unkeyedSets.length,
    totalSets: (sets.sets || []).length,
  };
}

const classes = process.argv.slice(2).map((n) => parseInt(n, 10));
const targets = classes.length ? classes : [6, 7, 8, 9, 10];
const report = [];

/// Small worker pool: the Edge function is happy with a few parallel
/// readers, and a sequential run of ~2,000 calls took half an hour.
async function pool(items, limit, fn) {
  const out = [];
  let next = 0;
  await Promise.all(
    Array.from({ length: Math.min(limit, items.length) }, async () => {
      for (;;) {
        const i = next++;
        if (i >= items.length) return;
        out[i] = await fn(items[i]);
      }
    }),
  );
  return out;
}

for (const cls of targets) {
  const flags = await post({ action: 'guideFlags', classId: cls });
  const subjects = Object.keys(flags.flags || {}).filter(
    (s) => flags.flags[s].hasGuide,
  );
  const rows = await pool(subjects, 6, (s) => auditSubject(cls, s));
  for (const r of rows) if (r) report.push(r);
}

fs.mkdirSync(new URL('../docs', import.meta.url), { recursive: true });
fs.writeFileSync(
  new URL('../docs/guide-consistency-audit.json', import.meta.url),
  JSON.stringify(report, null, 1),
);

const kinds = {};
for (const r of report) for (const i of r.issues) kinds[i.kind] = (kinds[i.kind] || 0) + 1;
console.log('subjects=' + report.length, 'issues=' + JSON.stringify(kinds));
for (const r of report) {
  if (r.issues.length) {
    const sample = r.issues.slice(0, 2).map((i) => i.kind).join(',');
    console.log(`class${r.cls} ${r.subject}: ${r.issues.length} (${sample})`);
  }
}
