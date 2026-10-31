// Guide bank data models (UI-agnostic row shapes).
// A GuideBankQuestion is one bank row: verbatim question text plus
// printed-only metadata. Marks and importance are absent when the
// guide does not print them — downstream code must never invent
// them (no marks badge, no star without printed evidence).
class GuideBankQuestion {
  final String id;
  final String questionText;
  final String questionType; // lowercase canonical: mcq, short,
  // creative, problem, task, matching, ...
  final List<String> options; // MCQ options verbatim; empty otherwise
  final int? correctOptionIndex; // null = no printed key IN THIS ROW.
  // List responses NEVER carry a key (only a hasKey boolean), so a
  // server row has correctOptionIndex null even when a key exists.
  // serverHasKey records that server-side knowledge separately.
  // NEVER let hasKey become true from this flag alone: the answer
  // screen indexes options[correctOptionIndex!], which would crash
  // on a null index. Use keyExists for "a key exists" labels.
  final bool serverHasKey;
  // Printed short-answer text (short questions only). Empty means
  // the guide prints no key text for this row — never synthesized.
  final String answerKeyText;
  final int? marks; // null = not printed
  final bool important; // true only when the guide prints it
  final String? setId; // null = chapter bank; model-test-<n> = set
  // Pilot tags (lesson 2.1 phase, 2026-10-31): lesson ('2.1'),
  // section, stimulusId, stimulusText — all OPTIONAL (missing
  // parses as null; untagged rows are "All only", never guessed).
  // The list action returns them after the pilot-fields deploy.
  final String? lesson;
  final String? section;
  final String? stimulusId;
  final String? stimulusText;
  // Pilot (2026-10-31): hasSolution = question and solution
  // chunked as ONE pair. Nullable: null = server did not say
  // (unknown, NOT "no solution"); chip shows only when true.
  final bool? hasSolution;
  // The guide-native chapter number (migration 011) for rows
  // served by the whole-guide search action: a search result
  // may come from any chapter, not the screen's chapter. Null
  // = the server did not say (chapter-local rows, or a
  // pre-migration server). Existing column, not a pilot field.
  final int? chapterNumber;
  // Phase 2 (2026-10-31): server-reported guide_error. True =
  // the row's printed key/solution is proven wrong; such rows
  // must never be scored. False also covers pre-migration
  // servers that do not send the flag (unknown, not proven
  // clean) — the quiz pool keeps the hardcoded id guard too.
  final bool guideError;
  const GuideBankQuestion({
    required this.id,
    required this.questionText,
    required this.questionType,
    this.options = const [],
    this.correctOptionIndex,
    this.serverHasKey = false,
    this.answerKeyText = '',
    this.marks,
    this.important = false,
    this.setId,
    this.guideError = false,
    this.lesson,
    this.section,
    this.stimulusId,
    this.stimulusText,
    this.hasSolution,
    this.chapterNumber,
  });

  /// A key counts only when it points at a real option.
  bool get hasKey =>
      correctOptionIndex != null &&
      correctOptionIndex! >= 0 &&
      correctOptionIndex! < options.length;

  /// "A stored key exists" (label use only): the index-based key
  /// OR the server's hasKey boolean. Never use this where the key
  /// VALUE is needed (scoring, key card) — those need hasKey.
  bool get keyExists => hasKey || serverHasKey;

  Map<String, dynamic> toJson() => {
        'id': id,
        'questionText': questionText,
        'questionType': questionType,
        'options': options,
        'correctOptionIndex': correctOptionIndex,
        // Round-trip the computed key status so a cached server
        // row keeps its "key exists" label after reload.
        'hasKey': keyExists,
        'answerKeyText': answerKeyText,
        'marks': marks,
        'important': important,
        'setId': setId,
        'guideError': guideError,
        'lesson': lesson,
        'section': section,
        'stimulusId': stimulusId,
        'stimulusText': stimulusText,
        'hasSolution': hasSolution,
        'chapterNumber': chapterNumber,
      };

  static GuideBankQuestion fromJson(Map<String, dynamic> j) {
    final opts = j['options'];
    return GuideBankQuestion(
      id: j['id'] as String? ?? '',
      questionText: j['questionText'] as String? ?? '',
      questionType: j['questionType'] as String? ?? '',
      options: opts is List ? opts.map((e) => e.toString()).toList() : const [],
      correctOptionIndex: (j['correctOptionIndex'] as num?)?.toInt(),
      serverHasKey: j['hasKey'] == true,
      answerKeyText: j['answerKeyText'] as String? ?? '',
      marks: (j['marks'] as num?)?.toInt(),
      important: j['important'] == true,
      setId: j['setId'] as String?,
      guideError: j['guideError'] == true,
      lesson: j['lesson'] as String?,
      section: j['section'] as String?,
      stimulusId: j['stimulusId'] as String?,
      stimulusText: j['stimulusText'] as String?,
      hasSolution: j['hasSolution'] is bool ? j['hasSolution'] as bool : null,
      chapterNumber: (j['chapterNumber'] as num?)?.toInt(),
    );
  }

  /// A row as served by the guide-bank list endpoint: options and
  /// a hasKey boolean, but NEVER a key index or key text (those
  /// stay with Mode G for the single opened question).
  static GuideBankQuestion fromServerJson(Map<String, dynamic> j) {
    final opts = j['options'];
    return GuideBankQuestion(
      id: j['id'] as String? ?? '',
      questionText: j['questionText'] as String? ?? '',
      questionType: j['questionType'] as String? ?? '',
      options: opts is List ? opts.map((e) => e.toString()).toList() : const [],
      serverHasKey: j['hasKey'] == true,
      marks: (j['marks'] as num?)?.toInt(),
      important: j['important'] == true,
      setId: j['setId'] as String?,
      guideError: j['guideError'] == true,
      lesson: j['lesson'] as String?,
      section: j['section'] as String?,
      stimulusId: j['stimulusId'] as String?,
      stimulusText: j['stimulusText'] as String?,
      hasSolution: j['hasSolution'] is bool ? j['hasSolution'] as bool : null,
      chapterNumber: (j['chapterNumber'] as num?)?.toInt(),
    );
  }
}

/// One guide model-test set's server metadata (sets action): counts
/// only, no rows. Rows for a set come from the list action with a
/// setId filter; the model-test screen rework that uses metadata
/// lists is a separate step.
class GuideModelSetInfo {
  final String setId;
  final int totalCount;
  final int keyedCount;
  const GuideModelSetInfo({
    required this.setId,
    required this.totalCount,
    required this.keyedCount,
  });

  int get unkeyedCount => totalCount - keyedCount;

  Map<String, dynamic> toJson() => {
        'setId': setId,
        'totalCount': totalCount,
        'keyedCount': keyedCount,
      };

  static GuideModelSetInfo fromJson(Map<String, dynamic> j) =>
      GuideModelSetInfo(
        setId: j['setId'] as String? ?? '',
        totalCount: (j['totalCount'] as num?)?.toInt() ?? 0,
        keyedCount: (j['keyedCount'] as num?)?.toInt() ?? 0,
      );
}

/// One guide model-test set: only the set id, subject and its rows.
// No title is stored: set titles are never invented.
class GuideModelSet {
  final String setId;
  final String subjectId;
  final List<GuideBankQuestion> questions;
  const GuideModelSet({
    required this.setId,
    required this.subjectId,
    required this.questions,
  });

  int get keyedCount => questions.where((q) => q.hasKey).length;
  int get unkeyedCount => questions.length - keyedCount;

  Map<String, dynamic> toJson() => {
        'setId': setId,
        'subjectId': subjectId,
        'questions': questions.map((q) => q.toJson()).toList(),
      };

  static GuideModelSet fromJson(Map<String, dynamic> j) {
    final qs = j['questions'];
    return GuideModelSet(
      setId: j['setId'] as String? ?? '',
      subjectId: j['subjectId'] as String? ?? '',
      questions: qs is List
          ? qs
              .whereType<Map>()
              .map((e) => GuideBankQuestion.fromJson(
                  e.map((k, v) => MapEntry(k.toString(), v))))
              .toList()
          : const [],
    );
  }
}

/// A per-question report, captured locally only (see
/// GuideBankService.submitReportLocal). No server endpoint exists
/// for guide reports today, so nothing here is ever "sent".
class GuideReport {
  final String questionId;
  final String subjectId;
  final int chapterNumber;
  final String reason; // wrong-key | wrong-chapter | unreadable
  final String createdAt; // ISO-8601 string
  const GuideReport({
    required this.questionId,
    required this.subjectId,
    required this.chapterNumber,
    required this.reason,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'subjectId': subjectId,
        'chapterNumber': chapterNumber,
        'reason': reason,
        'createdAt': createdAt,
      };

  static GuideReport fromJson(Map<String, dynamic> j) => GuideReport(
        questionId: j['questionId'] as String? ?? '',
        subjectId: j['subjectId'] as String? ?? '',
        chapterNumber: (j['chapterNumber'] as num?)?.toInt() ?? 0,
        reason: j['reason'] as String? ?? '',
        createdAt: j['createdAt'] as String? ?? '',
      );
}
