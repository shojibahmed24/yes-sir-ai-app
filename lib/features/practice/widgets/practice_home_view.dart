// Practice home body (Phase 4): MCQ practice and Model Tests are
// separate sections, each with its own entry. Kept out of
// practice_screen.dart so the screen stays under the 250-line cap.
import 'package:flutter/material.dart';

import '../../../core/services/progress_service.dart';
import '../../../theme/app_tokens.dart';
import '../../../theme/widgets/section_header.dart';
import 'practice_widgets.dart';

class PracticeHomeView extends StatelessWidget {
  const PracticeHomeView({
    super.key,
    required this.s,
    required this.bangla,
    required this.sum,
    required this.selectedSubject,
    required this.startingDaily,
    required this.startingSubject,
    required this.onDaily,
    required this.onWeak,
    required this.onSubject,
    required this.onGuideModel,
    required this.onBankModel,
  });

  final Map<String, String> s;
  final bool bangla;
  final ProgressSummary sum;
  final String selectedSubject;
  final bool startingDaily;
  final String? startingSubject;
  final VoidCallback onDaily;
  final VoidCallback onWeak;
  final ValueChanged<String> onSubject;
  final VoidCallback onGuideModel;
  final VoidCallback onBankModel;

  @override
  Widget build(BuildContext context) {
    final weakItems = sum.weakItems;
    final weak = sum.weakChapters.isEmpty ? null : sum.weakChapters.first;
    final countText = bangla
        ? '${weakItems.length}${s['wrongQuestions']!}'
        : '${weakItems.length} ${s['wrongQuestions']!}';
    final weakSub = weakItems.isEmpty
        ? (weak == null ? s['weakNone']! : s['weakUnavailable']!)
        : (weak == null ? countText : '$countText · ${weak.label(bangla)}');

    return ListView(
      padding: const EdgeInsets.all(Sp.lg),
      children: [
        SectionHeader(title: s['practiceSection']!),
        const SizedBox(height: Sp.sm),
        PracticeCard(
          title: s['dailyQuiz']!,
          subtitle: '${s['dailyCount']!} · ${s['bankNote']!}',
          icon: Icons.timer,
          trailing: ElevatedButton(
            onPressed: startingDaily ? null : onDaily,
            child: startingDaily
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(s['startQuiz']!),
          ),
        ),
        if (startingDaily)
          Padding(
            padding: const EdgeInsets.only(top: Sp.sm),
            child: Text(
              s['preparingGuide']!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        const SizedBox(height: Sp.md),
        PracticeCard(
          title: s['weakTitle']!,
          subtitle: weakSub,
          icon: Icons.psychology,
          trailing: TextButton(
            onPressed: weakItems.isEmpty ? null : onWeak,
            child: Text(s['weakStart']!),
          ),
        ),
        const SizedBox(height: Sp.xl),
        SectionHeader(title: s['bySubject']!),
        const SizedBox(height: Sp.sm),
        PracticeCard(
          title: s['maths']!,
          subtitle: selectedSubject == 'math' ? s['selected']! : '',
          icon: Icons.calculate,
          onTap: startingSubject != null ? null : () => onSubject('math'),
          trailing: startingSubject == 'math'
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
        ),
        const SizedBox(height: Sp.md),
        PracticeCard(
          title: s['science']!,
          subtitle: selectedSubject == 'science' ? s['selected']! : '',
          icon: Icons.biotech,
          onTap: startingSubject != null ? null : () => onSubject('science'),
          trailing: startingSubject == 'science'
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
        ),
        if (startingSubject != null)
          Padding(
            padding: const EdgeInsets.only(top: Sp.sm),
            child: Text(
              s['preparingGuide']!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        const SizedBox(height: Sp.xl),
        SectionHeader(title: s['modelSection']!),
        const SizedBox(height: Sp.sm),
        PracticeCard(
          title: s['guideModelTitle']!,
          subtitle: s['guideModelSub']!,
          icon: Icons.assignment_turned_in_outlined,
          onTap: onGuideModel,
        ),
        const SizedBox(height: Sp.md),
        PracticeCard(
          title: s['bankModelTitle']!,
          subtitle: s['bankModelSub']!,
          icon: Icons.assignment_outlined,
          onTap: onBankModel,
        ),
        const SizedBox(height: Sp.xl),
        Text(
          '${s['avg']!}: ${sum.averageScore}% · ${s['done']!}: ${sum.totalAttempts}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: Sp.sm),
        ProgressBar(value: sum.averageScore / 100),
      ],
    );
  }
}
