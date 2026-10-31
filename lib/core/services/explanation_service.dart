// Phase 2 (C2): the ONLY path from a question to an AI explanation.
// Grounding order — never guess, never substitute: (1) Edge
// Function (service role) returns verified context; the app never
// reads book_questions directly. (2) Edge missing: chapter-only.
// (3) DEMO: local index only. No key lives here.
// POSTs go through the shared edgePost (30s timeout, client
// closed on all paths) — no private copy here.
import '../models/backend_models.dart';
import 'app_config.dart';
import 'books_service.dart';
import 'edge_post.dart';
import 'marks_budget.dart';
import 'openrouter_client.dart';
import 'learn_service.dart';
import 'practice_service.dart';
import 'supabase_client.dart';

enum ExplanationOutcome { live, demo, ungrounded, failed }

/// Resolution against the book index. found == context != null.
/// Others: 'not-indexed', 'chapter-only', 'edge-missing'.
class Grounding {
  final GroundedContext? context;
  final String reason;
  const Grounding({this.context, required this.reason});
  bool get found => context != null && reason == 'found';
  static const notIndexed = Grounding(reason: 'not-indexed');
}

class ExplanationResult {
  final ExplanationOutcome outcome;
  final String text;
  final GroundedContext? context;
  final String demoKind; // '' | 'grounded' | 'bank'
  final bool serverKeyMissing; // Edge OPENROUTER secret not set
  const ExplanationResult({
    required this.outcome,
    this.text = '',
    this.context,
    this.demoKind = '', this.serverKeyMissing = false,
  });
}

class ExplanationService {
  Future<Grounding> resolve({
    required String subject,
    int schoolClass = 6,
    required int chapter,
    required int page,
    required int problem,
    required bool bangla,
  }) async {
    if (supabaseOrNull != null && AppConfig.explainEndpoint.isNotEmpty) {
      final res = await edgePost({
        'subject': subject,
        'classId': schoolClass,
        'chapter': chapter,
        'page': page,
        'problem': problem,
        'language': bangla ? 'bn' : 'en',
      });
      if (res != null) {
        if (res['found'] == true) {
          final ctx = _contextFrom(res, subject, schoolClass);
          if (ctx != null) return Grounding(context: ctx, reason: 'found');
        }
        return Grounding.notIndexed;
      }
      final chapters = await booksService.chaptersForSubjectAsync(
        schoolClass,
        subject,
        bangla,
      );
      if (chapters == null) return const Grounding(reason: 'edge-missing');
      if (!chapters.any((c) => c.number == chapter)) {
        return Grounding.notIndexed;
      }
      return const Grounding(reason: 'chapter-only');
    }
    if (supabaseOrNull != null) {
      return const Grounding(reason: 'edge-missing');
    }
    // DEMO: local index only (2 questions, see learn_service).
    final local = learnService.resolve(
      subject: subject,
      chapter: chapter,
      page: page,
      problem: problem,
    );
    if (!local.found) return Grounding.notIndexed;
    return Grounding(
      context: GroundedContext(
        bookTitle: '',
        chapterTitle: '',
        subject: subject,
        schoolClass: schoolClass,
        chapterNumber: chapter,
        page: page,
        problem: problem,
        questionText: local.question,
        localAnswer: bangla ? local.answerBn : local.answerEn,
        source: 'local-index',
      ),
      reason: 'found',
    );
  }

  /// Quiz/model-test lookup by wording. Edge-only: no local bank
  /// is ever claimed as a book match.
  Future<Grounding> resolveByText({
    required String subject,
    int schoolClass = 6,
    required String questionText,
    required bool bangla,
  }) async {
    if (supabaseOrNull == null || AppConfig.explainEndpoint.isEmpty) {
      return const Grounding(reason: 'edge-missing');
    }
    final res = await edgePost({
      'subject': subject,
      'classId': schoolClass,
      'questionText': questionText,
      'language': bangla ? 'bn' : 'en',
    });
    if (res == null) return const Grounding(reason: 'edge-missing');
    if (res['found'] != true) return Grounding.notIndexed;
    final ctx = _contextFrom(res, subject, schoolClass);
    if (ctx == null) return Grounding.notIndexed;
    return Grounding(context: ctx, reason: 'found');
  }

  /// AI explanation for grounded input only — ungrounded input
  /// never reaches the AI. userQuestion = chat follow-up, else null.
  /// [marksOverride] is the chat worker's user-stated marks
  /// (parseUserMarks of the student's message); null leaves the
  /// call unchanged. The plain-text path has no step budget, so
  /// the override is applied best-effort as a prompt-only
  /// teacher instruction appended to the follow-up — it is
  /// never displayed as printed marks. The fully budgeted path
  /// is structuredExplanationService.explainStructured, which
  /// turns the same override into a marksBudgetFor step budget.
  Future<ExplanationResult> explain({
    required Grounding grounding,
    required String style,
    required bool bangla,
    String? userQuestion,
    int? marksOverride,
  }) async {
    final ctx = grounding.context;
    if (!grounding.found || ctx == null) {
      return const ExplanationResult(outcome: ExplanationOutcome.ungrounded);
    }
    if (!AppConfig.aiTextConfigured) {
      final demoText =
          ctx.localAnswer.isNotEmpty ? ctx.localAnswer : ctx.questionText;
      return ExplanationResult(
        outcome: ExplanationOutcome.demo,
        text: demoText,
        context: ctx,
        demoKind: 'grounded',
      );
    }
    var effectiveFollowUp = userQuestion;
    if (marksOverride != null) {
      final budget = marksBudgetFor(
        marks: marksOverride,
        questionType:
            ctx.questionType.isEmpty ? 'textbook' : ctx.questionType,
      );
      final note = 'Teacher instruction: this answer is worth '
          '${budget.marks} marks. ${budget.guidance} Do not state '
          'or print any marks in the answer.';
      final follow = (effectiveFollowUp ?? '').trim();
      effectiveFollowUp = follow.isEmpty ? note : '$follow\n$note';
    }
    final gen = await openRouterClient.explain(
      ctx: ctx,
      style: style,
      bangla: bangla,
      userQuestion: effectiveFollowUp,
    );
    if (gen.keyMissing) {
      return ExplanationResult(
        outcome: ExplanationOutcome.failed,
        context: ctx,
        serverKeyMissing: true,
      );
    }
    final text = gen.text;
    if (text == null || text.isEmpty) {
      return ExplanationResult(
        outcome: ExplanationOutcome.failed,
        context: ctx,
      );
    }
    return ExplanationResult(
      outcome: ExplanationOutcome.live,
      text: text,
      context: ctx,
    );
  }

  /// Quiz explanation via the book index. Live-but-unmatched =>
  /// ungrounded, NEVER the DEMO bank (bank only, no server path).
  Future<ExplanationResult> explainQuiz({
    required QuizItem item,
    required String subject,
    required bool bangla,
  }) async {
    final grounding = await resolveByText(
      subject: subject,
      questionText: bangla ? item.questionBn : item.questionEn,
      bangla: bangla,
    );
    if (grounding.found) {
      return explain(grounding: grounding, style: 'simple', bangla: bangla);
    }
    if (grounding.reason == 'edge-missing') {
      return ExplanationResult(
        outcome: ExplanationOutcome.demo,
        text: practiceService.explanation(item.id, bangla),
        demoKind: 'bank',
      );
    }
    return const ExplanationResult(outcome: ExplanationOutcome.ungrounded);
  }

  GroundedContext? _contextFrom(
    Map<String, dynamic> res,
    String subject,
    int schoolClass,
  ) {
    final questionText = res['questionText'];
    if (questionText is! String || questionText.isEmpty) return null;
    // Mode A chunks (Edge objects {text, pageStart, pageEnd}, max 3); other modes / old deploys send none, so the prompt stays question-only.
    final chunks = ((res['chunks'] as List?) ?? []).whereType<Map>().where((c) => c['text'] is String && (c['text'] as String).isNotEmpty).take(3).toList();
    final chunkTexts = chunks.map((c) => c['text'] as String).toList(); final chunkRanges = chunks.map((c) { final s = c['pageStart'], e = c['pageEnd']; return s is num && e is num ? '${s.toInt()}–${e.toInt()}' : ''; }).toList();
    return GroundedContext(
      bookTitle: '${res['bookTitle'] ?? ''}', chapterTitle: '${res['chapterTitle'] ?? ''}',
      subject: subject, schoolClass: schoolClass,
      chapterNumber: (res['chapterNumber'] as num?)?.toInt() ?? 0,
      page: (res['page'] as num?)?.toInt() ?? 0, problem: (res['problem'] as num?)?.toInt() ?? 0,
      questionText: questionText, source: 'edge',
      chunkTexts: chunkTexts, chunkPageRanges: chunkRanges,
    );
  }

}

final explanationService = ExplanationService();
