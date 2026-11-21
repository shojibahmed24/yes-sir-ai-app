// Lesson hub: the single place where a lesson's content types are
// separated — MCQ, creative (with stimulus), short, model test and
// board. Each card opens the existing list/set flow, so list paging,
// answer rendering and verbatim-first rules stay untouched.
//
// B12: the question types are DATA-DRIVEN. Counts come from the same
// server (subject, class, chapter, lesson, type) totals the picker
// shows, so a type with 0 questions is not offered (it used to open
// an empty list). Unknown counts (old server / failed call) keep the
// card, because unknown is never "no questions". No per-subject code:
// the rule holds for every subject and lesson.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/guide_flow_count_service.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/lesson_hub_strings.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import '../../theme/themed_scaffold.dart';
import '../practice/practice_store.dart';
import 'lesson_hub_route.dart';
import 'search_flow_types.dart';
import 'widgets/digits.dart';
import 'widgets/lesson_hub_widgets.dart';
import 'widgets/mock_data.dart';

class LessonHubScreen extends StatefulWidget {
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

  @override
  State<LessonHubScreen> createState() => _LessonHubScreenState();
}

class _LessonHubScreenState extends State<LessonHubScreen> {
  Map<SearchFlowType, int?>? _counts;

  /// Question-type cards this hub can offer; model test and board
  /// are separate flows below.
  static const _types = [
    SearchFlowType.mcq,
    SearchFlowType.creative,
    SearchFlowType.short,
  ];

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    try {
      final out = await guideFlowCountService.countAll(
        subject: widget.subjectId,
        schoolClass: widget.schoolClass,
        chapter: widget.chapter,
        lesson: widget.lesson,
        types: _types,
      );
      if (!mounted) return;
      setState(() => _counts = out);
    } catch (_) {
      // Counts unknown: every card stays visible.
      if (mounted) setState(() => _counts = const {});
    }
  }

  String get _hubUrl => lessonHubRoute(
    subject: widget.subjectId,
    schoolClass: widget.schoolClass,
    chapter: widget.chapter,
    lesson: widget.lesson,
    title: widget.lessonTitle,
  );

  String _listUrl(SearchFlowType type) => Uri(
    path: '/search-flow-list',
    queryParameters: {
      'subject': widget.subjectId,
      'class': '${widget.schoolClass}',
      'source': 'guide',
      'chapter': '${widget.chapter}',
      'type': type.name,
      if (widget.lesson != null) 'lesson': widget.lesson!,
      'returnTo': _hubUrl,
    },
  ).toString();

  String get _boardUrl => Uri(
    path: '/search-flow-board',
    queryParameters: {
      'subject': widget.subjectId,
      'class': '${widget.schoolClass}',
      'returnTo': _hubUrl,
    },
  ).toString();

  /// Cards to show: a 0 count hides the card, null (unknown) keeps it.
  List<SearchFlowType> _visibleTypes() =>
      _types.where((t) => _counts == null || (_counts![t] ?? 1) > 0).toList();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? lessonHubStringsBn : lessonHubStringsEn;
        final types = _visibleTypes();
        return ThemedScaffold(
          appBar: AppBar(title: Text(s['title']!)),
          body: ListView(
            padding: const EdgeInsets.all(Sp.xl),
            children: [
              LessonHubHeader(
                subject: subjectNameFor(widget.subjectId, bn),
                chapter: widget.chapter,
                title: widget.lessonTitle.isEmpty
                    ? s['allLessons']!
                    : widget.lessonTitle,
                chapterLabel: s['chapterLabel']!,
                bn: bn,
              ),
              const SizedBox(height: Sp.xl),
              Text(
                s['chooseContent']!,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: Sp.md),
              if (_counts != null && types.isEmpty)
                LessonHubEmpty(
                  s: s,
                  onAllLessons: () => context.go(
                    lessonHubRoute(
                      subject: widget.subjectId,
                      schoolClass: widget.schoolClass,
                      chapter: widget.chapter,
                      title: '',
                    ),
                  ),
                )
              else ...[
                for (final t in types)
                  LessonHubCard(
                    icon: LessonHubTypeStyle.of(t).icon,
                    title: s[LessonHubTypeStyle.of(t).titleKey]!,
                    // Known count -> exact number; unknown -> the
                    // type's own description (never a guess).
                    subtitle: _counts?[t] != null
                        ? s['countSuffix']!.replaceAll(
                            '{n}',
                            numStr(_counts![t]!, bn),
                          )
                        : s[LessonHubTypeStyle.of(t).subKey]!,
                    accent: LessonHubTypeStyle.of(t).accent,
                    onTap: () => context.go(_listUrl(t)),
                  ),
                if (_counts == null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Sp.sm),
                    child: Text(
                      s['loadingCounts']!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
              LessonHubCard(
                icon: Icons.assignment_outlined,
                title: s['model']!,
                subtitle: s['modelSub']!,
                accent: AppTheme.amber,
                onTap: () {
                  PracticeSession.selectedSubject = widget.subjectId;
                  context.go('/guide-model-tests');
                },
              ),
              LessonHubCard(
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
