// Route: /guide-model-tests — cached guide model-test sets for
// the selected subject. Timed entry reuses the existing exam
// screen via PracticeSession (same pattern as ModelTestListScreen).
// Scoring: keyed MCQ only. Unkeyed rows are excluded and the
// count is labelled — never scored, never guessed. Gate: model
// tests are FREE while the guide bank is free-open
// (freeGuideLimit < 0); when the bank re-locks, a non-premium
// start goes to the paywall, never the exam.
// Exam minutes default to 15, matching the existing default maths
// test minutes (practice_store), since sets store no minutes.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/backend_models.dart';
import '../../core/models/guide_bank_model.dart';
import '../../core/services/app_config.dart';
import '../../core/services/billing_service.dart';
import '../../core/services/guide_bank_service.dart';
import '../../core/services/resolve_school_class.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/guide_bank_strings.dart';
import '../learn/widgets/digits.dart';
import '../learn/widgets/mock_data.dart';
import 'practice_store.dart';
import 'widgets/practice_widgets.dart';

class GuideModelTestListScreen extends StatelessWidget {
  const GuideModelTestListScreen({super.key});

  Future<void> _start(
    BuildContext context,
    String subject,
    GuideModelSet set,
    bool isPremium,
  ) async {
    // Free-open (freeGuideLimit < 0) bypasses the paywall; the
    // branch stays so one AppConfig value re-locks it later.
    if (!isPremium && AppConfig.freeGuideLimit >= 0) {
      context.go('/premium');
      return;
    }
    final items = <QuizItem>[];
    for (final q in set.questions) {
      // MCQ + stored key only. The same verbatim text goes in both
      // language fields: it is the guide text as-is, not a
      // translation claim.
      if (q.questionType == 'mcq' && q.hasKey) {
        items.add(QuizItem(
          id: q.id,
          questionBn: q.questionText,
          questionEn: q.questionText,
          options: q.options,
          correctIndex: q.correctOptionIndex!,
        ));
      }
    }
    if (items.isEmpty || !context.mounted) return;
    PracticeSession.modelTestId = 'guide:${set.setId}';
    PracticeSession.modelSubject = subject;
    PracticeSession.modelChapter = '';
    PracticeSession.modelItems = items;
    PracticeSession.modelMinutes = 15;
    context.go('/model-test-exam');
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? guideBankStringsBn : guideBankStringsEn;
        final subject = PracticeSession.selectedSubject;
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/practice'),
            ),
            title: Text(
              '${s['modelTestsTitle']!} · ${subjectNameFor(subject, bn)}',
            ),
          ),
          body: FutureBuilder<List<dynamic>>(
            // Sets are class-keyed: resolve the saved class first
            // instead of taking the service's documented fallback.
            future: Future.wait([
              resolveSchoolClass()
                  .then((c) => guideBankService.cachedSets(
                        subject,
                        schoolClass: c,
                      )),
              billingService.isPremium(),
            ]),
            builder: (context, snap) {
              if (!snap.hasData) {
                return Center(child: Text(s['loading']!));
              }
              final sets = snap.data![0] as List<GuideModelSet>;
              final isPremium = snap.data![1] as bool;
              if (sets.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    s['modelTestsEmpty']!,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final set in sets) ...[
                    PracticeCard(
                      title: set.setId,
                      subtitle:
                          '${numStr(set.questions.length, bn)}'
                          '${s['questionsSuffix']!} · '
                          '${numStr(set.keyedCount, bn)}'
                          '${s['keyedSuffix']!}'
                          '${set.unkeyedCount > 0 ? ' · '
                              '${numStr(set.unkeyedCount, bn)}'
                              '${s['unkeyedExcludedSuffix']!}' : ''}',
                      icon: set.keyedCount == 0
                          ? Icons.lock
                          : Icons.assignment,
                      trailing: ElevatedButton(
                        onPressed: set.keyedCount == 0
                            ? null
                            : () => _start(
                                  context,
                                  subject,
                                  set,
                                  isPremium,
                                ),
                        child: Text(s['modelTestStart']!),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }
}
