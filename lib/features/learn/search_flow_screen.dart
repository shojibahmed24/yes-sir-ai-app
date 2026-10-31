// New search screen (Step 3): home tile -> this screen. Order
// (plan §1): শ্রেণি -> বিষয় -> সোর্স (পাঠ্যবই / গাইড) ->
// অধ্যায় (REAL names) -> লেসন (guide mode ONLY, and ONLY when
// the chapter has lesson-tagged rows; otherwise skipped) ->
// প্রশ্ন নম্বর ইনপুট (NO page field anywhere) -> টাইপ (exactly
// 5). State + resolution live in SearchFlowController; this file
// only renders and navigates. UI (plan §5): every input uses the
// shared SearchFlowField component, grouped under two headings,
// with actions pinned at the bottom and a hint when chapter/type
// are still unpicked. No old screen/route is touched.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/language_provider.dart';
import '../../l10n/pages/search_flow_strings.dart';
import 'guide_answer_holder.dart';
import 'lesson_selection.dart';
import 'search_flow_controller.dart';
import 'search_flow_types.dart';
import 'widgets/digits.dart';
import 'widgets/search_flow_field.dart';
import 'widgets/search_flow_field_states.dart';

class SearchFlowScreen extends StatefulWidget {
  const SearchFlowScreen({
    super.key,
    this.initialSubjectId = 'math',
    this.initialSchoolClass,
  });
  final String initialSubjectId;
  final int? initialSchoolClass;

  @override
  State<SearchFlowScreen> createState() => _SearchFlowScreenState();
}

class _SearchFlowScreenState extends State<SearchFlowScreen> {
  late final SearchFlowController _c;
  String? _jumpMessage;

  @override
  void initState() {
    super.initState();
    _c = SearchFlowController(
      initialSubjectId: widget.initialSubjectId,
      initialSchoolClass: widget.initialSchoolClass,
      onChanged: () {
        if (mounted) setState(() {});
      },
    );    _c.init(languageNotifier.value.languageCode == 'bn');
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _goList({int? questionNumber}) =>
      context.go('/search-flow-list?${_c.listQuery(questionNumber: questionNumber)}');

  Future<void> _jump(Map<String, String> s, bool bn) async {
    final result = await _c.jump(s, bn);
    if (!mounted) return;
    switch (result.kind) {
      case SearchFlowJumpKind.guideQuestion:
        // Step 7: back from the answer returns to this
        // search screen (the jump came from here, not a list).
        GuideAnswerHolder.set(q: result.question!, subject: _c.subjectId,
            chapter: _c.chapter!, schoolClass: _c.schoolClass, returnTo: '/search-flow?subject=${_c.subjectId}');
        context.go('/guide-answer');
      case SearchFlowJumpKind.lesson:
        LessonSelectionHolder.set(result.lesson!);
        context.go('/lesson');
      case SearchFlowJumpKind.list:
        final n = normalizeQuestionNumber(_c.numberCtrl.text);
        if (n != null) _goList(questionNumber: n);
      case SearchFlowJumpKind.message:
        setState(() => _jumpMessage = result.message);
    }
  }

  String _chapterLabel(int n, String title, bool bn, Map<String, String> s) {
    final num = numStr(n, bn);
    if (title.isEmpty) return "${s['chapterLabel']} $num";
    return '$num · $title';
  }

  String _typeLabel(SearchFlowType t, Map<String, String> s) => {
        SearchFlowType.mcq: s['typeMcq']!,
        SearchFlowType.short: s['typeShort']!,
        SearchFlowType.creative: s['typeCreative']!,
        SearchFlowType.practiceWork: s['typePracticeWork']!,
        SearchFlowType.textbookExercise: s['typeTextbookExercise']!,
      }[t]!;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? searchFlowStringsBn : searchFlowStringsEn;
        final classItems = {6, 7, _c.schoolClass}.toList()..sort();
        final canSubmit = _c.chapter != null && _c.type != null;
        final String? actionHint = _c.chapter == null && _c.type == null
            ? s['actionHintBoth']
            : _c.chapter == null ? s['actionHintChapter'] : _c.type == null ? s['actionHintType'] : null;
        const gap = SizedBox(height: 12);
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home')),
            title: Text(s['title']!),
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s['subtitle']!, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 16),
                      SearchFlowGroupLabel(s['identityGroup']!),
                      const SizedBox(height: 12),
                      SearchFlowDropdownField<int>(
                        label: s['classLabel']!, icon: Icons.school,
                        value: _c.schoolClass,
                        items: classItems.map((c) => SearchFlowDropdownItem(value: c, label: '$c')).toList(),
                        onChanged: (v) {
                          if (v != null) _c.changeClass(v, bn);
                        },
                      ),
                      gap,
                      SearchFlowDropdownField<String>(
                        label: s['subjectLabel']!, icon: Icons.book,
                        value: _c.subjects.any((x) => x.id == _c.subjectId) ? _c.subjectId : null,
                        hint: s['subjectLabel']!,
                        items: _c.subjects.map((x) => SearchFlowDropdownItem(value: x.id, label: x.name(bn))).toList(),
                        onChanged: (v) {
                          if (v != null) _c.applySubject(v);
                        },
                      ),
                      gap,
                      SearchFlowDropdownField<String>(
                        label: s['sourceLabel']!, icon: Icons.source,
                        value: _c.source,
                        items: [
                          SearchFlowDropdownItem(value: 'textbook', label: s['sourceTextbook']!),
                          SearchFlowDropdownItem(value: 'guide', label: s['sourceGuide']!),
                        ],
                        onChanged: (v) {
                          if (v != null) _c.changeSource(v);
                        },
                      ),
                      const SizedBox(height: 20),
                      SearchFlowGroupLabel(s['questionGroup']!),
                      const SizedBox(height: 12),
                      if (_c.chaptersLoading)
                        SearchFlowLoadingBars(label: s['chapterLabel']!, semanticsLabel: s['chapterLoading']!)
                      else if (_c.chapters.isEmpty)
                        SearchFlowEmptyCard(label: s['chapterLabel']!, message: s['chapterEmpty']!)
                      else
                        SearchFlowDropdownField<int>(
                          label: s['chapterLabel']!, icon: Icons.menu_book,
                          value: _c.chapter, hint: s['chapterLabel']!,
                          items: _c.chapters.map((c) => SearchFlowDropdownItem(value: c.$1, label: _chapterLabel(c.$1, c.$2, bn, s))).toList(),
                          onChanged: (v) => setState(() {
                            _c.chapter = v;
                            _c.lesson = null;
                          }),
                        ),
                      if (_c.lessons.isNotEmpty) ...[
                        gap,
                        SearchFlowDropdownField<String?>(
                          label: s['lessonLabel']!, icon: Icons.play_lesson,
                          value: _c.lesson,
                          items: [
                            SearchFlowDropdownItem<String?>(value: null, label: s['lessonAll']!),
                            for (final e in _c.lessons.entries)
                              SearchFlowDropdownItem<String?>(value: e.key, label: '${e.key} · ${e.value}'),
                          ],
                          onChanged: (v) => setState(() => _c.lesson = v),
                        ),
                      ],
                      gap,
                      SearchFlowTextField(
                        label: s['questionNumberLabel']!, icon: Icons.numbers,
                        controller: _c.numberCtrl, hint: s['questionNumberHint']!,
                        keyboardType: TextInputType.number,
                        onChanged: (_) {
                          if (_jumpMessage != null) {
                            setState(() => _jumpMessage = null);
                          }
                        },
                        onSubmitted: () => _jump(s, bn),
                      ),
                      gap,
                      SearchFlowDropdownField<SearchFlowType>(
                        label: s['typeLabel']!, icon: Icons.category,
                        value: _c.type,
                        items: [for (final t in SearchFlowType.values) SearchFlowDropdownItem(value: t, label: _typeLabel(t, s))],
                        onChanged: (v) => setState(() => _c.type = v),
                      ),
                      if (_jumpMessage != null) ...[
                        const SizedBox(height: 12),
                        Card(child: Padding(padding: const EdgeInsets.all(12), child: Text(_jumpMessage!))),
                      ],
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (actionHint != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(actionHint,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall),
                        ),
                      ElevatedButton(
                          onPressed: canSubmit ? () => _goList() : null,
                          child: Text(s['showList']!)),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: canSubmit && !_c.jumping ? () => _jump(s, bn) : null,
                        child: Text(_c.jumping ? s['jumpChecking']! : s['jumpButton']!),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
