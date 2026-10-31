// Guide bank data layer: client cache + honest unavailable states.
// Null = unreachable (never demo data). Cache-first, class-keyed.
// After a new import, call invalidateGuideBankCache().
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/guide_bank_model.dart';
import 'app_config.dart';
import 'edge_post.dart';
import 'guide_bank_cache.dart';

class GuideBankService {
  static const _reportsKey = 'guide_reports_outbox';

  /// Cached chapter rows, or null when nothing was ever cached.
  /// Null means "unknown", NOT "empty": callers must show the
  /// unavailable state, never an empty-bank message, for null.
  Future<List<GuideBankQuestion>?> cachedChapter(
      String subject, int chapter,
      {int schoolClass = 6}) async {
    await ensureGuideCacheMigrated();
    final prefs = await SharedPreferences.getInstance();
    final raw =
        prefs.getString(guideChapterKey(schoolClass, subject, chapter));
    if (raw == null || raw.isEmpty) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map>()
          .map((e) => GuideBankQuestion.fromJson(
              e.map((k, v) => MapEntry(k.toString(), v))))
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Stores a chapter list and refreshes the subject index.
  Future<void> cacheChapter(String subject, int chapter,
      List<GuideBankQuestion> questions,
      {int schoolClass = 6}) async {
    await ensureGuideCacheMigrated();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      guideChapterKey(schoolClass, subject, chapter),
      jsonEncode(questions.map((q) => q.toJson()).toList()),
    );
    final index =
        await subjectChapterCounts(subject, schoolClass: schoolClass) ?? {};
    index[chapter] = questions.length;
    await prefs.setString(
      guideIndexKey(schoolClass, subject),
      jsonEncode(index.map((k, v) => MapEntry(k.toString(), v))),
    );
  }

  /// Server chapter list via the guide-bank Edge Function.
  /// Pages (pageSize 20, server-capped) to the reported total;
  /// hard cap 1000 rows. Null = unreachable (unavailable, never
  /// cached). Empty = honest empty (returned, NOT cached, so
  /// later-arriving data is never hidden behind a stale cache).
  Future<List<GuideBankQuestion>?> fetchChapterFromServer(
    String subject,
    int chapter, {
    int schoolClass = 6,
    void Function(int fetched, int total)? onProgress,
  }) async {
    if (AppConfig.guideBankEndpoint.isEmpty) return null;
    const pageSize = 20;
    const maxRows = 1000;
    final all = <GuideBankQuestion>[];
    var page = 1;
    var total = -1;
    while (all.length < maxRows) {
      final res = await edgePost(
        {
          'action': 'list',
          'classId': schoolClass,
          'subject': subject,
          'chapter': chapter,
          'page': page,
          'pageSize': pageSize,
        },
        endpoint: AppConfig.guideBankEndpoint,
      );
      if (res == null || res['found'] != true) return null;
      final rows = res['questions'];
      if (rows is! List) return null;
      total = (res['total'] as num?)?.toInt() ?? all.length + rows.length;
      for (final r in rows.whereType<Map>()) {
        all.add(GuideBankQuestion.fromServerJson(
            r.map((k, v) => MapEntry(k.toString(), v))));
      }
      onProgress?.call(all.length, total);
      if (all.length >= total || rows.length < pageSize) break;
      page += 1;
    }
    if (all.isEmpty) return const [];
    await cacheChapter(subject, chapter, all, schoolClass: schoolClass);
    return all;
  }

  /// Server model-test set metadata (counts only, no rows).
  /// Null = unreachable (unknown, not empty).
  Future<List<GuideModelSetInfo>?> fetchSetsFromServer(
    String subject, {
    int schoolClass = 6,
  }) async {
    if (AppConfig.guideBankEndpoint.isEmpty) return null;
    final res = await edgePost(
      {
        'action': 'sets',
        'classId': schoolClass,
        'subject': subject,
      },
      endpoint: AppConfig.guideBankEndpoint,
    );
    if (res == null || res['found'] != true) return null;
    final sets = res['sets'];
    if (sets is! List) return null;
    return sets
        .whereType<Map>()
        .map((e) => GuideModelSetInfo.fromJson(
            e.map((k, v) => MapEntry(k.toString(), v))))
        .toList();
  }

  /// Server guide-native chapters for a subject: chapter number
  /// -> bank question count. Null = unreachable. This is the
  /// fallback when no textbook chapters exist for the class
  /// (guide-native system, migration 011): the tab and the quiz
  /// pool use these numbers when the textbook list is empty.
  Future<Map<int, int>?> fetchGuideChapters(String subject,
      {int schoolClass = 6}) async {
    if (AppConfig.guideBankEndpoint.isEmpty) return null;
    final res = await edgePost(
      {
        'action': 'guideChapters',
        'classId': schoolClass,
        'subject': subject,
      },
      endpoint: AppConfig.guideBankEndpoint,
    );
    if (res == null || res['found'] != true) return null;
    final list = res['guideChapters'];
    if (list is! List) return null;
    final out = <int, int>{};
    for (final e in list.whereType<Map>()) {
      final n = e['chapter'];
      final t = e['totalCount'];
      if (n is num && t is num) out[n.toInt()] = t.toInt();
    }
    return out;
  }

  /// Chapter number -> cached question count, or null when the
  /// subject has no cached index at all (unknown, not zero).
  Future<Map<int, int>?> subjectChapterCounts(String subject,
      {int schoolClass = 6}) async {
    await ensureGuideCacheMigrated();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(guideIndexKey(schoolClass, subject));
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map;
      final out = <int, int>{};
      map.forEach((k, v) {
        final n = int.tryParse(k.toString());
        if (n != null && v is num) out[n] = v.toInt();
      });
      return out;
    } catch (_) {
      return null;
    }
  }

  /// Cached model-test sets (empty = none cached).
  Future<List<GuideModelSet>> cachedSets(String subject,
      {int schoolClass = 6}) async {
    await ensureGuideCacheMigrated();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(guideSetsKey(schoolClass, subject));
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map>()
          .map((e) => GuideModelSet.fromJson(
              e.map((k, v) => MapEntry(k.toString(), v))))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> cacheSets(String subject, List<GuideModelSet> sets,
      {int schoolClass = 6}) async {
    await ensureGuideCacheMigrated();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      guideSetsKey(schoolClass, subject),
      jsonEncode(sets.map((s) => s.toJson()).toList()),
    );
  }

  /// LOCAL capture only: no server endpoint exists; the UI
  /// must say so plainly, never claim "sent".
  Future<void> submitReportLocal(GuideReport report) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = await pendingReports();
    pending.add(report);
    await prefs.setString(
      _reportsKey,
      jsonEncode(pending.map((r) => r.toJson()).toList()),
    );
  }

  Future<List<GuideReport>> pendingReports() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_reportsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map>()
          .map((e) => GuideReport.fromJson(
              e.map((k, v) => MapEntry(k.toString(), v))))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Paywall gate. Unknown/unverified premium is NEVER premium.
  /// [index] is the position in the FULL chapter list, not the
  /// filtered view. Negative freeLimit (free-open) unlocks all.
  bool isUnlocked({
    required bool isPremium,
    required int index,
    required int freeLimit,
  }) {
    if (isPremium) return true;
    if (freeLimit < 0) return true;
    return index < freeLimit;
  }
}

final guideBankService = GuideBankService();
