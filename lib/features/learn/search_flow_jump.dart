// Direct jump for the search screen, split out of
// SearchFlowController so the controller stays under the
// 250-line cap (same pattern as SearchFlowListQuery).
// Resolves here and returns a result; the screen navigates.
// Uses only the controller's public state (onChanged()
// instead of its private _notify).
import '../../core/services/guide_flow_jump.dart';
import '../../core/services/guide_flow_models.dart';
import '../../core/services/model_test_set_service.dart';
import '../../core/services/textbook_chapter_service.dart';
import 'lesson_selection.dart';
import 'search_flow_controller.dart';
import 'search_flow_types.dart';

extension SearchFlowJump on SearchFlowController {
  /// Direct jump, scoped to type + lesson + chapter + source.
  /// Guide: positional; textbook: matched on printed number.
  /// Chapterless modes have no chapter/type, so they branch
  /// before the chapter guard: a picked set jumps within the
  /// set's rows, a picked Paper-II section jumps within that
  /// section's chapterless list. Both used to fall through
  /// the guard and return a null message — the number field
  /// and jump button showed, but tapping did nothing.
  Future<SearchFlowJumpResult> jump(Map<String, String> s, bool bn,
      {String? paper2Section, String? setId}) async {
    final isSet = setId != null;
    final isPaper2 = !isSet &&
        source == 'guide' &&
        subjectId == 'english-2nd' &&
        paper2Section != null;
    if (!isSet &&
        !isPaper2 &&
        (chapter == null ||
            (englishGuideSectionMode ? section == null : type == null))) {
      return const SearchFlowJumpResult(kind: SearchFlowJumpKind.message);
    }
    jumping = true;
    onChanged();
    final number = normalizeQuestionNumber(numberCtrl.text);
    SearchFlowJumpResult finish(SearchFlowJumpResult r) {
      jumping = false;
      return r;
    }

    /// One mapping for every guide jump outcome, so the
    /// chapter, Paper-II and set paths cannot drift apart.
    SearchFlowJumpResult finishJump(GuideFlowJump jump) {
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

    if (number == null) {
      return finish(SearchFlowJumpResult(
          kind: SearchFlowJumpKind.message,
          message: s['jumpNotFoundBody']));
    }
    if (isSet) {
      final rows = await modelTestSetService.fetchSetRows(
          effectiveSubjectId, setId,
          schoolClass: effectiveClass);
      if (rows == null) {
        return finish(SearchFlowJumpResult(
            kind: SearchFlowJumpKind.message,
            message: s['unavailableBody']));
      }
      if (number > rows.length) {
        return finish(SearchFlowJumpResult(
            kind: SearchFlowJumpKind.message,
            message: s['jumpOutOfRangeBody']));
      }
      return finish(SearchFlowJumpResult(
          kind: SearchFlowJumpKind.guideQuestion,
          question: rows[number - 1]));
    }
    if (isPaper2) {
      final jump =
          await guideFlowJumpService.jumpToChapterlessPosition(
              subject: effectiveSubjectId,
              schoolClass: effectiveClass,
              section: paper2Section,
              position: number);
      return finishJump(jump);
    }
    if (source == 'guide') {
      final jump = await guideFlowJumpService.jumpToPosition(
          subject: subjectId, schoolClass: schoolClass, chapter: chapter!,
          type: type, lesson: lesson, position: number,
          section: englishGuideSectionMode ? section : null);
      return finishJump(jump);
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
