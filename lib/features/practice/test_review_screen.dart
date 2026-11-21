// Filtered review of one finished run (B1).
//
// Opened from a tappable "correct / wrong / skipped" card on the
// results screen: shows ONLY the questions of that bucket, each with
// the student's answer and the guide key, so "which were wrong?" is
// answerable. Read-only; nothing is regenerated or guessed.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/language_provider.dart';
import '../../l10n/pages/model_test_results_strings.dart';
import '../../theme/themed_scaffold.dart';
import 'practice_store.dart';
import 'widgets/practice_widgets.dart';
import 'widgets/review_filter_cards.dart';

class TestReviewScreen extends StatelessWidget {
  const TestReviewScreen({super.key, required this.filter});

  final ReviewFilter filter;

  bool _matches(int? answer, bool correct) {
    switch (filter) {
      case ReviewFilter.correct:
        return answer != null && correct;
      case ReviewFilter.wrong:
        return answer != null && !correct;
      case ReviewFilter.skipped:
        return answer == null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? modelTestResultsStringsBn : modelTestResultsStringsEn;
        final attempt = PracticeSession.lastAttempt;
        final items = PracticeSession.lastItems;
        if (attempt == null || items.isEmpty) {
          return ThemedScaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/practice'),
              ),
              title: Text(s['title']!),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(s['noResult']!),
            ),
          );
        }
        final rows = <(int, dynamic)>[];
        for (var i = 0; i < items.length; i++) {
          final q = items[i];
          final a = attempt.answers[q.id];
          if (_matches(a, a != null && q.isCorrect(a))) rows.add((i, q));
        }
        final titles = {
          ReviewFilter.correct: s['correct']!,
          ReviewFilter.wrong: s['wrong']!,
          ReviewFilter.skipped: s['skipped']!,
        };
        return ThemedScaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/model-test-results'),
            ),
            title: Text('${titles[filter]!} · ${rows.length}'),
          ),
          body: rows.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(s['reviewEmpty']!),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: rows.length,
                  itemBuilder: (context, idx) {
                    final (i, q) = rows[idx];
                    final a = attempt.answers[q.id];
                    final sub = a == null
                        ? s['skippedLabel']!
                        : '${s['yourAnswer']!}: ${q.options[a]} · '
                              '${s['correctAnswer']!}: '
                              '${q.acceptedOptionTexts.join(' / ')}';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: PracticeCard(
                        title:
                            '#${i + 1} · ${bn ? q.questionBn : q.questionEn}',
                        subtitle: sub,
                        maxTitleLines: null,
                        icon: switch (filter) {
                          ReviewFilter.correct => Icons.check_circle,
                          ReviewFilter.wrong => Icons.cancel,
                          ReviewFilter.skipped => Icons.remove_circle_outline,
                        },
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
