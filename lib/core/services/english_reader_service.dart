// English reader data assembly (redesign 2026-11-03).
// Fetches rows through the existing set/bank scan, then shapes
// them with the pure rules in english_redesign.dart. No rows
// are invented: a missing fetch yields null (unavailable),
// a missing passage yields a null passage (honest note).
//
// QUICK-LOAD (2026-11-21): poem/story aggregation scans 57 sets +
// the chapterless bank on a cold session. The result is now cached
// on disk and served stale-while-revalidate: a cached scan opens
// instantly and a background refresh rewrites the file for the next
// open. Empty/failed scans are never cached.
import 'dart:async';

import '../data/english_reader_shape.dart';
import '../data/english_redesign.dart';
import '../data/english_redesign_lessons.dart';
import '../models/guide_bank_model.dart';
import 'english_set_scan.dart';
import 'guide_bank_disk_cache.dart';

/// Reader kinds. Writing entries keep the old list screen and
/// never reach this service.
enum EnglishReaderKind { model, special, practice, poem, story, bucket }

/// What the reader screen needs to open one collection.
class EnglishReaderRequest {
  const EnglishReaderRequest({
    required this.kind,
    required this.schoolClass,
    this.setId,
    this.lesson,
    this.stimulusRef,
    this.workName,
  });
  final EnglishReaderKind kind;
  final int schoolClass;
  final String? setId;
  final String? lesson;
  final String? stimulusRef;
  final String? workName;
}

/// Assembled reader content: passage parts + question groups.
class EnglishReaderData {
  const EnglishReaderData({
    required this.parts,
    required this.groups,
    required this.totalQuestions,
  });
  final List<String> parts; // empty = passage unavailable
  final List<EnglishReaderGroup> groups;
  final int totalQuestions;
}

class EnglishReaderService {
  EnglishReaderService({EnglishSetScanService? scan, GuideBankDiskCache? cache})
    : _scan = scan ?? EnglishSetScanService(),
      _cache = cache ?? GuideBankDiskCache();
  final EnglishSetScanService _scan;
  final GuideBankDiskCache _cache;

  /// Disk cache file for the poem/story aggregation of one class.
  static String _scanCacheFile(int schoolClass) =>
      'english_all_rows_v1_$schoolClass';

  /// All set rows + bank rows for poem/story aggregation.
  /// Null when any fetch fails (fail-closed, never partial).
  ///
  /// Stale-while-revalidate: a cached scan is returned immediately
  /// (the screen opens instantly) and refreshed in the background for
  /// the next open. No cache means one live scan, then it is stored.
  Future<List<GuideBankQuestion>?> _allRows(int schoolClass) async {
    final file = _scanCacheFile(schoolClass);
    List<Map<String, dynamic>>? cached;
    try {
      // Bounded: a platform without file storage (tests) must never
      // hang the open on an unanswered method channel.
      cached = await _cache
          .readRows(file)
          .timeout(const Duration(milliseconds: 800));
    } catch (_) {
      cached = null; // no usable cache (e.g. platform without files)
    }
    if (cached != null && cached.isNotEmpty) {
      // Refresh for the next open; never block this one on it.
      unawaited(_refreshScanCache(file, schoolClass));
      return cached.map(GuideBankQuestion.fromJson).toList();
    }
    final fresh = await _fetchAllRows(schoolClass);
    if (fresh == null) return null;
    if (fresh.isNotEmpty) {
      // Fire-and-forget: no timer, so a test teardown never sees a
      // pending timeout; a failed write simply leaves no cache.
      unawaited(
        _cache
            .writeRows(file, [for (final q in fresh) q.toJson()])
            .catchError((_) => false),
      );
    }
    return fresh;
  }

  Future<void> _refreshScanCache(String file, int schoolClass) async {
    try {
      final fresh = await _fetchAllRows(schoolClass);
      if (fresh == null || fresh.isEmpty) return;
      await _cache.writeRows(file, [for (final q in fresh) q.toJson()]);
    } catch (_) {
      // A failed background refresh keeps the existing cache.
    }
  }

  Future<List<GuideBankQuestion>?> _fetchAllRows(int schoolClass) async {
    final sets = await _scan.fetchSets(schoolClass: schoolClass);
    if (sets == null) return null;
    final all = <GuideBankQuestion>[];
    const batchSize = 8;
    for (var i = 0; i < sets.length; i += batchSize) {
      final end = (i + batchSize < sets.length) ? i + batchSize : sets.length;
      final fetched = await Future.wait(
        sets
            .sublist(i, end)
            .map(
              (s) => _scan.fetchAllSetRows(
                schoolClass: schoolClass,
                setId: s.setId,
              ),
            ),
      );
      for (final rows in fetched) {
        if (rows == null) return null;
        all.addAll(rows);
      }
    }
    final bank = await _scan.fetchBankRows(schoolClass: schoolClass);
    if (bank == null) return null;
    all.addAll(bank);
    return all;
  }

  Future<EnglishReaderData?> load(EnglishReaderRequest req) async {
    final kind = req.kind.name;
    late final List<GuideBankQuestion> rows;
    switch (req.kind) {
      case EnglishReaderKind.model:
      case EnglishReaderKind.special:
        final setRows = await _scan.fetchAllSetRows(
          schoolClass: req.schoolClass,
          setId: req.setId!,
        );
        if (setRows == null) return null;
        // Passage-based sections only: poem/story/writing never
        // appear inside a test view (plan §4).
        rows = setRows
            .where((r) => englishPassageBasedSections.contains(r.section))
            .toList();
      case EnglishReaderKind.practice:
        final bank = await _scan.fetchBankRows(schoolClass: req.schoolClass);
        if (bank == null) return null;
        rows = bank
            .where(
              (r) => r.lesson == req.lesson && r.stimulusRef == req.stimulusRef,
            )
            .toList();
      case EnglishReaderKind.poem:
        final all = await _allRows(req.schoolClass);
        if (all == null) return null;
        rows = all
            .where(
              (r) =>
                  r.section == 'poem' &&
                  poemNameForRef(r.stimulusRef) == req.workName,
            )
            .toList();
      case EnglishReaderKind.story:
        final all = await _allRows(req.schoolClass);
        if (all == null) return null;
        rows = all
            .where(
              (r) =>
                  r.section == 'story' &&
                  storyNameForRef(r.stimulusRef) == req.workName,
            )
            .toList();
      case EnglishReaderKind.bucket:
        // Unnamed poem/story sets only: never a titled row, so
        // no row appears in both a title entry and the bucket.
        if (req.setId != null) {
          final setRows = await _scan.fetchAllSetRows(
            schoolClass: req.schoolClass,
            setId: req.setId!,
          );
          if (setRows == null) return null;
          rows = setRows
              .where((r) => isBucketPoemStoryRow(r.section, r.stimulusRef))
              .toList();
        } else {
          final bank = await _scan.fetchBankRows(schoolClass: req.schoolClass);
          if (bank == null) return null;
          final lesson = req.lesson;
          rows = bank
              .where(
                (r) =>
                    isBucketPoemStoryRow(r.section, r.stimulusRef) &&
                    (lesson == null
                        ? (r.lesson == null || r.lesson!.isEmpty)
                        : r.lesson == lesson),
              )
              .toList();
        }
    }
    final passage = readerPassage(rows);
    var groups = buildReaderGroups(rows, kind);
    if (req.kind == EnglishReaderKind.model ||
        req.kind == EnglishReaderKind.special) {
      // Tests follow the guide's printed Q order (Q1→Q7), not
      // the server's row order (which can list matching and
      // rearranging before summary and table).
      groups = groups.toList()
        ..sort((a, b) {
          final ia = englishPassageBasedSections.indexOf(a.section ?? '');
          final ib = englishPassageBasedSections.indexOf(b.section ?? '');
          return ia.compareTo(ib);
        });
    }
    if (req.kind == EnglishReaderKind.bucket) {
      // Q8 poem before Q9 story, regardless of row order.
      const order = ['poem', 'story'];
      groups = groups.toList()
        ..sort(
          (a, b) => order
              .indexOf(a.section ?? '')
              .compareTo(order.indexOf(b.section ?? '')),
        );
    }
    return EnglishReaderData(
      parts: passage == null ? const [] : splitPassageParts(passage),
      groups: groups,
      totalQuestions: rows.length,
    );
  }

  /// Bucket lesson items from all rows (set rows + bank rows).
  /// Null when any fetch fails (fail-closed, never partial).
  Future<List<EnglishRedesignLesson>?> bucketLessonItems(
    int schoolClass,
  ) async {
    final all = await _allRows(schoolClass);
    if (all == null) return null;
    return bucketLessonItemsFromRows(all);
  }
}
