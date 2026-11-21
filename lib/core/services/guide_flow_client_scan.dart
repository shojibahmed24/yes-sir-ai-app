// Old-server (v7) client scan for the new search flow. v7 rows
// carry question_type but NO lesson/section tags, so only
// MCQ/short/creative can be matched client-side; a lesson filter
// or a practice_work/textbook_exercise section is honestly
// filterPending (see guide_flow_list_service), never faked.
// Pages are scanned 20 at a time; `total` stays unknown and
// hasMore means "the server list is not exhausted yet".
import '../models/guide_bank_model.dart';
import 'guide_flow_models.dart';
import '../../features/learn/search_flow_types.dart';

List<GuideBankQuestion> guideFlowRows(Map<String, dynamic> res) {
  final q = res['questions'];
  if (q is! List) return const [];
  return q
      .whereType<Map>()
      .map(
        (m) => GuideBankQuestion.fromServerJson(Map<String, dynamic>.from(m)),
      )
      .toList();
}

/// One display page (<= 20 matched rows) from a client scan.
Future<GuideFlowPage> guideFlowClientPage({
  required GuideFlowPost fetch,
  required String subject,
  required int schoolClass,
  required int chapter,
  required SearchFlowType type,
  required String? lesson,
  required int scanOffset,
}) async {
  if (lesson != null) {
    return const GuideFlowPage(
      rows: [],
      total: null,
      hasMore: false,
      mode: GuideFlowMode.filterPending,
      nextScanOffset: 0,
    );
  }
  final qType = searchFlowLegacyQuestionType(type);
  if (qType == null) {
    return const GuideFlowPage(
      rows: [],
      total: null,
      hasMore: false,
      mode: GuideFlowMode.filterPending,
      nextScanOffset: 0,
    );
  }
  const pageSize = 20;
  final matched = <GuideBankQuestion>[];
  var scan = scanOffset;
  var exhausted = false;
  var pages = 0;
  while (matched.length < pageSize && !exhausted && pages < 50) {
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
      // false "end of list". A failure before ANY row matched is
      // not an empty list either: report unavailable so the screen
      // shows a retry instead of "no questions found".
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
    for (final r in rows) {
      if (r.questionType == qType) matched.add(r);
    }
    scan += rows.length;
    final total = (res['total'] as num?)?.toInt();
    if (rows.length < pageSize || (total != null && scan >= total)) {
      exhausted = true;
    }
  }
  return GuideFlowPage(
    rows: matched,
    total: null,
    hasMore: !exhausted,
    mode: GuideFlowMode.clientFiltered,
    nextScanOffset: scan,
  );
}

/// Positional jump through a client scan: the Nth row of the
/// type-filtered list (guide rows have no printed number).
Future<GuideFlowJump> guideFlowClientJump({
  required GuideFlowPost fetch,
  required String subject,
  required int schoolClass,
  required int chapter,
  required SearchFlowType type,
  required String? lesson,
  required int position,
}) async {
  if (lesson != null) {
    return const GuideFlowJump(
      question: null,
      outcome: GuideFlowJumpOutcome.filterPending,
    );
  }
  final qType = searchFlowLegacyQuestionType(type);
  if (qType == null) {
    return const GuideFlowJump(
      question: null,
      outcome: GuideFlowJumpOutcome.filterPending,
    );
  }
  const pageSize = 20;
  var scan = 0;
  var seen = 0;
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
    for (final r in rows) {
      if (r.questionType != qType) continue;
      seen++;
      if (seen == position) {
        return GuideFlowJump(question: r, outcome: GuideFlowJumpOutcome.found);
      }
    }
    scan += rows.length;
    final total = (res['total'] as num?)?.toInt();
    if (rows.length < pageSize || (total != null && scan >= total)) break;
  }
  return const GuideFlowJump(
    question: null,
    outcome: GuideFlowJumpOutcome.notFound,
  );
}

/// D1 (Phase-5) page fallback: the new server echoes a type
/// section but reports total 0 — the chapter may still hold
/// rows of that type with section NULL (class 7/8). Returns
/// the client-scan page, or null when the fallback does not
/// apply (lesson lists keep the server answer — the scan
/// cannot filter by lesson).
Future<GuideFlowPage?> guideFlowTypeFallbackPage({
  required GuideFlowPost fetch,
  required String subject,
  required int schoolClass,
  required int chapter,
  required SearchFlowType type,
  required String? lesson,
  required int? total,
  required String typeSection,
  required int scanOffset,
}) async {
  if (total != 0 || lesson != null || typeSection.isEmpty) return null;
  return guideFlowClientPage(
    fetch: fetch,
    subject: subject,
    schoolClass: schoolClass,
    chapter: chapter,
    type: type,
    lesson: lesson,
    scanOffset: scanOffset,
  );
}

/// D1 (Phase-5) jump fallback: same empty-type case as the
/// page fallback, for positional jumps. Returns null when
/// the fallback does not apply.
Future<GuideFlowJump?> guideFlowTypeFallbackJump({
  required GuideFlowPost fetch,
  required String subject,
  required int schoolClass,
  required int chapter,
  required SearchFlowType type,
  required String? lesson,
  required String typeSection,
  required int position,
}) async {
  if (lesson != null || typeSection.isEmpty) return null;
  return guideFlowClientJump(
    fetch: fetch,
    subject: subject,
    schoolClass: schoolClass,
    chapter: chapter,
    type: type,
    lesson: lesson,
    position: position,
  );
}
