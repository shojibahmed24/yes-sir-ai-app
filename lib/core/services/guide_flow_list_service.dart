// Paged guide list for the new search flow (Step 5).
// Server-first, honestly degraded on the OLD live server (v7):
//
// - NEW server (step-1 params deployed): the response ECHOES the
//   requested lesson/section. Echo match => serverFiltered page:
//   exact `total`, hasMore = offset + shown < total.
// - Filtered request on a pre-migration server => found:false
//   reason 'pilot-columns-missing' => filterPending: the UI shows
//   "not live yet", never unfiltered rows disguised as filtered.
// - OLD server (v7, ignores lesson/section, echoes NEITHER key):
//   echo absence proves the filter was ignored, so the request
//   falls through to the client scan (guide_flow_client_scan):
//   MCQ/short/creative match on v7 question_type; lesson filters
//   and practice_work/textbook_exercise stay filterPending.
//   This fallback is TEMPORARY: after deploy, echo match makes
//   every request serverFiltered.
// - Null / non-200 / bad body => unavailable (never demo rows).
// Quiz sourcing is untouched: guide_quiz_service reads
// guide_bank_service, never this file.
import 'app_config.dart';
import 'edge_post.dart';
import 'guide_flow_client_scan.dart';
import 'guide_flow_models.dart';
import '../../features/learn/search_flow_types.dart';

export 'guide_flow_models.dart';

class GuideFlowListService {
  GuideFlowListService({GuideFlowPost? post})
      : _post = post ?? edgePost,
        _customPost = post != null;
  final GuideFlowPost _post;
  final bool _customPost;

  static const pageSize = 20;

  Future<Map<String, dynamic>?> _list(Map<String, dynamic> body) async {
    if (!_customPost && AppConfig.guideBankEndpoint.isEmpty) return null;
    return _post(body, endpoint: AppConfig.guideBankEndpoint);
  }

  /// One display page (<= 20 rows) for a type (+ lesson) selection.
  /// [scanOffset] is meaningful only for clientFiltered resumption;
  /// serverFiltered paging uses [offset] directly.
  Future<GuideFlowPage> fetchPage({
    required String subject,
    required int schoolClass,
    required int chapter,
    required SearchFlowType type,
    String? lesson,
    int offset = 0,
    int scanOffset = 0,
  }) async {
    final section = searchFlowGuideSection(type);
    final res = await _list({
      'action': 'list',
      'classId': schoolClass,
      'subject': subject,
      'chapter': chapter,
      'lesson': lesson,
      'section': section,
      'offset': offset,
      'limit': pageSize,
    });
    if (res == null) {
      return const GuideFlowPage(rows: [], total: null, hasMore: false,
          mode: GuideFlowMode.unavailable, nextScanOffset: 0);
    }
    if (res['found'] != true) {
      return GuideFlowPage(
          rows: [], total: null, hasMore: false,
          mode: res['reason'] == 'pilot-columns-missing'
              ? GuideFlowMode.filterPending
              : GuideFlowMode.unavailable,
          nextScanOffset: 0);
    }
    final filtered = lesson != null || section.isNotEmpty;
    if (filtered &&
        (!res.containsKey('lesson') || !res.containsKey('section'))) {
      return guideFlowClientPage(
          fetch: (body, {endpoint}) => _list(body),
          subject: subject, schoolClass: schoolClass,
          chapter: chapter, type: type, lesson: lesson,
          scanOffset: scanOffset);
    }
    final rows = guideFlowRows(res);
    final total = (res['total'] as num?)?.toInt();
    final hasMore =
        total != null ? offset + rows.length < total : rows.length >= pageSize;
    return GuideFlowPage(rows: rows, total: total, hasMore: hasMore,
        mode: GuideFlowMode.serverFiltered, nextScanOffset: 0);
  }

  /// Positional jump (guide rows carry NO printed question number:
  /// no question_number column exists in migrations 008/011/013
  /// and the list payload has no number field — so "number N"
  /// means the Nth row of the filtered list in Edge id order).
  /// Returns the row, or notFound when N is beyond the list.
  Future<GuideFlowJump> jumpToPosition({
    required String subject,
    required int schoolClass,
    required int chapter,
    required SearchFlowType type,
    required String? lesson,
    required int position,
  }) async {
    final section = searchFlowGuideSection(type);
    final res = await _list({
      'action': 'list',
      'classId': schoolClass,
      'subject': subject,
      'chapter': chapter,
      'lesson': lesson,
      'section': section,
      'offset': position - 1,
      'limit': 1,
    });
    if (res == null) {
      return const GuideFlowJump(
          question: null, outcome: GuideFlowJumpOutcome.unavailable);
    }
    if (res['found'] != true) {
      return GuideFlowJump(
          question: null,
          outcome: res['reason'] == 'pilot-columns-missing'
              ? GuideFlowJumpOutcome.filterPending
              : GuideFlowJumpOutcome.unavailable);
    }
    final filtered = lesson != null || section.isNotEmpty;
    if (filtered &&
        (!res.containsKey('lesson') || !res.containsKey('section'))) {
      return guideFlowClientJump(
          fetch: (body, {endpoint}) => _list(body),
          subject: subject, schoolClass: schoolClass,
          chapter: chapter, type: type, lesson: lesson,
          position: position);
    }
    final rows = guideFlowRows(res);
    if (rows.isEmpty) {
      return const GuideFlowJump(
          question: null, outcome: GuideFlowJumpOutcome.notFound);
    }
    return GuideFlowJump(
        question: rows.first, outcome: GuideFlowJumpOutcome.found);
  }
}

final guideFlowListService = GuideFlowListService();
