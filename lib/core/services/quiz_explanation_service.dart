// Quiz explanation (Phase 2, plan §2 step 3). Split out of
// explanation_service.dart to keep it under the 250-line cap.
// Grounding rule — never guess, never substitute:
// - Bank items (mq/mm/mp/sq/sm/sp ids) keep the old path:
//   textbook-index lookup by wording, DEMO bank only when the
//   Edge is unreachable, ungrounded otherwise.
// - Guide items (every other quiz id) resolve DIRECTLY by row
//   id via Mode G (resolveGuide) — the textbook index is never
//   consulted for them, so the old "ইনডেক্সে পাওয়া যায়নি"
//   failure for guide questions is gone. A guide row that does
//   not resolve yields guideMissing (honest message), never a
//   bank substitution.
// - Guide explanations are OPTION-WISE: the prompt names every
//   option and the verified correct letter, and requires a
//   why-right / why-wrong reason per option, math in $...$
//   LaTeX (rendered by the Phase 1 chain: normalize +
//   SolutionRichText, see quiz_explanation_body.dart).
import '../models/backend_models.dart';
import 'explanation_service.dart';
import 'guide_quiz_pool.dart';
import 'practice_service.dart';
import 'resolve_school_class.dart';
import 'structured_explanation_service.dart';

/// Bank ids (practice_service.subjectOf's closed set): mq/mm/mp
/// = maths, sq/sm/sp = science. Every other quiz id is a guide
/// row id (class7-...-guide-... or pilot...), never a bank id.
bool isBankQuizId(String id) =>
    id.startsWith('mq') ||
    id.startsWith('mm') ||
    id.startsWith('mp') ||
    id.startsWith('sq') ||
    id.startsWith('sm') ||
    id.startsWith('sp');

const _letters = ['ক', 'খ', 'গ', 'ঘ', 'ঙ'];
const _lettersEn = ['A', 'B', 'C', 'D', 'E'];

/// Option-wise instruction for the AI (pure, tested): every
/// option listed with its letter, the verified correct letter(s)
/// named, one why-right / why-wrong reason required per option.
/// [multiKey] pluralises the "correct option" wording: with
/// several accepted letters, more than one option is right.
String optionWiseInstruction({
  required QuizItem item,
  required String correctLetter,
  required bool bangla,
  bool multiKey = false,
}) {
  final letters = bangla ? _letters : _lettersEn;
  final listed = [
    for (var i = 0; i < item.options.length; i++)
      '${letters[i]}) ${item.options[i]}'
  ].join('; ');
  if (bangla) {
    return 'এই MCQ-র প্রতিটা অপশন ধরে আলাদা করে ব্যাখ্যা করো: '
        '${multiKey ? 'সঠিক অপশনগুলো কেন ঠিক' : 'সঠিক অপশনটি কেন ঠিক'} (কোন নিয়ম/হিসাবে), আর প্রতিটা ভুল '
        'অপশন কেন ভুল (কোথায় ভুল ধারণা বা হিসাব)। অপশনগুলো: '
        '$listed। সঠিক উত্তর: $correctLetter। গণিত \$...\$ LaTeX-এ '
        'লেখো (ভগ্নাংশ \\frac{}{} দিয়ে)।';
  }
  return 'Explain EACH option of this MCQ separately: why the '
      '${multiKey ? 'correct options are' : 'correct option is'} right (which rule/calculation), and why '
      'each wrong option is wrong (where the misconception or '
      'calculation fails). Options: $listed. Correct answer: '
      '$correctLetter. Write math in \$...\$ LaTeX '
      '(fractions as \\frac{}{}).';
}

/// Verified correct-answer label for the option-wise prompt
/// (pure, tested). Multi-key items name EVERY accepted
/// letter ("ক, খ"), never just the first: the old code fell
/// back to the single correctIndex, so the AI was told only
/// one variant was right and explained the other accepted
/// option as wrong. The accepted set comes from the item
/// (resolveKeys) when present, else from the Mode G key
/// parsed the same way resolveKeys parses it; a raw key
/// that maps to nothing stays verbatim, never invented.
String acceptedAnswerLabel({
  required QuizItem item,
  required String answerKey,
  required bool bangla,
}) {
  final letters = bangla ? _letters : _lettersEn;
  final accepted = item.correctIndices.isNotEmpty
      ? item.correctIndices
      : acceptedOptionIndices(
          parseAcceptedAnswerKeys(answerKey), item.options);
  final lettered = accepted
      .where((i) => i >= 0 && i < letters.length)
      .map((i) => letters[i])
      .toList();
  if (lettered.isNotEmpty) return lettered.join(', ');
  if (answerKey.isNotEmpty) return answerKey;
  return item.correctIndex >= 0 && item.correctIndex < letters.length
      ? letters[item.correctIndex]
      : '';
}

class QuizExplanationService {
  /// Quiz explanation for one checked question. Live-but-
  /// unmatched guide rows return guideMissing (the screen
  /// shows the guide-specific honest message).
  Future<ExplanationResult> explainQuiz({
    required QuizItem item,
    required String subject,
    required bool bangla,
  }) async {
    if (isBankQuizId(item.id)) {
      final grounding = await explanationService.resolveByText(
        subject: subject,
        questionText: bangla ? item.questionBn : item.questionEn,
        bangla: bangla,
      );
      if (grounding.found) {
        return explanationService.explain(
            grounding: grounding, style: 'simple', bangla: bangla);
      }
      if (grounding.reason == 'edge-missing') {
        return ExplanationResult(
          outcome: ExplanationOutcome.demo,
          text: practiceService.explanation(item.id, bangla),
          demoKind: 'bank',
        );
      }
      return const ExplanationResult(
          outcome: ExplanationOutcome.ungrounded);
    }
    final schoolClass = await resolveSchoolClass();
    final grounding = await structuredExplanationService.resolveGuide(
      guideQuestionId: item.id,
      subject: subject,
      schoolClass: schoolClass,
      bangla: bangla,
    );
    if (!grounding.found || grounding.context == null) {
      if (grounding.reason == 'edge-missing') {
        return const ExplanationResult(
            outcome: ExplanationOutcome.failed);
      }
      return const ExplanationResult(
          outcome: ExplanationOutcome.ungrounded, guideMissing: true);
    }
    final ctx = grounding.context!;
    final correctLetter = acceptedAnswerLabel(
        item: item, answerKey: ctx.answerKey, bangla: bangla);
    return explanationService.explain(
      grounding: grounding,
      style: 'simple',
      bangla: bangla,
      userQuestion: optionWiseInstruction(
          item: item,
          correctLetter: correctLetter,
          bangla: bangla,
          multiKey: item.correctIndices.length > 1),
    );
  }
}

final quizExplanationService = QuizExplanationService();
