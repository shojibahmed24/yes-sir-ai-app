// Route: /search — textbook search, reworked (second step).
// Primary action is "অধ্যায়ের সব প্রশ্ন দেখুন" (chapter list).
// "সমাধান দেখো" is ONLY a shortcut: exact resolve -> /lesson,
// else chapter list with a page banner when the chapter exists,
// else /lesson/no-match (see decideSearchShortcut). No DEMO
// quick-finds. Class = saved profile (loadSchoolClass ?? 6) in a
// visible 6/7 selector; page/problem optional, default 1/1.
// Textbook list = NCTB questions only; guide questions are in
// Guide Bank (linked below).
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/explanation_service.dart';
import '../../core/services/profile_service.dart';
import 'class_choices.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/search_strings.dart';
import 'learn_store.dart';
import 'lesson_selection.dart';
import 'search_solution_fallback.dart';
import 'widgets/search_guide_section.dart';
import 'widgets/search_recents.dart';
import 'widgets/search_stepper.dart';
import 'package:yes_sir_ai/theme/themed_scaffold.dart';

// Phase 16 (M1): [initialQuery] is the text typed on Home (?q=).
// The stepper cannot resolve free text, so it is shown honestly
// above the stepper instead of being silently dropped.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialQuery = ''});
  final String initialQuery;
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late LessonSelection _sel;
  int _schoolClass = 6;
  bool _locked = false;
  bool _resolving = false;

  @override
  void initState() {
    super.initState();
    // Untouched app default is not a user selection: fresh search
    // starts at page/problem 1/1, never the demo 45/5.
    final cur = LessonSelectionHolder.current;
    _sel = LessonSelectionHolder.touched
        ? cur
        : LessonSelection(
            subject: cur.subject,
            chapter: cur.chapter,
            page: 1,
            problem: 1,
          );
    _loadClass();
  }

  Future<void> _loadClass() async {
    int cls = 6;
    try {
      cls = await profileService.loadSchoolClass() ?? 6;
    } catch (_) {}
    if (mounted) setState(() => _schoolClass = cls);
  }

  String _label(bool bn) =>
      (bn ? searchStringsBn : searchStringsEn)['selectionLabel']!
          .replaceAll('{chapter}', '${_sel.chapter}')
          .replaceAll('{page}', '${_sel.page}')
          .replaceAll('{problem}', '${_sel.problem}');

  void _goChapterList({int? bannerPage}) {
    ChapterListHolder.set(schoolClass: _schoolClass, bannerPage: bannerPage);
    context.go('/chapter-questions/${_sel.subject}/${_sel.chapter}');
  }

  // Shortcut only: found -> /lesson (and recorded as recent);
  // chapter exists -> chapter list with the page banner; chapter
  // missing -> the old no-match screen. Never a guessed answer.
  Future<void> _showSolution(BuildContext context) async {
    if (_resolving) return;
    setState(() => _resolving = true);
    final bn = Localizations.localeOf(context).languageCode == 'bn';
    LessonSelectionHolder.set(_sel.copyWith(schoolClass: _schoolClass));
    final found = (await explanationService.resolve(
      subject: _sel.subject,
      schoolClass: _schoolClass,
      chapter: _sel.chapter,
      page: _sel.page,
      problem: _sel.problem,
      bangla: bn,
    )).found;
    if (!context.mounted) return;
    setState(() => _resolving = false);
    if (found) {
      await LearnStore.addRecentSearch('${_label(bn)}|${_sel.key}');
      if (!context.mounted) return;
      context.go('/lesson');
      return;
    }
    await resolveSearchFallback(
      context: context,
      subject: _sel.subject,
      schoolClass: _schoolClass,
      chapter: _sel.chapter,
      page: _sel.page,
      problem: _sel.problem,
      label: _label(bn),
      bn: bn,
      goChapterList: (bannerPage) => _goChapterList(bannerPage: bannerPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? searchStringsBn : searchStringsEn;
        final classItems = classChoices(_schoolClass);
        return ThemedScaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/home'),
            ),
            title: Text(s['title']!),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s['subtitle']!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (widget.initialQuery.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.search),
                      title: Text('${s['homeSearch']!} ${widget.initialQuery}'),
                      subtitle: Text(s['homeSearchSub']!),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(child: Text(s['classLabel']!)),
                        DropdownButton<int>(
                          value: _schoolClass,
                          items: classItems
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text('$c'),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _schoolClass = v);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SearchStepper(
                  labels: s,
                  bn: bn,
                  initial: _sel,
                  schoolClass: _schoolClass,
                  lockedLabel: s['lockedSubject']!,
                  onChanged: (sel, locked) {
                    setState(() {
                      _sel = sel.copyWith(schoolClass: _schoolClass);
                      _locked = locked;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _locked ? null : () => _goChapterList(),
                  child: Text(s['chapterListButton']!),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: (_locked || _resolving)
                      ? null
                      : () => _showSolution(context),
                  child: Text(_resolving ? s['checking']! : s['showSolution']!),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => context.go('/book-lookup'),
                  child: Text(s['bookLookup']!),
                ),
                SearchGuideSection(
                  subject: _sel.subject,
                  schoolClass: _schoolClass,
                  locked: _locked,
                  note: s['textbookOnlyNote']!,
                  linkLabel: s['guideBankLink']!,
                  buttonLabel: s['guideChaptersButton']!,
                ),
                const SizedBox(height: 8),
                SearchRecentsSection(
                  s: s,
                  onRecentTap: (sel, label) {
                    _sel = sel.copyWith(schoolClass: _schoolClass);
                    _showSolution(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
