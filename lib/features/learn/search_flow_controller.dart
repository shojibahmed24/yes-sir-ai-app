// State + resolution for the new search screen (Step 3). The
// screen widget only renders; this controller owns class/subject
// /source/chapter/lesson/type state, chapter loading, and the
// direct-jump resolution. Navigation stays in the screen: jump()
// returns a SearchFlowJumpResult, never a BuildContext.
import 'package:flutter/material.dart';

import '../../core/models/backend_models.dart';
import '../../core/services/books_service.dart';
import '../../core/services/guide_bank_service.dart';
import '../../core/services/guide_flow_list_service.dart';
import '../../core/services/profile_service.dart';
import '../../core/services/textbook_chapter_service.dart';
import 'lesson_selection.dart';
import 'search_flow_types.dart';

class SearchFlowController {
  SearchFlowController({
    required this.initialSubjectId,
    required this.initialSchoolClass,
    required this.onChanged,
  });
  final String initialSubjectId;
  final int? initialSchoolClass;
  final VoidCallback onChanged;

  int schoolClass = 6;
  bool bangla = true;
  List<SubjectInfo> subjects = [];
  String subjectId = 'math';
  String source = 'textbook';
  List<(int, String)> chapters = [];
  bool chaptersLoading = true;
  int? chapter;
  String? lesson;
  SearchFlowType? type;
  final numberCtrl = TextEditingController();
  bool jumping = false;

  void dispose() => numberCtrl.dispose();

  void _notify() => onChanged();

  SubjectInfo? get subject {
    for (final s in subjects) {
      if (s.id == subjectId) return s;
    }
    return null;
  }

  Map<String, String> get lessons => source == 'guide'
      ? lessonsForChapter(subjectId, schoolClass, chapter ?? 0)
      : const <String, String>{};

  Future<void> init(bool bn) async {
    bangla = bn;
    final saved =
        await profileService.loadSchoolClass().catchError((_) => null);
    final cls = initialSchoolClass ?? saved ?? 6;
    final list = await booksService.subjectsAsync(cls, bn)
        .catchError((_) => <SubjectInfo>[]);
    schoolClass = cls;
    subjects = list;
    subjectId = list.any((s) => s.id == initialSubjectId)
        ? initialSubjectId
        : (list.isNotEmpty ? list.first.id : 'math');
    applySubject(subjectId);
  }

  void applySubject(String id) {
    subjectId = id;
    source = (subject?.locked ?? false) ? 'guide' : 'textbook';
    chapter = null;
    lesson = null;
    _notify();
    loadChapters();
  }

  Future<void> changeClass(int cls, bool bn) async {
    bangla = bn;
    schoolClass = cls;
    subjects = await booksService.subjectsAsync(cls, bn)
        .catchError((_) => <SubjectInfo>[]);
    applySubject(subjects.any((x) => x.id == subjectId)
        ? subjectId
        : (subjects.isNotEmpty ? subjects.first.id : 'math'));
  }

  void changeSource(String value) {
    source = value;
    chapter = null;
    lesson = null;
    _notify();
    loadChapters();
  }

  Future<void> loadChapters() async {
    chaptersLoading = true;
    _notify();
    final bn = bangla;
    final subj = subjectId;
    final cls = schoolClass;
    List<(int, String)> out = [];
    if (source == 'guide') {
      final map = await guideBankService
          .fetchGuideChapters(subj, schoolClass: cls)
          .catchError((_) => null);
      final numbers = (map?.keys.toList() ?? [])..sort();
      out = [
        for (final n in numbers)
          (n, verifiedChapterTitle(subj, cls, n) ?? ''),
      ];
    } else {
      final db = await booksService
          .chaptersForSubjectAsync(cls, subj, bn)
          .catchError((_) => null);
      if (db != null && db.isNotEmpty) {
        out = [
          for (final c in db) (c.number, c.title(bn)),
        ];
      } else {
        out = [
          for (var n = 1; n <= 17; n++)
            if (verifiedChapterTitle(subj, cls, n) != null)
              (n, verifiedChapterTitle(subj, cls, n)!),
        ];
      }
    }
    chapters = out;
    chaptersLoading = false;
    _notify();
  }

  /// Query string for the list route (no navigation here).
  String listQuery({int? questionNumber}) {
    final q = <String, String>{
      'subject': subjectId,
      'class': '$schoolClass',
      'source': source,
      'chapter': '${chapter ?? 0}',
      'type': type!.name,
      if (lesson != null) 'lesson': lesson!,
      if (questionNumber != null) 'questionNumber': '$questionNumber',
    };
    return q.entries.map((e) => '${e.key}=${e.value}').join('&');
  }

  /// Direct jump, scoped to type + lesson + chapter + source.
  /// Guide: positional (no printed number exists — see
  /// guide_flow_list_service). Textbook: the existing chapter
  /// list path, matched on printed problem number; one hit opens
  /// the lesson, several hits open the matched-only list.
  Future<SearchFlowJumpResult> jump(Map<String, String> s, bool bn) async {
    if (chapter == null || type == null) {
      return const SearchFlowJumpResult(kind: SearchFlowJumpKind.message);
    }
    jumping = true;
    _notify();
    final number = normalizeQuestionNumber(numberCtrl.text);
    SearchFlowJumpResult finish(SearchFlowJumpResult r) {
      jumping = false;
      return r;
    }
    if (number == null) {
      return finish(SearchFlowJumpResult(
          kind: SearchFlowJumpKind.message,
          message: s['jumpNotFoundBody']));
    }
    if (source == 'guide') {
      final jump = await guideFlowListService.jumpToPosition(
          subject: subjectId, schoolClass: schoolClass, chapter: chapter!,
          type: type!, lesson: lesson, position: number);
      switch (jump.outcome) {
        case GuideFlowJumpOutcome.found:
          return finish(SearchFlowJumpResult(
              kind: SearchFlowJumpKind.guideQuestion,
              question: jump.question));
        case GuideFlowJumpOutcome.notFound:
          return finish(SearchFlowJumpResult(
              kind: SearchFlowJumpKind.message,
              message: s['jumpOutOfRangeBody']));
        case GuideFlowJumpOutcome.filterPending:
          return finish(SearchFlowJumpResult(
              kind: SearchFlowJumpKind.message,
              message: s['filterPendingBody']));
        case GuideFlowJumpOutcome.unavailable:
          return finish(SearchFlowJumpResult(
              kind: SearchFlowJumpKind.message,
              message: s['unavailableBody']));
      }
    }
    final rows = await textbookChapterService.fetchChapter(
        subjectId, schoolClass, chapter!, bn);
    if (rows == null) {
      return finish(SearchFlowJumpResult(
          kind: SearchFlowJumpKind.message,
          message: s['unavailableBody']));
    }
    final matched = rows
        .where((r) =>
            searchFlowTextbookMatches(type!, r.questionType) &&
            r.problem == number)
        .toList();
    if (matched.isEmpty) {
      return finish(SearchFlowJumpResult(
          kind: SearchFlowJumpKind.message,
          message: s['jumpNotFoundBody']));
    }
    if (matched.length == 1) {
      final q = matched.first;
      return finish(SearchFlowJumpResult(
          kind: SearchFlowJumpKind.lesson,
          lesson: LessonSelection(
              subject: subjectId, chapter: chapter!, page: q.page,
              problem: q.problem ?? 0, questionId: q.id,
              schoolClass: schoolClass)));
    }
    return finish(
        const SearchFlowJumpResult(kind: SearchFlowJumpKind.list));
  }
}
