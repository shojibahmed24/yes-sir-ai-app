// Positional jump for the search flow (split out of
// guide_flow_list_service.dart to keep that file under the
// 250-line cap, Phase-5). Guide rows carry NO printed
// question number: no question_number column exists in
// migrations 008/011/013 and the list payload has no number
// field — so "number N" means the Nth row of the filtered
// list in Edge id order.
import 'app_config.dart';
import 'edge_post.dart';
import 'guide_flow_client_scan.dart';
import 'guide_flow_creative_scan.dart';
import 'guide_flow_models.dart';
import 'guide_flow_section_scan.dart';
import '../../features/learn/search_flow_types.dart';

class GuideFlowJumpService {
  GuideFlowJumpService({GuideFlowPost? post})
      : _post = post ?? edgePost,
        _customPost = post != null;
  final GuideFlowPost _post;
  final bool _customPost;

  Future<Map<String, dynamic>?> _list(Map<String, dynamic> body) async {
    if (!_customPost && AppConfig.guideBankEndpoint.isEmpty) return null;
    return _post(body, endpoint: AppConfig.guideBankEndpoint);
  }

  /// Positional jump: returns the row, or notFound when N is
  /// beyond the list.
  Future<GuideFlowJump> jumpToPosition({
    required String subject,
    required int schoolClass,
    required int chapter,
    required SearchFlowType? type,
    required String? lesson,
    required int position,
    String? section,
  }) async {
    if (section != null) {
      return guideFlowSectionJump(
          fetch: (body, {endpoint}) => _list(body),
          subject: subject,
          schoolClass: schoolClass,
          chapter: chapter,
          section: section,
          lesson: lesson,
          position: position);
    }
    if (type == null) {
      return const GuideFlowJump(
          question: null, outcome: GuideFlowJumpOutcome.unavailable);
    }
    if (type == SearchFlowType.creative) {
      // User rule (2026-11-08): the jump counts the same
      // pattern population the creative list shows (any subject,
      // any creative-family section), not just section
      // 'creative' rows — otherwise "সরাসরি উত্তর" N lands on
      // a different row than the list shows at N.
      return guideFlowCreativePatternJump(
          fetch: (body, {endpoint}) => _list(body),
          subject: subject,
          schoolClass: schoolClass,
          chapter: chapter,
          lesson: lesson,
          position: position);
    }
    final typeSection = searchFlowGuideSection(type);
    final res = await _list({
      'action': 'list',
      'classId': schoolClass,
      'subject': subject,
      'chapter': chapter,
      'lesson': lesson,
      'section': typeSection,
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
    final filtered = lesson != null || typeSection.isNotEmpty;
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
      // D1 (Phase-5): the server section filter misses
      // NULL-section rows — try the client scan.
      final fallback = await guideFlowTypeFallbackJump(
          fetch: (body, {endpoint}) => _list(body),
          subject: subject, schoolClass: schoolClass,
          chapter: chapter, type: type, lesson: lesson,
          typeSection: typeSection, position: position);
      if (fallback != null) return fallback;
      return const GuideFlowJump(
          question: null, outcome: GuideFlowJumpOutcome.notFound);
    }
    return GuideFlowJump(
        question: rows.first, outcome: GuideFlowJumpOutcome.found);
  }
  /// Chapterless positional jump (Paper-II sections): the Nth
  /// row of the chapterless list in Edge id order. Uses the
  /// same server-side section filter the chapterless list
  /// screen uses — Paper-II values are exact
  /// LIST_SECTION_VALUES members, so the filter accepts them
  /// verbatim. No chapter is ever sent: the Edge chapter
  /// scope filters `set_id IS NULL` rows by chapter, so a
  /// chapter here would return the wrong (empty) list.
  Future<GuideFlowJump> jumpToChapterlessPosition({
    required String subject,
    required int schoolClass,
    required String section,
    String? lesson,
    required int position,
  }) async {
    final res = await _list({
      'action': 'list',
      'classId': schoolClass,
      'subject': subject,
      'chapterless': true,
      'section': section,
      if (lesson != null) 'lesson': lesson,
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
    final rows = guideFlowRows(res);
    if (rows.isEmpty) {
      return const GuideFlowJump(
          question: null, outcome: GuideFlowJumpOutcome.notFound);
    }
    return GuideFlowJump(
        question: rows.first, outcome: GuideFlowJumpOutcome.found);
  }
}

final guideFlowJumpService = GuideFlowJumpService();
