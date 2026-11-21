// State + resolution for the search screen: the widget only
// renders; this controller owns picks and chapter loading.
// jump() lives in search_flow_jump.dart (extension, same
// pattern as SearchFlowListQuery) to keep this file under
// the 250-line cap.
import 'package:flutter/material.dart';

import '../../core/models/backend_models.dart';
import '../../core/services/books_service.dart';
import '../../core/services/picker_cache_service.dart';
import '../../core/services/profile_service.dart';
import 'search_flow_bangla_papers.dart';
import 'search_flow_chapter_fetch.dart';
import 'search_flow_list_query.dart';
import 'search_flow_types.dart';

class SearchFlowController {
  SearchFlowController({
    required this.initialSubjectId,
    required this.initialSchoolClass,
    required this.onChanged,
    this.initialSource,
  });
  final String initialSubjectId;
  final int? initialSchoolClass;

  /// 'guide' from a subject's Start button: opens the guide picker
  /// directly instead of the textbook source. Null = old behaviour
  /// (guide only when the subject's book is locked).
  final String? initialSource;
  final VoidCallback onChanged;

  int schoolClass = 6;
  bool bangla = true;
  List<SubjectInfo> subjects = [];
  String subjectId = 'math';
  String source = 'textbook';
  List<(int, String)> chapters = [];
  bool chaptersLoading = true;
  int _chaptersGeneration = 0;
  int? chapter;
  String? lesson;
  SearchFlowType? type;

  /// Guide question totals per chapter (guide source only), so the
  /// picker can show "৩ অধ্যায় · ৫৭৬ প্রশ্ন" instead of a bare
  /// number. Empty = unknown (textbook source, or restored from the
  /// tuple cache, which stores titles only).
  Map<int, int> chapterTotals = const {};

  /// English guide section pick (Paper-I only). Null = none
  /// picked; reset on subject/source change, never stale.
  String? section;

  /// 1st-Paper section pick (goddo/poddo/uponnas); null = none
  /// picked, so the lesson picker shows all 18 lessons.
  String? banglaSection;
  String get effectiveSubjectId => banglaPaperSubject(subjectId);
  int get effectiveClass => banglaPaperClass(subjectId, source, schoolClass);
  final numberCtrl = TextEditingController();
  bool jumping = false;

  void dispose() => numberCtrl.dispose();

  void _notify() => onChanged();

  /// English guide section mode: the section picker replaces
  /// the type dropdown (Math's 5-type dropdown is untouched).
  bool get englishGuideSectionMode =>
      source == 'guide' && subjectId == 'english';

  Map<String, String> get lessons => source == 'guide'
      ? lessonsForChapter(subjectId, schoolClass, chapter ?? 0)
      : const <String, String>{};

  Future<void> init(bool bn) async {
    bangla = bn;
    final saved = await profileService.loadSchoolClass().catchError(
      (_) => null,
    );
    final cls = initialSchoolClass ?? saved ?? 6;
    subjects = splitBanglaSubjects(
      await booksService
          .subjectsAsync(cls, bn)
          .catchError((_) => <SubjectInfo>[]),
    );
    schoolClass = cls;
    final initial = normalizeBanglaSubject(initialSubjectId);
    subjectId = subjects.any((s) => s.id == initial)
        ? initial
        : (subjects.isNotEmpty ? subjects.first.id : 'math');
    applySubject(subjectId);
    final wanted = initialSource;
    if (wanted != null && wanted != source) changeSource(wanted);
  }

  void applySubject(String id) {
    subjectId = id;
    source = (subject?.locked ?? false) ? 'guide' : 'textbook';
    chapter = null;
    lesson = null;
    section = null;
    banglaSection = null;
    _notify();
    loadChapters();
  }

  Future<void> changeClass(int cls, bool bn) async {
    bangla = bn;
    schoolClass = cls;
    subjects = splitBanglaSubjects(
      await booksService
          .subjectsAsync(cls, bn)
          .catchError((_) => <SubjectInfo>[]),
    );
    final current = normalizeBanglaSubject(subjectId);
    applySubject(
      subjects.any((x) => x.id == current)
          ? current
          : (subjects.isNotEmpty ? subjects.first.id : 'math'),
    );
  }

  void changeSource(String value) {
    source = value;
    chapter = null;
    lesson = null;
    section = null;
    banglaSection = null;
    _notify();
    loadChapters();
  }

  /// Cache-first (stale-while-revalidate): saved chapters
  /// render instantly, then a fresh fetch overwrites them in
  /// the background. A newer load supersedes an older one
  /// (generation guard), so rapid subject changes never land
  /// a stale list. Unreachable + no cache keeps the old
  /// behavior: verified titles for textbook, empty for guide.
  /// Unreachable + cache keeps the cached chapters.
  Future<void> loadChapters() async {
    final gen = ++_chaptersGeneration;
    final bn = bangla;
    final subj = effectiveSubjectId;
    final cls = effectiveClass;
    final src = source;
    final kind = src == 'guide'
        ? pickerCacheKindGuideChapters
        : pickerCacheKindTextbookChapters;
    final key = pickerCacheKey(cls, subj, bn ? 'bn' : 'en', kind);
    final totalsKey = pickerCacheKey(
      cls,
      subj,
      bn ? 'bn' : 'en',
      'guide-chapter-totals',
    );
    chaptersLoading = true;
    _notify();
    var showedCache = false;
    if (src == 'guide') {
      final cachedTotals = decodeChapterTotals(
        await pickerCacheService.read(totalsKey),
      );
      if (gen == _chaptersGeneration && cachedTotals != null) {
        chapterTotals = cachedTotals;
      }
    } else {
      chapterTotals = const {};
    }
    final cached = await pickerCacheService.read(key);
    if (gen == _chaptersGeneration && cached != null) {
      final decoded = decodeChapterTuples(cached);
      if (decoded != null) {
        chapters = decoded;
        chaptersLoading = false;
        showedCache = true;
        _notify();
      }
    }
    final freshTotals = <int, int>{};
    final out = await pickerCacheService
        .dedupe(
          'fetch:$key',
          () => fetchSearchFlowChapterTuples(
            source: src,
            subject: subj,
            schoolClass: cls,
            bangla: bn,
            totalsOut: freshTotals,
          ),
        )
        .catchError((_) => null);
    if (gen != _chaptersGeneration) return;
    if (freshTotals.isNotEmpty) {
      chapterTotals = freshTotals;
      await pickerCacheService.write(
        totalsKey,
        encodeChapterTotals(freshTotals),
      );
    }
    if (out == null) {
      if (showedCache) {
        chaptersLoading = false;
        _notify();
        return;
      }
      chapters = src == 'guide' ? [] : searchFlowChapterFallback(subj, cls);
    } else {
      chapters = out;
      await pickerCacheService.write(key, encodeChapterTuples(out));
    }
    chaptersLoading = false;
    _notify();
  }
}
