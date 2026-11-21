// Creative-pattern scan for the new search flow (user rule
// 2026-11-08): the creative form follows the PATTERN — stimulus
// + 4 parts + marks 1,2,3,4 — in ANY subject or class, so the
// creative type cannot be served by one server section
// ('creative' misses model/board/chapter-model creative rows).
// This scan fetches unfiltered chapter pages (full rows: the
// Edge defaults slim=false, so stimulusId arrives) and matches
// creative-family rows sharing a stimulus, in Edge id order.
// Pages are scanned 20 at a time; `total` stays unknown and
// hasMore means "the server list is not exhausted yet".
// Lesson matches client-side when given (rows carry lesson on
// the new server). On a server whose rows carry no lesson tag
// at all, a lesson-filtered scan honestly reports filterPending
// instead of an empty page — untagged rows are never presented
// as "no creative questions in this lesson".
import '../models/guide_bank_model.dart';
import 'guide_flow_client_scan.dart';
import 'guide_flow_models.dart';
import '../../features/learn/widgets/guide_creative_parts.dart';

/// Pattern match for the creative form: a creative-family row
/// sharing a stimulus. Marks are NOT part of the scan match:
/// part rows with unmarked (null) marks exist in live data and
/// group by stimulus all the same; the 4-part / marks 1-4 shape
/// is verified at grouping time, never by dropping rows here.
bool isCreativePatternRow(GuideBankQuestion q) {
  final sid = q.stimulusId;
  return sid != null && sid.isNotEmpty && isCreativeFamilyType(q.questionType);
}

bool _lessonMatches(GuideBankQuestion r, String? lesson) =>
    lesson == null || r.lesson == lesson;

/// One display page (<= 20 matched rows) from a creative-pattern
/// scan. The scanOffset is the server offset to resume from;
/// nextScanOffset resumes the scan on "আরো দেখুন".
Future<GuideFlowPage> guideFlowCreativePatternPage({
  required GuideFlowPost fetch,
  required String subject,
  required int schoolClass,
  required int chapter,
  required String? lesson,
  required int scanOffset,
}) async {
  const pageSize = 20;
  const maxPages = 50;
  final matched = <GuideBankQuestion>[];
  var scan = scanOffset;
  var exhausted = false;
  var pages = 0;
  var sawLessonTag = false;
  var sawAnyRow = false;
  while (matched.length < pageSize && !exhausted && pages < maxPages) {
    pages++;
    final res = await fetch({
      'action': 'list',
      'classId': schoolClass,
      'subject': subject,
      'chapter': chapter,
      'offset': scan,
      'limit': pageSize,
    });
    if (res == null || res['found'] != true) {
      // Mid-scan failure: return what matched, keep the scan
      // offset so "আরো দেখুন" retries the same page — never a
      // false "end of list". Before any row matched this is a
      // failure, not an empty lesson: report unavailable.
      if (matched.isEmpty) {
        return GuideFlowPage(
          rows: const [],
          total: null,
          hasMore: false,
          mode: GuideFlowMode.unavailable,
          nextScanOffset: scan,
        );
      }
      return GuideFlowPage(
        rows: matched,
        total: null,
        hasMore: true,
        mode: GuideFlowMode.clientFiltered,
        nextScanOffset: scan,
      );
    }
    final rows = guideFlowRows(res);
    if (rows.isNotEmpty) sawAnyRow = true;
    for (final r in rows) {
      if (r.lesson != null) sawLessonTag = true;
      if (isCreativePatternRow(r) && _lessonMatches(r, lesson)) {
        matched.add(r);
      }
    }
    scan += rows.length;
    final total = (res['total'] as num?)?.toInt();
    if (rows.length < pageSize || (total != null && scan >= total)) {
      exhausted = true;
    }
  }
  if (lesson != null && sawAnyRow && !sawLessonTag && matched.isEmpty) {
    // Rows carry no lesson tag at all: the server cannot filter
    // by lesson, so an empty page would lie. Honest pending.
    return const GuideFlowPage(
      rows: [],
      total: null,
      hasMore: false,
      mode: GuideFlowMode.filterPending,
      nextScanOffset: 0,
    );
  }
  return GuideFlowPage(
    rows: matched,
    total: null,
    hasMore: !exhausted,
    mode: GuideFlowMode.clientFiltered,
    nextScanOffset: scan,
  );
}

/// Positional jump through a creative-pattern scan: the Nth
/// pattern row of the chapter (Edge id order). Counts the same
/// population the pattern page lists, so "সরাসরি উত্তর" N lands
/// on the row the list shows at N.
Future<GuideFlowJump> guideFlowCreativePatternJump({
  required GuideFlowPost fetch,
  required String subject,
  required int schoolClass,
  required int chapter,
  required String? lesson,
  required int position,
}) async {
  const pageSize = 20;
  var scan = 0;
  var seen = 0;
  var sawLessonTag = false;
  var sawAnyRow = false;
  for (var pages = 0; pages < 100; pages++) {
    final res = await fetch({
      'action': 'list',
      'classId': schoolClass,
      'subject': subject,
      'chapter': chapter,
      'offset': scan,
      'limit': pageSize,
    });
    if (res == null || res['found'] != true) {
      return const GuideFlowJump(
        question: null,
        outcome: GuideFlowJumpOutcome.unavailable,
      );
    }
    final rows = guideFlowRows(res);
    if (rows.isNotEmpty) sawAnyRow = true;
    for (final r in rows) {
      if (r.lesson != null) sawLessonTag = true;
      if (!isCreativePatternRow(r) || !_lessonMatches(r, lesson)) continue;
      seen++;
      if (seen == position) {
        return GuideFlowJump(question: r, outcome: GuideFlowJumpOutcome.found);
      }
    }
    scan += rows.length;
    final total = (res['total'] as num?)?.toInt();
    if (rows.length < pageSize || (total != null && scan >= total)) break;
  }
  if (lesson != null && sawAnyRow && !sawLessonTag) {
    return const GuideFlowJump(
      question: null,
      outcome: GuideFlowJumpOutcome.filterPending,
    );
  }
  return const GuideFlowJump(
    question: null,
    outcome: GuideFlowJumpOutcome.notFound,
  );
}
