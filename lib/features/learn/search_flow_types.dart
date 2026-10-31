// New search-flow pure logic (Step 3+5): type taxonomy, digit
// normalisation, lesson scope, chapter titles. No widgets, no I/O
// — fully unit-testable. Nothing here invents data:
// - Guide section values are migration 013 (LIST_SECTION_VALUES).
// - Textbook types are migration 009 + the backfill CANONICAL set
//   (mcq, fill_blank, creative, short, problem, task, descriptive,
//   boxed_kaj, other) plus verbatim lowercased values and NULL.
// - Chapter/lesson titles come ONLY from class9_10_math_chapters
//   (NCTB TOC + guide pilot banners, step 2).
import '../../core/data/class9_10_math_chapters.dart';
import '../../core/models/guide_bank_model.dart';
import 'lesson_selection.dart';

/// Jump outcome for the search screen's "সরাসরি উত্তর" button.
/// The controller resolves; the screen navigates. Keeping the
/// payload here lets the controller stay UI-free and testable.
enum SearchFlowJumpKind { guideQuestion, lesson, list, message }

class SearchFlowJumpResult {
  const SearchFlowJumpResult({
    required this.kind,
    this.question,
    this.lesson,
    this.message,
  });
  final SearchFlowJumpKind kind;

  /// Guide-mode hit: open via GuideAnswerHolder.
  final GuideBankQuestion? question;

  /// Textbook-mode single hit: open via LessonSelectionHolder.
  final LessonSelection? lesson;

  /// Human-readable outcome for message kind (not-found,
  /// filter-pending, unavailable) — never a guessed question.
  final String? message;
}

/// The 5 dropdown options — identical in textbook and guide mode.
/// There is deliberately NO "all questions" option: a list always
/// loads one type, 20 at a time.
enum SearchFlowType {
  mcq,
  short,
  creative,
  practiceWork,
  textbookExercise,
}

/// Guide-bank `section` value for a dropdown option (guide mode).
String searchFlowGuideSection(SearchFlowType type) {
  switch (type) {
    case SearchFlowType.mcq:
      return 'mcq_bank';
    case SearchFlowType.short:
      return 'short';
    case SearchFlowType.creative:
      return 'creative';
    case SearchFlowType.practiceWork:
      return 'practice_work';
    case SearchFlowType.textbookExercise:
      return 'textbook_exercise';
  }
}

/// Types with a server-side questionType filter on the OLD guide
/// server (v7 rows carry question_type but no section/lesson):
/// only MCQ / short / creative can be filtered client-side there.
/// practice_work and textbook_exercise need the new server's
/// section filter — on the old server they are honestly
/// unavailable, never faked from questionType.
String? searchFlowLegacyQuestionType(SearchFlowType type) {
  switch (type) {
    case SearchFlowType.mcq:
      return 'mcq';
    case SearchFlowType.short:
      return 'short';
    case SearchFlowType.creative:
      return 'creative';
    case SearchFlowType.practiceWork:
    case SearchFlowType.textbookExercise:
      return null;
  }
}

/// Textbook-mode match for one row's raw question_type value
/// (lowercase canonical, or null when the file had no type).
///
/// Verified mappings: MCQ -> mcq, সংক্ষিপ্ত -> short,
/// সৃজনশীল -> creative (individual rows: textbook creative has
/// no stimulus data, so no grouping).
/// অনুশীলনীমূলক কাজ -> task: the textbook type whose verified
/// Bangla label is 'কাজ' (chapter_questions_strings typeTask).
/// boxed_kaj is NOT folded into it: its meaning is unverified
/// anywhere in code, so it must not be silently relabelled.
/// পাঠ্যবইয়ের অনুশীলনী -> everything NOT covered by the other
/// four options (problem, fill_blank, descriptive, boxed_kaj,
/// other, null, and any verbatim value): the textbook chapter's
/// general exercise questions. This is a UI grouping rule, stated
/// here and in the report — it hides no row and mislabels none
/// as a type it is not; the row's own type is never displayed
/// as one of the four named types.
bool searchFlowTextbookMatches(SearchFlowType type, String? raw) {
  final v = raw?.trim().toLowerCase();
  switch (type) {
    case SearchFlowType.mcq:
      return v == 'mcq';
    case SearchFlowType.short:
      return v == 'short';
    case SearchFlowType.creative:
      return v == 'creative';
    case SearchFlowType.practiceWork:
      return v == 'task';
    case SearchFlowType.textbookExercise:
      return v != 'mcq' && v != 'short' && v != 'creative' && v != 'task';
  }
}

/// Question-number input -> positive int, or null when invalid.
/// Accepts Latin digits AND Bangla digits (০-৯), with surrounding
/// whitespace ignored. Bangla digits are converted, never
/// rejected: a student typing ৫ means 5. Anything else (empty,
/// letters, mixed, zero, negative) is null — never a guessed row.
int? normalizeQuestionNumber(String input) {
  const bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
  final buf = StringBuffer();
  for (final ch in input.trim().split('')) {
    if (ch == ' ' || ch == '\u00a0') continue;
    final bi = bn.indexOf(ch);
    if (bi >= 0) {
      buf.write(bi);
      continue;
    }
    buf.write(ch);
  }
  final n = int.tryParse(buf.toString());
  if (n == null || n <= 0) return null;
  return n;
}

/// Lessons actually present for a chapter, as
/// lesson-code -> title. TODAY only class 9-10 math chapter 2 has
/// DB-backed lesson rows (2.1 / 2.2); every other chapter returns
/// empty, and the search screen SKIPS the lesson step entirely
/// for it. Pilot-file-only lessons (ch 3/7/8/9) are deliberately
/// NOT included: they are not in the DB yet, so presenting them
/// would promise rows that do not exist.
Map<String, String> lessonsForChapter(
    String subject, int schoolClass, int chapter) {
  if (subject == 'math' &&
      (schoolClass == 9 || schoolClass == 10) &&
      chapter == 2) {
    return chapter2LessonTitles;
  }
  return const {};
}

/// Verified chapter title for the new search UI, or null when no
/// verified title exists (caller then shows "অধ্যায় N" — the
/// number alone, never an invented title). Textbook mode prefers
/// the DB title when the caller has one; this static map is the
/// fallback for class 9-10 math, whose textbook chapters are not
/// in the DB yet. Guide mode uses the same map: guide and
/// textbook chapter numbers/names match (step-2 cross-check).
String? verifiedChapterTitle(String subject, int schoolClass, int number) {
  if (subject == 'math' && (schoolClass == 9 || schoolClass == 10)) {
    return class9_10MathChapterTitles[number];
  }
  return null;
}
