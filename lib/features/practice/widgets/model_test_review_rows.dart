// "প্রতিটি প্রশ্নের রিভিউ" list for the model-test results screen,
// split out so model_test_results_screen.dart stays under the
// 250-line cap. Rendering only: the attempt owns the answers.
import 'package:flutter/material.dart';

import '../../../core/models/backend_models.dart';
import '../practice_store.dart';
import 'practice_widgets.dart';

class ModelReviewRows extends StatelessWidget {
  const ModelReviewRows({
    super.key,
    required this.attempt,
    required this.items,
    required this.bangla,
    required this.s,
  });

  final Attempt attempt;
  final List<QuizItem> items;
  final bool bangla;
  final Map<String, String> s;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final q in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _row(context, q),
          ),
      ],
    );
  }

  Widget _row(BuildContext context, QuizItem q) {
    final a = attempt.answers[q.id];
    final flaggedMark = attempt.flagged.contains(q.id)
        ? " · ${s['flaggedLabel']!}"
        : '';
    final sub =
        (a == null
            ? s['skippedLabel']!
            : "${s['yourAnswer']!}: ${q.options[a]} · "
                  "${s['correctAnswer']!}: "
                  "${q.acceptedOptionTexts.join(' / ')}") +
        flaggedMark;
    return PracticeCard(
      title: bangla ? q.questionBn : q.questionEn,
      subtitle: sub,
      maxTitleLines: null,
      icon: a == null
          ? Icons.remove_circle_outline
          : (q.isCorrect(a) ? Icons.check_circle : Icons.cancel),
    );
  }
}
