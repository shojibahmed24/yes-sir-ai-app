// Plain data models shared by the data services. No network code here.

/// One row of the books_public view. The view carries a SINGLE title
/// column: a 'bn' row's title is the Bangla title, an 'en' row's title
/// is the English title. Callers filter by language, so both title
/// fields are filled with that row's title and title(bn) is correct
/// for the UI language in use. Never query the books table directly:
/// it holds the server-only source_link and has no client RLS policy.
class BookInfo {
  final String id, titleBn, titleEn, subject;
  final int schoolClass;
  final bool supplied;
  const BookInfo({
    required this.id,
    required this.titleBn,
    required this.titleEn,
    required this.subject,
    required this.schoolClass,
    required this.supplied,
  });
  String title(bool bangla) => bangla ? titleBn : titleEn;
}

/// One row of the chapters table (client-readable for signed-in
/// users per migration 002). Chapters carry both titles, so one row
/// serves both UI languages.
class ChapterInfo {
  final String id, bookId, bookTitle, titleBn, titleEn;
  final int number;
  const ChapterInfo({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.number,
    required this.titleBn,
    required this.titleEn,
  });
  String title(bool bangla) => bangla ? titleBn : titleEn;
}

/// One row of the subjects table, enriched with the class's books:
/// locked = no supplied book for this subject in this class+language,
/// chapterCount = chapters of that subject's books in that language
/// (0 when unknown / no chapters imported yet).
class SubjectInfo {
  final String id, nameBn, nameEn;
  final bool locked;
  final int chapterCount;

  /// Guide availability (server-checked in subjectsAsync): true
  /// when this class+subject has guide-bank chapters even though
  /// its textbook is not supplied. A guide-available subject is
  /// VISIBLE on Home and reachable in Search via the guide route,
  /// even though textbook lessons stay locked. Defaults false/0
  /// (DEMO fallback, or the guide check failed) — never a guess.
  final bool hasGuide;
  final int guideChapterCount;
  const SubjectInfo({
    required this.id,
    required this.nameBn,
    required this.nameEn,
    required this.locked,
    required this.chapterCount,
    this.hasGuide = false,
    this.guideChapterCount = 0,
  });
  String name(bool bangla) => bangla ? nameBn : nameEn;
}

class LessonResult {
  final String question, answerBn, answerEn;
  final bool found;
  const LessonResult({
    required this.question,
    required this.answerBn,
    required this.answerEn,
    required this.found,
  });
  static const noMatch = LessonResult(
    question: '',
    answerBn: '',
    answerEn: '',
    found: false,
  );
}

/// Book-verified context for ONE question, returned only by the
/// server-side path (Edge Function) or the local DEMO index.
/// questionText is the book's own wording, verbatim — the AI is
/// sent this text, never just a question title. localAnswer is
/// non-empty ONLY for the local DEMO index; edge-grounded rows
/// carry no stored answer (book_questions holds question text
/// only), so a no-key DEMO fallback shows the question itself.
/// sourceLink is deliberately absent: it is server-only and must
/// never reach the app.
class GroundedContext {
  final String bookTitle, chapterTitle, subject;
  final int schoolClass, chapterNumber, page, problem;
  final String questionText, localAnswer, source; // edge | local-index | guide
  /// Book chapter text chunks (OCR) for this question's page, max 3,
  /// in reading order. Empty = no chunk grounding; the prompt must
  /// then say plainly the explanation is question-only grounded.
  /// chunkPageRanges runs parallel to chunkTexts ('12–14' style).
  final List<String> chunkTexts, chunkPageRanges;

  /// Guide Mode G fields (empty for textbook Mode A rows).
  /// questionType: 'mcq' | 'short' | 'creative' | 'problem' | ''.
  /// marks is the PRINTED mark count, or null when unprinted.
  /// answerKey is the printed key for MCQ/short, else ''.
  /// guideUnitText is HIDDEN grounding (the guide's worked
  /// solution for creative/long/Math) — it goes into the AI
  /// prompt. It is rendered to the student ONLY when the server
  /// marks it verbatim (verbatimKind 'guide'/'corrected'); in
  /// every other case it stays hidden grounding, exactly as
  /// before. fallbackChunkText is the single prose fallback
  /// chunk, or ''.
  final String guideQuestionId, questionType, answerKey;
  final String guideUnitText, guideUnitKind, fallbackChunkText;
  final String verbatimKind, verbatimText, correctionNote;
  final bool guideError;
  final int? marks;
  const GroundedContext({
    required this.bookTitle,
    required this.chapterTitle,
    required this.subject,
    required this.schoolClass,
    required this.chapterNumber,
    required this.page,
    required this.problem,
    required this.questionText,
    this.localAnswer = '',
    required this.source,
    this.chunkTexts = const [],
    this.chunkPageRanges = const [],
    this.guideQuestionId = '',
    this.questionType = '',
    this.answerKey = '',
    this.guideUnitText = '',
    this.guideUnitKind = '',
    this.fallbackChunkText = '',
    this.verbatimKind = 'none',
    this.verbatimText = '',
    this.correctionNote = '',
    this.guideError = false,
    this.marks,
  });

  /// True when the server explicitly allows stage-1 verbatim
  /// display for this row (guide text or curated correction).
  bool get hasVerbatim =>
      (verbatimKind == 'guide' || verbatimKind == 'corrected') &&
      verbatimText.isNotEmpty;

  /// True when this row carries printed marks (a badge may show).
  bool get marksPrinted => marks != null;
}

class PracticeProblem {
  final String id, questionBn, questionEn, answerBn, answerEn;
  const PracticeProblem({
    required this.id,
    required this.questionBn,
    required this.questionEn,
    required this.answerBn,
    required this.answerEn,
  });
}

class QuizItem {
  final String id, questionBn, questionEn;
  final List<String> options;
  final int correctIndex;
  const QuizItem({
    required this.id,
    required this.questionBn,
    required this.questionEn,
    required this.options,
    required this.correctIndex,
  });

  // Phase 2 (2026-10-31): weak-revision persistence. A finished
  // run's wrong items are stored inside Attempt, so a later
  // revision quiz can re-ask GUIDE items too — guide ids are
  // not in any bank, so findQuestion() can never rebuild them.
  Map<String, dynamic> toJson() => {
        'id': id,
        'questionBn': questionBn,
        'questionEn': questionEn,
        'options': options,
        'correctIndex': correctIndex,
      };

  static QuizItem fromJson(Map<String, dynamic> j) {
    final opts = j['options'];
    return QuizItem(
      id: j['id'] as String? ?? '',
      questionBn: j['questionBn'] as String? ?? '',
      questionEn: j['questionEn'] as String? ?? '',
      options:
          opts is List ? opts.map((e) => e.toString()).toList() : const [],
      correctIndex: (j['correctIndex'] as num?)?.toInt() ?? 0,
    );
  }
}

class VoiceBudget {
  final int usedMinutes, capMinutes;
  const VoiceBudget({required this.usedMinutes, required this.capMinutes});
  int get remaining => (capMinutes - usedMinutes).clamp(0, capMinutes);
  bool get hasMinutes => remaining > 0;
}
