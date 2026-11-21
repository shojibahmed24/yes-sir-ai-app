// Progress screen extras (S3): overall score ring and per-subject
// breakdown, both computed from the REAL attempts the screen already
// loads. No invented subject rows: a subject appears only when it has
// at least one answered question.
import 'package:flutter/material.dart';
import '../../practice/practice_store.dart';
import '../../learn/widgets/digits.dart';
import '../../learn/widgets/mock_data.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';

class ProgressScoreCard extends StatelessWidget {
  const ProgressScoreCard({
    super.key,
    required this.bn,
    required this.score,
    required this.runs,
    required this.answered,
    required this.title,
    required this.runsLabel,
    required this.questionsLabel,
  });
  final bool bn;
  final int score;
  final int runs;
  final int answered;
  final String title;
  final String runsLabel;
  final String questionsLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Sp.md),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: (score / 100).clamp(0.0, 1.0),
                    strokeWidth: 7,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    color: score >= 60 ? AppTheme.success : AppTheme.amber,
                  ),
                  Text(
                    '${numStr(score, bn)}%',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(width: Sp.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    '${numStr(runs, bn)} $runsLabel · '
                    '${numStr(answered, bn)} $questionsLabel',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProgressPeriodSection extends StatefulWidget {
  const ProgressPeriodSection({
    super.key,
    required this.bn,
    required this.attempts,
    required this.title,
    required this.runsLabel,
    required this.questionsLabel,
    required this.bySubjectTitle,
    required this.emptyLabel,
    required this.last7,
    required this.last30,
  });
  final bool bn;
  final List<Attempt> attempts;
  final String title;
  final String runsLabel;
  final String questionsLabel;
  final String bySubjectTitle;
  final String emptyLabel;
  final String last7;
  final String last30;

  @override
  State<ProgressPeriodSection> createState() => _ProgressPeriodSectionState();
}

class _ProgressPeriodSectionState extends State<ProgressPeriodSection> {
  int _days = 7;

  bool _inWindow(Attempt a, DateTime today) {
    final p = a.date.split('-');
    if (p.length < 3) return false;
    final d = DateTime(
      int.tryParse(p[0]) ?? 0,
      int.tryParse(p[1]) ?? 1,
      int.tryParse(p[2]) ?? 1,
    );
    return today.difference(d).inDays < _days;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final rows = widget.attempts
        .where((a) => _inWindow(a, today))
        .toList(growable: false);
    var correct = 0, total = 0;
    for (final a in rows) {
      correct += a.correct;
      total += a.total;
    }
    final score = total == 0 ? 0 : ((correct / total) * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<int>(
          segments: [
            ButtonSegment(value: 7, label: Text(widget.last7)),
            ButtonSegment(value: 30, label: Text(widget.last30)),
          ],
          selected: {_days},
          showSelectedIcon: false,
          onSelectionChanged: (v) => setState(() => _days = v.first),
        ),
        const SizedBox(height: Sp.sm),
        ProgressScoreCard(
          bn: widget.bn,
          score: score,
          runs: rows.length,
          answered: total,
          title: widget.title,
          runsLabel: widget.runsLabel,
          questionsLabel: widget.questionsLabel,
        ),
        const SizedBox(height: Sp.md),
        ProgressSubjectBreakdown(
          bn: widget.bn,
          attempts: rows,
          title: widget.bySubjectTitle,
          emptyLabel: widget.emptyLabel,
        ),
      ],
    );
  }
}

class ProgressSubjectBreakdown extends StatelessWidget {
  const ProgressSubjectBreakdown({
    super.key,
    required this.bn,
    required this.attempts,
    required this.title,
    required this.emptyLabel,
  });
  final bool bn;
  final List<Attempt> attempts;
  final String title;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final bySubject = <String, List<int>>{}; // subject -> [correct, total]
    for (final a in attempts) {
      if (a.subject.isEmpty || a.total <= 0) continue;
      final row = bySubject.putIfAbsent(a.subject, () => [0, 0]);
      row[0] += a.correct;
      row[1] += a.total;
    }
    final rows = bySubject.entries.toList()
      ..sort((a, b) => b.value[1].compareTo(a.value[1]));
    final top = rows.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: Sp.sm),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(Sp.md),
            child: top.isEmpty
                ? Text(emptyLabel)
                : Column(
                    children: [
                      for (final e in top) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                subjectNameFor(e.key, bn),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            Text(
                              '${((e.value[0] / e.value[1]) * 100).round()}%',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (e.value[0] / e.value[1]).clamp(0.0, 1.0),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
