// Route: /model-test-results. Real score + per-question review
// (your answer vs correct, skipped marked) + time used, all from the
// just-finished run or the last saved model attempt. Saved to progress
// by the exam screen before navigating here. Batch 2 (item 5): the
// run's flagged question ids (Attempt.flagged) are shown as a summary
// above the review list and marked on each flagged question's card.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yes_sir_ai/core/models/backend_models.dart';
import 'package:yes_sir_ai/core/services/practice_service.dart';
import 'package:yes_sir_ai/features/practice/practice_store.dart';
import 'package:yes_sir_ai/features/practice/widgets/practice_widgets.dart';
import 'package:yes_sir_ai/l10n/language_provider.dart';
import 'package:yes_sir_ai/l10n/pages/model_test_results_strings.dart';

class ModelTestResultsScreen extends StatelessWidget {
  const ModelTestResultsScreen({super.key});

  Future<(Attempt?, List<QuizItem>)> _load() async {
    final session = PracticeSession.lastAttempt;
    if (session != null && session.kind == 'model') {
      return (session, PracticeSession.lastItems);
    }
    final attempts = await PracticeStore.loadAttempts();
    final models = attempts.where((a) => a.kind == 'model').toList();
    if (models.isEmpty) return (null, <QuizItem>[]);
    final last = models.last;
    final test = practiceService.modelTests().where((t) => t.id == last.testId).toList();
    return (last, test.isEmpty ? practiceService.modelMath() : test.first.items);
  }

  String _fmt(int sec) => '${(sec ~/ 60).toString().padLeft(2, '0')}:${(sec % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(valueListenable: languageNotifier, builder: (context, locale, _) {
      final s = locale.languageCode == 'bn' ? modelTestResultsStringsBn : modelTestResultsStringsEn;
      final bangla = locale.languageCode == 'bn';
      // Phase 17 (L3): consume the one-shot time-up flag here, so
      // the message survives navigation and is shown on this screen.
      // Cleared at once: revisiting results later must not re-show it.
      final timeUp = PracticeSession.timeUpAutoSubmit;
      PracticeSession.timeUpAutoSubmit = false;
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/practice'),
          ),
          title: Text(s['title']!),
        ),
        body: FutureBuilder<(Attempt?, List<QuizItem>)>(future: _load(), builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final attempt = snap.data!.$1;
          final items = snap.data!.$2;
          if (attempt == null) {
            return ListView(padding: const EdgeInsets.all(16), children: [
              Text(s['noResult']!, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8), Text(s['noResultSub']!),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => context.go('/model-tests'), child: Text(s['retake']!)),
            ]);
          }
          final skipped = attempt.total - attempt.answers.length;
          final wrong = attempt.answers.length - attempt.correct;
          final weak = <String>{};
          for (final q in items) {
            final a = attempt.answers[q.id];
            if (a != null && a != q.correctIndex) weak.add(practiceService.chapterOf(q.id, bangla));
          }
          return ListView(padding: const EdgeInsets.all(16), children: [
            if (timeUp)
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        const Icon(Icons.timer_off),
                        const SizedBox(width: 8),
                        Expanded(child: Text(s['timeUp']!)),
                      ]))),
            if (timeUp) const SizedBox(height: 12),
            ScoreHeader(score: '${attempt.correct} / ${attempt.total}', total: '${attempt.percent}% • +${attempt.xp} XP', message: s['message']!),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: PracticeCard(title: '${s['correct']!}: ${attempt.correct}')),
              const SizedBox(width: 8),
              Expanded(child: PracticeCard(title: '${s['wrong']!}: $wrong')),
              const SizedBox(width: 8),
              Expanded(child: PracticeCard(title: '${s['skipped']!}: $skipped')),
            ]),
            const SizedBox(height: 12),
            Text("${s['timeUsed']!}: ${_fmt(attempt.seconds)}", style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            ProgressBar(value: attempt.percent / 100),
            const SizedBox(height: 16),
            Text(s['weakTitle']!, style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 8),
            if (weak.isEmpty) Text(s['allCorrect']!)
            else for (final w in weak) Padding(padding: const EdgeInsets.only(bottom: 8),
                child: PracticeCard(title: w, icon: Icons.warning_amber, trailing: ElevatedButton(onPressed: () => context.go('/books/viewer'), child: Text(s['readAgain']!)))),
            const SizedBox(height: 16),
            if (attempt.flagged.isNotEmpty) ...[
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(
                  "${s['flaggedTitle']!}: ${[for (int i = 0; i < items.length; i++) if (attempt.flagged.contains(items[i].id)) '${i + 1}'].join(', ')}"))),
              const SizedBox(height: 16),
            ],
            Text(s['reviewTitle']!, style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 8),
            for (final q in items) Padding(padding: const EdgeInsets.only(bottom: 8), child: () {
              final a = attempt.answers[q.id];
              final flaggedMark = attempt.flagged.contains(q.id) ? " · ${s['flaggedLabel']!}" : '';
              final sub = (a == null
                  ? s['skippedLabel']!
                  : "${s['yourAnswer']!}: ${q.options[a]} · ${s['correctAnswer']!}: ${q.options[q.correctIndex]}") + flaggedMark;
              return PracticeCard(title: bangla ? q.questionBn : q.questionEn, subtitle: sub,
                  icon: a == null ? Icons.remove_circle_outline : (a == q.correctIndex ? Icons.check_circle : Icons.cancel));
            }()),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () {
              final test = practiceService.modelTests().where((t) => t.id == attempt.testId).toList();
              if (test.isNotEmpty) {
                PracticeSession.modelTestId = test.first.id;
                PracticeSession.modelSubject = test.first.subject;
                PracticeSession.modelItems = test.first.items;
                PracticeSession.modelMinutes = test.first.minutes;
                context.go('/model-test-exam');
              } else {
                context.go('/model-tests');
              }
            }, child: Text(s['retake']!)),
            const SizedBox(height: 8),
            TextButton(onPressed: () => context.go('/home'), child: Text(s['home']!)),
          ]);
        }),
      );
    });
  }
}
