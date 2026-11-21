// Route: /home — HomeDashboard, Stitch home_dashboard_1 + _2.
// REAL behaviour: hero continues the LAST saved lesson (or the
// new search flow when none exists); stats are LearnStore
// lesson/chapter counts
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
import 'home_continue_route.dart';
import 'home_data.dart';
import 'home_design.dart';
import 'home_lower_sections.dart';
import '../learn/widgets/digits.dart';
import '../learn/widgets/mock_data.dart';
import 'widgets/home_top_bar.dart';
import 'widgets/home_hero_card.dart';
import 'widgets/home_stats_row.dart';
import 'widgets/home_dashboard_cards.dart';
import 'widgets/home_dashboard_d4.dart';
import 'widgets/home_dashboard_extra.dart';
import 'widgets/home_subject_grid.dart';
import 'widgets/home_search_field.dart';
import 'widgets/home_bottom_nav.dart';
import '../../theme/themed_scaffold.dart';
import '../../theme/app_tokens.dart';
import '../../theme/staggered_list.dart';
import '../../theme/widgets/section_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // QUICK-LOAD (2026-11-20): ONE load per screen lifetime. A locale
  // or theme rebuild used to re-run loadHomeData() (three storage
  // reads) on every frame rebuild. A fresh /home navigation still
  // reloads, so returning to the tab shows current numbers.
  late final Future<HomeData> _data = loadHomeData();

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
      problem: int.tryParse(p[3]) ?? 1,
      schoolClass: schoolClass,
    );
  }

  static const _bnDays = ['সোম', 'মঙ্গল', 'বুধ', 'বৃহঃ', 'শুক্র', 'শনি', 'রবি'];
  static const _enDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  bool _activeOn(DateTime day, List<String>? dates) {
    for (final raw in dates ?? const <String>[]) {
      final p = raw.split('T').first.split('-');
      if (p.length < 3) continue;
      if (int.tryParse(p[0]) == day.year &&
          int.tryParse(p[1]) == day.month &&
          int.tryParse(p[2]) == day.day) {
        return true;
      }
    }
    return false;
  }

  List<String> _weekdayLabels(bool bn, List<String>? dates) {
    final now = DateTime.now();
    final names = bn ? _bnDays : _enDays;
    return [
      for (var i = 6; i >= 0; i--)
        names[now.subtract(Duration(days: i)).weekday - 1],
    ];
  }

  List<bool> _weekActive(List<String>? dates) {
    final now = DateTime.now();
    return [
      for (var i = 6; i >= 0; i--)
        _activeOn(now.subtract(Duration(days: i)), dates),
    ];
  }

  /// A8: the plan is not the same three rows every day. The quiz row is
  /// always first (streak), then the day's focus rotates (revision /
  /// goal / saved), and the weekly test appears on the weekend.
  List<(String, bool, String)> _planRows(
    Map<String, String> s,
    HomeData? data,
  ) {
    final weekday = DateTime.now().weekday;
    final quizDone = (data?.summary.lessonsToday ?? 0) > 0;
    final weakDone = data?.progress.weakItems.isEmpty ?? true;
    final goalDone = (data?.progress.goalProgress ?? 0) >= 1;
    final savedCount = data?.savedCount ?? 0;
    // Never show the same task twice: the two rotating slots pick from
    // revision / goal / saved, so each weekday gives a distinct pair.
    final savedSlot = weekday.isEven || weekday % 4 == 3;
    return [
      (s['planQuiz']!, quizDone, '/practice'),
      if (weekday.isEven)
        (s['planRevision']!, weakDone, '/practice')
      else
        (s['dailyGoal']!, goalDone, '/today'),
      if (weekday >= DateTime.saturday)
        (s['planTest']!, false, '/guide-model-tests')
      else if (savedSlot)
        (s['qaSaved']!, savedCount == 0, '/saved')
      else
        (s['planRevision']!, weakDone, '/practice'),
    ];
  }

  int _nextMilestone(int streak) {
    for (final m in const [3, 7, 30, 100]) {
      if (streak < m) return m;
    }
    return 100;
  }

  int _daysToSaturday() {
    final now = DateTime.now();
    final delta = (DateTime.saturday - now.weekday + 7) % 7;
    return delta == 0 ? 7 : delta;
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
                future: _data,
                builder: (context, snap) {
                  final data = snap.data;
                  final sum = data?.summary;
                  final last = _parseKey(sum?.lastLessonKey, data?.schoolClass);
                  final heroSubject = last == null
                      ? s['noLessonYet']!
                      : '${subjectNameFor(last.subject, bn)} · '
                            '${bn ? 'অধ্যায়' : 'Chapter'} '
                            '${numStr(last.chapter, bn)} · '
                            '${bn ? 'পৃষ্ঠা' : 'Page'} '
                            '${numStr(last.page, bn)}';
                  final heroTopic = last == null
                      ? s['startFromSearch']!
                      : '${bn ? 'প্রশ্ন' : 'Question'} '
                            '${numStr(last.problem, bn)}';
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(HomeDesign.screenPadding),
                    // One staggered entrance for the first blocks
                    // (hero, search, stats): same motion language as
                    // the subject grid below.
                    child: StaggeredList(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const DemoBanner(),
                        HomeOfflineChip(label: s['offline']!),
                        HomeTopBar(
                          greeting: s['greeting']!,
                          classChip: s['classChip']!,
                          streakDays: data?.progress.streakDays ?? 0,
                          xp: data?.progress.xp ?? 0,
                          streakSuffix: s['streakSuffix']!,
                        ),
                        const SizedBox(height: HomeDesign.tightGap),
                        // Tappable today line: opens the study-plan
                        // screen (real counters only, no invented
                        // minutes).
                        InkWell(
                          onTap: () => context.go('/today'),
                          borderRadius: BorderRadius.circular(Rad.sm),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  s['todayGoal']!,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                size: IconSize.sm,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: HomeDesign.blockGap),
                        // Phase 16 (M1): typed text goes to /search
                        // as ?q= via HomeSearchField, not discarded.
                        HomeSearchField(hint: s['searchHint']),
                        const SizedBox(height: HomeDesign.blockGap),
                        HomeHeroCard(
                          title: s['continueLearning']!,
                          subject: heroSubject,
                          topic: heroTopic,
                          progressLabel: last == null
                              ? s['noDataYet']!
                              : '${numStr(sum?.lessonsOpened ?? 0, bn)} '
                                    '${s['lessonsOpened']!}',
                          continueLabel: s['continue']!,
                          // Continue opens the NEW search flow
                          // (subject/class prefilled when known),
                          // never the old /lesson or /search
                          // screens that dead-end class 9.
                          onContinue: () => context.go(homeContinueRoute(last)),
                        ),
                        const SizedBox(height: HomeDesign.blockGap),
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
                        const SizedBox(height: HomeDesign.sectionGap),
                        HomeGoalCard(
                          bn: bn,
                          doneMinutes: data?.progress.todayMinutes ?? 0,
                          goalMinutes: data?.progress.goalMinutes ?? 0,
                          title: s['dailyGoal']!,
                          doneLabel: s['minutesWord']!,
                          setGoalLabel: s['setGoal']!,
                        ),
                        const SizedBox(height: HomeDesign.blockGap),
                        HomeQuickActions(
                          labels: [
                            s['qaSearch']!,
                            s['qaPractice']!,
                            s['qaTest']!,
                            s['qaSaved']!,
                            s['qaAskAi']!,
                          ],
                        ),
                        const SizedBox(height: HomeDesign.blockGap),
                        HomeTodayPlan(
                          title: s['todayPlan']!,
                          rows: _planRows(s, data),
                        ),
                        const SizedBox(height: HomeDesign.sectionGap),
                        HomeWeekActivity(
                          title: s['weekTitle']!,
                          days: _weekdayLabels(
                            bn,
                            data?.progress.activityDates,
                          ),
                          active: _weekActive(data?.progress.activityDates),
                          countLabel: s['weekActive']!.replaceFirst(
                            '{n}',
                            '${_weekActive(data?.progress.activityDates).where((x) => x).length}',
                          ),
                        ),
                        const SizedBox(height: HomeDesign.blockGap),
                        HomeWeakTopics(
                          title: s['weakTitle']!,
                          labels: [
                            for (final w
                                in (data?.progress.weakChapters ?? const [])
                                    .take(2))
                              w.label(bn),
                          ],
                          emptyLabel: s['weakEmpty']!,
                          actionLabel: s['revise']!,
                        ),
                        const SizedBox(height: HomeDesign.blockGap),
                        HomeUpcomingTest(
                          title: s['weeklyTest']!,
                          daysLeftLabel: s['daysLeft']!.replaceFirst(
                            '{n}',
                            '${_daysToSaturday()}',
                          ),
                          actionLabel: s['start']!,
                        ),
                        const SizedBox(height: HomeDesign.sectionGap),
                        HomeRecentQuestions(
                          title: s['recentQ']!,
                          entries: data?.recentQuestions ?? const [],
                        ),
                        if ((data?.recentQuestions ?? const []).isNotEmpty)
                          const SizedBox(height: HomeDesign.blockGap),
                        HomeNextMilestone(
                          title: s['nextBadge']!,
                          label: s['milestone']!.replaceFirst(
                            '{n}',
                            '${_nextMilestone(data?.progress.streakDays ?? 0)}',
                          ),
                          actionLabel: s['view']!,
                        ),
                        const SizedBox(height: HomeDesign.sectionGap),
                        SectionHeader(
                          title: s['subjects']!,
                          actionLabel: s['seeAll']!,
                          onAction: () => context.go('/home/subjects'),
                        ),
                        // Batch 2, item 3: grid uses the profile
                        // class, never hardcoded 6; loading shows
                        // the loading line, not choose-class state.
                        if (data == null)
                          const SubjectGridSkeleton()
                        else
                          HomeSubjectGrid(
                            bn: bn,
                            schoolClass: data.schoolClass,
                            opened: data.opened,
                            loadingLabel: s['loadingSubjects']!,
                            noSubjectsLabel: s['noSubjects']!,
                            chooseClassTitle: s['chooseClassTitle']!,
                            chooseClassBody: s['chooseClassBody']!,
                            chooseClassAction: s['chooseClassAction']!,
                          ),
                        const SizedBox(height: HomeDesign.sectionGap),
                        HomeLowerSections(
                          bn: bn,
                          s: s,
                          last: last,
                          heroSubject: heroSubject,
                          heroTopic: heroTopic,
                          recentBooks: sum?.recentBooks ?? const [],
                          onOpenLesson: () {
                            if (last == null) return;
                            // B14: a guide entry (page 0) opens the
                            // new search flow at that chapter; a real
                            // textbook entry keeps the lesson screen.
                            if (last.page <= 0) {
                              final cls = last.schoolClass;
                              context.go(
                                '/search-flow?subject=${last.subject}'
                                '&chapter=${last.chapter}'
                                '${cls == null ? '' : '&class=$cls'}',
                              );
                              return;
                            }
                            LessonSelectionHolder.set(last);
                            context.go('/lesson');
                          },
                          onOpenBook: (e) {
                            final parts = e.split('|');
                            // A guide entry (B14) carries the target as
                            // '<guide:class:subject:chapter>'.
                            final target = parts.length > 3 ? parts[3] : '';
                            if (target.startsWith('<guide:')) {
                              final t = target
                                  .replaceAll('<guide:', '')
                                  .replaceAll('>', '')
                                  .split(':');
                              if (t.length == 3) {
                                context.go(
                                  '/search-flow?subject=${t[1]}'
                                  '&class=${t[0]}&chapter=${t[2]}',
                                );
                                return;
                              }
                            }
                            // The recent entry carries the REAL
                            // books_public id as its 4th part; the old
                            // fabricated 'class6-…' id opened the wrong
                            // (or no) book. No id = open the library,
                            // never invent one.
                            final id = target;
                            if (id.isEmpty) {
                              context.go('/books');
                              return;
                            }
                            BookSelectionHolder.set(parts[0], id, 1);
                            context.go('/books/viewer');
                          },
                          onSearch: () => context.go('/search-flow'),
                          onSeeSubjects: () => context.go('/home/subjects'),
                        ),
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
              s['subjectsTab']!,
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
