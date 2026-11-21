// Guide-data consistency audit (repeatable).
//
// Finds, for every class + subject + chapter, the mismatches the owner
// reported: chapter total vs offered type totals, lesson counts vs the
// chapter-scoped list, and creative part maps/order. Run:
//   node tools/audit_guide_consistency.mjs 6 9 10
// Writes docs/guide-consistency-audit.json and prints a summary.
//
// Read-only: only guide-bank `list` / `guideChapters` / `guideLessons`.
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

const sections = { mcq: 'mcq', short: 'short', creative: 'creative' };

async function chapterTotal(cls, subject, ch, section) {
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
  if (j.found !== true || typeof j.total !== 'number') return null;
  return j.total;
}

async function auditSubject(cls, subject) {
  const chs = await post({ action: 'guideChapters', classId: cls, subject });
  const chapters = (chs.guideChapters || []).slice(0, 20);
  const out = [];
  for (const c of chapters) {
    const [mcq, short, creative] = await Promise.all([
      chapterTotal(cls, subject, c.chapter, sections.mcq),
      chapterTotal(cls, subject, c.chapter, sections.short),
      chapterTotal(cls, subject, c.chapter, sections.creative),
    ]);
    const known = [mcq, short, creative].filter((v) => typeof v === 'number');
    const sum = known.reduce((a, b) => a + b, 0);
    out.push({
      chapter: c.chapter,
      chapterTotal: c.totalCount,
      keyed: c.keyedCount,
      mcq,
      short,
      creative,
      offeredSum: known.length ? sum : null,
      mismatch:
        typeof c.totalCount === 'number' && known.length
          ? c.totalCount !== sum
          : null,
    });
  }
  const lessons = await post({
    action: 'guideLessons',
    classId: cls,
    subject,
  });
  const lessonRows = (lessons.lessons || []).slice(0, 6);
  const lessonChecks = [];
  for (const l of lessonRows) {
    const withoutChapter = await post({
      action: 'list',
      classId: cls,
      subject,
      lesson: l.lesson,
      slim: true,
      limit: 1,
      offset: 0,
    });
    lessonChecks.push({
      lesson: l.lesson,
      countByLesson: l.totalCount,
      listNoChapter: withoutChapter.total ?? null,
    });
  }
  const creative = await post({
    action: 'list',
    classId: cls,
    subject,
    chapter: chapters[0]?.chapter ?? 1,
    type: 'creative',
    limit: 4,
    offset: 0,
  });
  const sample = (creative.questions || []).map((q) => ({
    id: q.id,
    marks: q.marks,
    partsType: typeof q.marksParts,
    parts: q.marksParts,
  }));
  return { cls, subject, chapters: out, lessons: lessonChecks, creativeSample: sample };
}

const classes = process.argv.slice(2).map((n) => parseInt(n, 10));
const targets = classes.length ? classes : [6, 9, 10];
const report = [];

for (const cls of targets) {
  const flags = await post({ action: 'guideFlags', classId: cls });
  const subjects = Object.keys(flags.flags || {}).filter(
    (s) => flags.flags[s].hasGuide,
  );
  for (const subject of subjects) {
    report.push(await auditSubject(cls, subject));
  }
}

fs.mkdirSync(new URL('../docs', import.meta.url), { recursive: true });
fs.writeFileSync(
  new URL('../docs/guide-consistency-audit.json', import.meta.url),
  JSON.stringify(report, null, 1),
);
for (const r of report) {
  const bad = r.chapters.filter((c) => c.mismatch === true).length;
  console.log(
    `class${r.cls} ${r.subject}: chapters=${r.chapters.length} mismatch=${bad}`,
  );
}
