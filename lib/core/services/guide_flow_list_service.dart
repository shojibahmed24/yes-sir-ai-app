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
import 'guide_flow_creative_scan.dart';
import 'guide_flow_inflight.dart';
import 'guide_flow_models.dart';
import 'guide_flow_prefetch.dart';
import 'guide_flow_section_scan.dart';
import '../../features/learn/search_flow_types.dart';

export 'guide_flow_models.dart';

class GuideFlowListService {
  GuideFlowListService({GuideFlowPost? post})
    : _post = post ?? edgePost,
      _customPost = post != null;
  final GuideFlowPost _post;
  final bool _customPost;
  final GuideFlowPageCache _pageCache = GuideFlowPageCache();
  final _inFlight = GuideFlowInflight();

  /// First paint size (B2): 10 rows render fast; the next page is
  /// fetched in the background while the student reads.
  static const pageSize = 10;

  Future<Map<String, dynamic>?> _list(Map<String, dynamic> body) async {
    if (!_customPost && AppConfig.guideBankEndpoint.isEmpty) return null;
    return _post(body, endpoint: AppConfig.guideBankEndpoint);
  }

  /// One display page (<= 20 rows) for a type (+ lesson) selection.
  /// Prefetched pages (Phase 5) are served from the one-page
  /// cache; identical concurrent requests share one future.
  Future<GuideFlowPage> fetchPage({
    required String subject,
    required int schoolClass,
    required int chapter,
    required SearchFlowType type,
    String? lesson,
    String? section,
    int offset = 0,
    int scanOffset = 0,
  }) async {
    final identity = [
      subject,
      schoolClass,
      chapter,
      type.name,
      lesson ?? '',
      section ?? '',
    ].join('|');
    if (offset > 0) {
      final cached = _pageCache.take('$identity@$offset');
      if (cached != null) {
        prefetchGuideFlowPage(
          fetch: (body, {endpoint}) => _list(body),
          cache: _pageCache,
          identity: identity,
          body: cached.nextBody,
          pageSize: pageSize,
        );
        return cached.page;
      }
    }
    final key = '$identity@$offset@$scanOffset';
    final existing = _inFlight.existing(key);
    if (existing != null) return existing;
    // A13: first page per list is reused for 3 minutes. Custom-post
    // instances (tests/injection) skip the cache so a fake failure can
    // never be masked by an earlier page.
    if (!_customPost && offset == 0) {
      final hit = _firstPage[identity];
      if (hit != null &&
          DateTime.now().difference(hit.$1) < const Duration(minutes: 3)) {
        return hit.$2;
      }
    }
    final page = await _inFlight.track(
      key,
      _fetchPageInner(
        identity: identity,
        subject: subject,
        schoolClass: schoolClass,
        chapter: chapter,
        type: type,
        lesson: lesson,
        section: section,
        offset: offset,
        scanOffset: scanOffset,
      ),
    );
    if (!_customPost && offset == 0) {
      _firstPage[identity] = (DateTime.now(), page);
    }
    return page;
  }

  final Map<String, (DateTime, GuideFlowPage)> _firstPage = {};

  Future<GuideFlowPage> _fetchPageInner({
    required String identity,
    required String subject,
    required int schoolClass,
    required int chapter,
    required SearchFlowType type,
    String? lesson,
    String? section,
    int offset = 0,
    int scanOffset = 0,
  }) async {
    if (section != null) {
      // Phase 2: the server filters these sections now, so try
      // the direct page first; the client scan is the fallback
      // for old servers (no section echo) and unreachable ones.
      final direct = await fetchDirectSectionPage(
        fetch: (body, {endpoint}) => _list(body),
        subject: subject,
        schoolClass: schoolClass,
        chapter: chapter,
        section: section,
        lesson: lesson,
        offset: offset,
        pageSize: pageSize,
      );
      if (direct != null) return direct;
      return guideFlowSectionPage(
        fetch: (body, {endpoint}) => _list(body),
        subject: subject,
        schoolClass: schoolClass,
        chapter: chapter,
        section: section,
        lesson: lesson,
        scanOffset: scanOffset,
      );
    }
    final typeSection = searchFlowGuideSection(type);
    if (type == SearchFlowType.creative) {
      // User rule (2026-11-08): the creative form follows the
      // pattern (stimulus + 4 parts + marks 1-4) in ANY subject —
      // one server section ('creative') misses model/board/
      // chapter-model creative rows, so the creative type is
      // served by the pattern scan instead of the section page.
      // Paging continues via scanOffset (the screen tracks
      // nextScanOffset); no server prefetch applies here.
      return guideFlowCreativePatternPage(
        fetch: (body, {endpoint}) => _list(body),
        subject: subject,
        schoolClass: schoolClass,
        chapter: chapter,
        lesson: lesson,
        scanOffset: scanOffset,
      );
    }
    // Phase 3: slim rows for list screens, except creative
    // (group opens need the full stimulus text in the rows).
    final body = <String, dynamic>{
      'action': 'list',
      'classId': schoolClass,
      'subject': subject,
      'chapter': chapter,
      'lesson': lesson,
      'section': typeSection,
      'offset': offset,
      'limit': pageSize,
      'slim': type != SearchFlowType.creative,
    };
    final res = await _list(body);
    if (res == null) {
      return const GuideFlowPage(
        rows: [],
        total: null,
        hasMore: false,
        mode: GuideFlowMode.unavailable,
        nextScanOffset: 0,
      );
    }
    if (res['found'] != true) {
      return GuideFlowPage(
        rows: [],
        total: null,
        hasMore: false,
        mode: res['reason'] == 'pilot-columns-missing'
            ? GuideFlowMode.filterPending
            : GuideFlowMode.unavailable,
        nextScanOffset: 0,
      );
    }
    final filtered = lesson != null || typeSection.isNotEmpty;
    if (filtered &&
        (!res.containsKey('lesson') || !res.containsKey('section'))) {
      return guideFlowClientPage(
        fetch: (body, {endpoint}) => _list(body),
        subject: subject,
        schoolClass: schoolClass,
        chapter: chapter,
        type: type,
        lesson: lesson,
        scanOffset: scanOffset,
      );
    }
    final rows = guideFlowRows(res);
    final total = (res['total'] as num?)?.toInt();
    final hasMore = total != null
        ? offset + rows.length < total
        : rows.length >= pageSize;
    final page = GuideFlowPage(
      rows: rows,
      total: total,
      hasMore: hasMore,
      mode: GuideFlowMode.serverFiltered,
      nextScanOffset: 0,
    );
    // D1 (Phase-5): server total 0 can mean NULL-section
    // rows (class 7/8), not an empty chapter — fall back to
    // the client scan (see guide_flow_client_scan).
    final fallback = await guideFlowTypeFallbackPage(
      fetch: (body, {endpoint}) => _list(body),
      subject: subject,
      schoolClass: schoolClass,
      chapter: chapter,
      type: type,
      lesson: lesson,
      total: total,
      typeSection: typeSection,
      scanOffset: scanOffset,
    );
    if (fallback != null) return fallback;
    if (hasMore) {
      prefetchGuideFlowPage(
        fetch: (b, {endpoint}) => _list(b),
        cache: _pageCache,
        identity: identity,
        body: {...body, 'offset': offset + rows.length},
        pageSize: pageSize,
      );
    }
    return page;
  }
}

final guideFlowListService = GuideFlowListService();
