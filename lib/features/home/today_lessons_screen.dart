// Route: /home/today-lessons — detail behind Home's first stat.
//
// Lists TODAY's lessons only, from LearnStore.lessonsTodayList().
// Two key shapes are accepted:
//   4 parts  'subject|chapter|page|problem'  (old textbook flow)
//   3 parts  'subject|chapter|lesson'        (guide flow, D6)
// The guide shape used to be skipped by the strict 4-part parser, so
// Home said "2 lessons opened" while this screen said "none".
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/home_strings.dart';
import '../../theme/themed_scaffold.dart';
import '../learn/learn_store.dart';
import '../learn/lesson_selection.dart';
import '../learn/widgets/digits.dart';
import '../learn/widgets/mock_data.dart';
import 'open_last_study.dart';
import '../learn/last_study.dart';

/// One row of today's lessons: a guide lesson or a textbook page.
class TodayLesson {
  const TodayLesson({
    required this.subject,
    required this.chapter,
    this.lesson,
    this.page,
    this.problem,
  });

  final String subject;
  final int chapter;
  final String? lesson;
  final int? page;
  final int? problem;

  bool get isGuide => page == null || page! < 1;
}

/// Parses both key shapes. Anything malformed -> null (skipped, never
/// invented).
TodayLesson? parseTodayLessonKey(String key) {
  final parts = key.split('|');
  if (parts.length == 3 && parts[0].isNotEmpty) {
    final chapter = int.tryParse(parts[1]);
    if (chapter == null || chapter < 1) return null;
    return TodayLesson(
      subject: parts[0],
      chapter: chapter,
      lesson: parts[2].isEmpty ? null : parts[2],
    );
  }
  if (parts.length != 4 || parts[0].isEmpty) return null;
  final chapter = int.tryParse(parts[1]);
  final page = int.tryParse(parts[2]);
  final problem = int.tryParse(parts[3]);
  if (chapter == null || page == null || problem == null) return null;
  if (chapter < 1 || page < 1 || problem < 1) return null;
  return TodayLesson(
    subject: parts[0],
    chapter: chapter,
    page: page,
    problem: problem,
  );
}

class TodayLessonsScreen extends StatefulWidget {
  const TodayLessonsScreen({super.key});
  @override
  State<TodayLessonsScreen> createState() => _TodayLessonsScreenState();
}

class _TodayLessonsScreenState extends State<TodayLessonsScreen> {
  late final Future<List<TodayLesson>> _future;

  @override
  void initState() {
    super.initState();
    _future = LearnStore.lessonsTodayList().then(
      (keys) => keys.map(parseTodayLessonKey).whereType<TodayLesson>().toList(),
    );
  }

  String _rowText(TodayLesson l, bool bn) {
    final chapterWord = bn ? 'অধ্যায়' : 'Chapter';
    final head =
        '${subjectNameFor(l.subject, bn)} · $chapterWord ${numStr(l.chapter, bn)}';
    if (l.lesson != null && l.lesson!.isNotEmpty) {
      return '$head · ${l.lesson}';
    }
    if (l.page != null && l.problem != null) {
      final pageWord = bn ? 'পৃষ্ঠা' : 'Page';
      final questionWord = bn ? 'প্রশ্ন' : 'Question';
      return '$head · $pageWord ${numStr(l.page!, bn)} · '
          '$questionWord ${numStr(l.problem!, bn)}';
    }
    return head;
  }

  Future<void> _open(TodayLesson l) async {
    if (l.isGuide) {
      await openLastStudy(
        context,
        LastStudy(subject: l.subject, chapter: l.chapter, lesson: l.lesson),
      );
      return;
    }
    LessonSelectionHolder.set(
      LessonSelection(
        subject: l.subject,
        chapter: l.chapter,
        page: l.page!,
        problem: l.problem!,
      ),
    );
    context.go('/lesson');
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? homeStringsBn : homeStringsEn;
        return ThemedScaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/home'),
            ),
            title: Text(s['todayLessonsTitle']!),
          ),
          body: FutureBuilder<List<TodayLesson>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final lessons = snap.data ?? const [];
              if (lessons.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      s['todayLessonsEmpty']!,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.go('/search-flow'),
                      child: Text(s['startFromSearch']!),
                    ),
                  ],
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: lessons.length,
                itemBuilder: (context, i) {
                  final lesson = lessons[i];
                  return Card(
                    child: ListTile(
                      title: Text(
                        _rowText(lesson, bn),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _open(lesson),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
