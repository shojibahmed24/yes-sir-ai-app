// Chapters whose guide rows live ONLY in model-test sets
// (set_id rows, never chapter-scope rows), so the Edge
// chapter list (guideChapters) never returns them — while
// the content is real and browsable through the Sets list.
// Single source of truth for every place that counts or
// lists guide chapters: the global picker (note node),
// the subject flags (home-tile count), and the subject
// guide card. App-only static map: no DB or Edge change.
//
// Verified (Phase-5, Worker C decision paper):
// Civics (3,838 rows): ch 1/3/4 are set-only (404/305/415
// rows); guideChapters returns only 6/7/8.
const Map<String, List<int>> setOnlyChapters = {
  'civics': [1, 3, 4],
};

/// How many set-only chapters a subject has (0 when none).
int setOnlyChapterCount(String subjectId) =>
    setOnlyChapters[subjectId]?.length ?? 0;
