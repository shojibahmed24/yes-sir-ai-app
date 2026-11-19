// Lesson hub: the single place where a lesson's content types are
// separated — MCQ, creative (with stimulus), short, model test and
// board. Each card opens the existing list/set flow, so list paging,
// answer rendering and verbatim-first rules stay untouched.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/language_provider.dart';
import '../../l10n/pages/lesson_hub_strings.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import '../../theme/themed_scaffold.dart';
import '../practice/practice_store.dart';
import 'lesson_hub_route.dart';
import 'search_flow_types.dart';
import 'widgets/digits.dart';
import 'widgets/mock_data.dart';

class LessonHubScreen extends StatelessWidget {
  const LessonHubScreen({
    super.key,
    required this.subjectId,
    required this.schoolClass,
    required this.chapter,
    this.lesson,
    this.lessonTitle = '',
  });

  final String subjectId;
  final int schoolClass;
  final int chapter;
  final String? lesson;
  final String lessonTitle;

  String get _hubUrl => lessonHubRoute(
    subject: subjectId,
    schoolClass: schoolClass,
    chapter: chapter,
    lesson: lesson,
    title: lessonTitle,
  );

  String _listUrl(SearchFlowType type) => Uri(
    path: '/search-flow-list',
    queryParameters: {
      'subject': subjectId,
      'class': '$schoolClass',
      'source': 'guide',
      'chapter': '$chapter',
      'type': type.name,
      if (lesson != null) 'lesson': lesson,
      'returnTo': _hubUrl,
    },
  ).toString();

  String get _boardUrl => Uri(
    path: '/search-flow-board',
    queryParameters: {
      'subject': subjectId,
      'class': '$schoolClass',
      'returnTo': _hubUrl,
    },
  ).toString();

  void _openModel(BuildContext context) {
    PracticeSession.selectedSubject = subjectId;
    context.go('/guide-model-tests');
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? lessonHubStringsBn : lessonHubStringsEn;
        return ThemedScaffold(
          appBar: AppBar(title: Text(s['title']!)),
          body: ListView(
            padding: const EdgeInsets.all(Sp.xl),
            children: [
              _Header(
                subject: subjectNameFor(subjectId, bn),
                chapter: chapter,
                title: lessonTitle.isEmpty ? s['allLessons']! : lessonTitle,
                chapterLabel: s['chapterLabel']!,
                bn: bn,
              ),
              const SizedBox(height: Sp.xl),
              Text(
                s['chooseContent']!,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: Sp.md),
              _HubCard(
                icon: Icons.quiz_outlined,
                title: s['mcq']!,
                subtitle: s['mcqSub']!,
                accent: Theme.of(context).colorScheme.primary,
                onTap: () => context.go(_listUrl(SearchFlowType.mcq)),
              ),
              _HubCard(
                icon: Icons.edit_note_rounded,
                title: s['creative']!,
                subtitle: s['creativeSub']!,
                accent: AppTheme.secondary,
                onTap: () => context.go(_listUrl(SearchFlowType.creative)),
              ),
              _HubCard(
                icon: Icons.short_text_rounded,
                title: s['short']!,
                subtitle: s['shortSub']!,
                accent: AppTheme.success,
                onTap: () => context.go(_listUrl(SearchFlowType.short)),
              ),
              _HubCard(
                icon: Icons.assignment_outlined,
                title: s['model']!,
                subtitle: s['modelSub']!,
                accent: AppTheme.amber,
                onTap: () => _openModel(context),
              ),
              _HubCard(
                icon: Icons.verified_outlined,
                title: s['board']!,
                subtitle: s['boardSub']!,
                accent: AppTheme.primaryDark,
                onTap: () => context.go(_boardUrl),
              ),
              const SizedBox(height: Sp.lg),
              Text(s['note']!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.subject,
    required this.chapter,
    required this.title,
    required this.chapterLabel,
    required this.bn,
  });
  final String subject;
  final int chapter;
  final String title;
  final String chapterLabel;
  final bool bn;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Sp.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subject, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: Sp.xs),
            Text(
              '$chapterLabel ${numStr(chapter, bn)} · $title',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.sm),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(Rad.xl),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(Sp.lg),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(Rad.md),
                  ),
                  child: Icon(icon, color: accent, size: IconSize.md),
                ),
                const SizedBox(width: Sp.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: IconSize.sm),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
