// Route: /home — HomeDashboard, Stitch home_dashboard_1 + _2.
// REAL behaviour: hero continues the LAST saved lesson (or Search
// when none exists); stats are LearnStore lesson/chapter counts
// plus LocalStore's saved count (the Saved/Profile source — 0
// fresh, never invented); the subject grid uses the profile
// class. NOTE: no bKash here — deliberately absent, Play only.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/demo_banner.dart';
import '../../core/widgets/double_back_exit.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/home_strings.dart';
import '../learn/lesson_selection.dart';
import 'home_data.dart';
import '../learn/widgets/digits.dart';
import '../learn/widgets/mock_data.dart';
import 'widgets/home_top_bar.dart';
import 'widgets/home_hero_card.dart';
import 'widgets/home_stats_row.dart';
import 'widgets/home_subject_grid.dart';
import 'widgets/home_search_field.dart';
import 'widgets/home_bottom_nav.dart';
import '../../theme/themed_scaffold.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _subjectName(String id, bool bn) => subjectNameFor(id, bn);

  // Class stamp: saved profile class when available; null = no
  // class known — downstream resolves from it, never a silent 6.
  LessonSelection? _parseKey(String? key, int? schoolClass) {
    if (key == null) return null;
    final p = key.split('|');
    if (p.length != 4) return null;
    return LessonSelection(
      subject: p[0],
      chapter: int.tryParse(p[1]) ?? 1,
      page: int.tryParse(p[2]) ?? 1,
      problem: int.tryParse(p[3]) ?? 1, schoolClass: schoolClass,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? homeStringsBn : homeStringsEn;
        return ThemedScaffold(
          // Phase 6 (H1): home is a tab root; system back must
          // not silently exit, so DoubleBackExit asks twice.
          body: DoubleBackExit(
            message: s['pressBackAgain']!,
            child: SafeArea(
              child: FutureBuilder<HomeData>(
                future: loadHomeData(),
                builder: (context, snap) {
                  final data = snap.data;
                  final sum = data?.summary;
                  final last = _parseKey(sum?.lastLessonKey, data?.schoolClass);
                  final heroSubject = last == null
                      ? s['noLessonYet']!
                      : '${_subjectName(last.subject, bn)} · '
                            '${bn ? 'অধ্যায়' : 'Chapter'} '
                            '${numStr(last.chapter, bn)} · '
                            '${bn ? 'পৃষ্ঠা' : 'Page'} '
                            '${numStr(last.page, bn)}';
                  final heroTopic = last == null
                      ? s['startFromSearch']!
                      : '${bn ? 'প্রশ্ন' : 'Question'} '
                            '${numStr(last.problem, bn)}';
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const DemoBanner(),
                        HomeTopBar(
                          greeting: s['greeting']!,
                          classChip: s['classChip']!,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          s['todayGoal']!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        // Phase 16 (M1): typed text goes to /search
                        // as ?q= via HomeSearchField, not discarded.
                        HomeSearchField(hint: s['searchHint']),
                        const SizedBox(height: 16),
                        HomeHeroCard(
                          title: s['continueLearning']!,
                          subject: heroSubject,
                          topic: heroTopic,
                          progressLabel: last == null
                              ? s['noDataYet']!
                              : '${numStr(sum?.lessonsOpened ?? 0, bn)} '
                                    '${s['lessonsOpened']!}',
                          continueLabel: s['continue']!,
                          onContinue: () {
                            if (last != null) {
                              LessonSelectionHolder.set(last);
                              context.go('/lesson');
                            } else {
                              context.go('/search');
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        // Batch 2, item 3: saved = LocalStore (the
                        // Saved/Profile source, not LearnStore's
                        // diverging area2 list); chapters = opened.
                        HomeStatsRow(
                          todayLabel: s['lessonsToday']!,
                          chaptersLabel: s['chaptersOpened']!,
                          savedLabel: s['savedCount']!,
                          values: [
                            sum?.lessonsToday ?? 0,
                            sum?.chaptersOpened ?? 0,
                            data?.savedCount ?? 0,
                          ],
                          bangla: bn,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              s['subjects']!,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            TextButton(
                              onPressed: () => context.go('/home/subjects'),
                              child: Text(s['seeAll']!),
                            ),
                          ],
                        ),
                        // Batch 2, item 3: grid uses the profile
                        // class, never hardcoded 6; loading shows
                        // the loading line, not choose-class state.
                        if (data == null)
                          Text(s['loadingSubjects']!)
                        else
                          HomeSubjectGrid(
                            bn: bn,
                            schoolClass: data.schoolClass,
                            loadingLabel: s['loadingSubjects']!,
                            noSubjectsLabel: s['noSubjects']!,
                            chooseClassTitle: s['chooseClassTitle']!,
                            chooseClassBody: s['chooseClassBody']!,
                            chooseClassAction: s['chooseClassAction']!,
                          ),
                        const SizedBox(height: 20),
                        Text(
                          s['weakChapters']!,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        if (last == null)
                          Text(s['noWeakYet']!)
                        else
                          Card(
                            child: ListTile(
                              title: Text(
                                '${_subjectName(last.subject, bn)} · '
                                '${bn ? 'অধ্যায়' : 'Chapter'} '
                                '${numStr(last.chapter, bn)}',
                              ),
                              subtitle: Text(s['practiceAgain']!),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                LessonSelectionHolder.set(last);
                                context.go('/lesson');
                              },
                            ),
                          ),
                        const SizedBox(height: 12),
                        Text(
                          s['recommendations']!,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        if (last == null)
                          Text(s['noDataYet']!)
                        else
                          Card(
                            child: ListTile(
                              title: Text(heroTopic),
                              subtitle: Text(heroSubject),
                              onTap: () {
                                LessonSelectionHolder.set(last);
                                context.go('/lesson');
                              },
                            ),
                          ),
                        const SizedBox(height: 12),
                        Text(
                          s['recentBooks']!,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        if (sum == null || sum.recentBooks.isEmpty)
                          Text(s['noRecentBook']!)
                        else
                          ...sum.recentBooks.map((e) {
                            final parts = e.split('|');
                            final title = bn && parts.length > 1
                                ? parts[1]
                                : (parts.length > 2 ? parts[2] : e);
                            return Card(
                              child: ListTile(
                                title: Text(title),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  if (parts.isNotEmpty) {
                                    BookSelectionHolder.set(
                                      parts[0],
                                      'class6-${parts[0]}-${bn ? 'bn' : 'en'}',
                                      1,
                                    );
                                  }
                                  context.go('/books/viewer');
                                },
                              ),
                            );
                          }),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          bottomNavigationBar: HomeBottomNav(
            current: 0,
            labels: [
              s['home']!,
              s['search']!,
              s['practice']!,
              s['progress']!,
              s['profile']!,
            ],
          ),
        );
      },
    );
  }
}
