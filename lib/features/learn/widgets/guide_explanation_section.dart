// Guide explanation section, split out of guide_answer_body.dart
// to keep that file under the 250-line rule. Renders the
// stage-2 AI explanation (structured renderer), a pending row
// while it runs, prose fallback when unstructured, or a failed
// row with retry — never a screen hiding the stage-1 cards.
import 'package:flutter/material.dart';

import '../../../core/models/guide_bank_model.dart';
import '../../../core/services/structured_explanation_service.dart';
import 'guide_message_state.dart';
import 'solution_renderer.dart';

class GuideExplanationSection extends StatelessWidget {
  const GuideExplanationSection({
    super.key,
    required this.attempt,
    required this.question,
    required this.chips,
    required this.fontSize,
    required this.s,
    required this.ls,
    required this.stepsOnly,
    required this.explanationPending,
    required this.onRetry,
  });
  final StructuredAttempt? attempt;
  final GuideBankQuestion question;
  final List<String> chips;
  final double fontSize;
  final Map<String, String> s;
  final Map<String, String> ls;
  final bool stepsOnly;
  final bool explanationPending;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final failed =
        attempt == null || attempt!.status == StructuredStatus.failed;
    final proseFallback = attempt != null &&
            attempt!.status == StructuredStatus.failed &&
            attempt!.rawText.isNotEmpty
        ? attempt!.rawText
        : null;
    if (explanationPending) {
      return Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(s['explanationLoading']!),
        ],
      );
    }
    if (!failed) {
      return SolutionRenderer(
        key: ValueKey('guide:${question.id}'),
        solution: attempt!.solution,
        sourceChips: chips,
        fontSize: fontSize,
        s: ls,
        marksPrinted: question.marks != null,
        hideSummary: stepsOnly,
        fallbackText: attempt!.solution == null ? attempt!.rawText : null,
        questionText: question.questionText,
        questionLabel: ls['sourceGuideQuestion']!,
        explanationLabel: ls['sourceAiExplanation']!,
      );
    }
    if (proseFallback != null) {
      return SolutionRenderer(
        key: ValueKey('guide-prose:${question.id}'),
        solution: null,
        sourceChips: chips,
        fontSize: fontSize,
        s: ls,
        marksPrinted: question.marks != null,
        fallbackText: proseFallback,
        questionText: question.questionText,
        questionLabel: ls['sourceGuideQuestion']!,
        explanationLabel: ls['sourceAiExplanation']!,
      );
    }
    return GuideMessageState(
      title: s['answerFailed']!,
      buttonLabel: s['retry']!,
      onPressed: onRetry,
    );
  }
}
