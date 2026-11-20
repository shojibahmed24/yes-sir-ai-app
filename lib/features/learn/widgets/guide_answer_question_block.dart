// Question + MCQ options block of the guide answer body, split out
// to keep guide_answer_body.dart under the 250-line cap. Rendering
// only: the parent owns try-first state and passes the already
// resolved correct index (null while the answer stays hidden).
import 'package:flutter/material.dart';

import '../../../core/models/guide_bank_model.dart';
import '../../../theme/app_tokens.dart';
import 'guide_mcq_no_options_card.dart';
import 'guide_mcq_options_card.dart';
import 'guide_translated_math_text.dart';

class GuideAnswerQuestionBlock extends StatelessWidget {
  const GuideAnswerQuestionBlock({
    super.key,
    required this.q,
    required this.fontSize,
    required this.s,
    required this.correctOptionIndex,
    required this.acceptedIndices,
    required this.onAttempted,
    required this.translate,
  });

  final GuideBankQuestion q;
  final double fontSize;
  final Map<String, String> s;
  final int? correctOptionIndex;
  final List<int>? acceptedIndices;
  final VoidCallback onAttempted;

  /// English only: other subjects always render the original text.
  final bool translate;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final mcqNoOptions = q.questionType == 'mcq' && q.options.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(Sp.lg),
            child: GuideTranslatedMathText(
              text: q.questionText,
              fontSize: fontSize + 1,
              fontWeight: FontWeight.w600,
              color: onSurface,
              translate: translate,
            ),
          ),
        ),
        const SizedBox(height: Sp.md),
        if (q.questionType == 'mcq' && q.options.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: Sp.md),
            child: GuideMcqOptionsCard(
              key: ValueKey('mcq:${q.id}'),
              options: q.options,
              correctOptionIndex: correctOptionIndex,
              acceptedIndices: acceptedIndices,
              fontSize: fontSize,
              s: s,
              onAttempted: onAttempted,
            ),
          ),
        if (mcqNoOptions)
          Padding(
            padding: const EdgeInsets.only(bottom: Sp.md),
            child: GuideMcqNoOptionsCard(fontSize: fontSize, s: s),
          ),
      ],
    );
  }
}
