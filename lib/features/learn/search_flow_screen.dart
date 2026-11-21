// New search screen (Step 3): home tile -> this screen. Order
// (plan §1): শ্রেণি -> বিষয় -> সোর্স (পাঠ্যবই / গাইড) -> ONE global
// picker (subject-wise items load below, same widget for every
// subject) -> প্রশ্ন নম্বর ইনপুট (NO page field anywhere) -> টাইপ
// (exactly 5; guide mode shows the exact count per type). State +
// resolution live in SearchFlowController; this file only renders
// and navigates. The English guide tree and Bangla 2nd types open
// their existing routes. UI (plan §5): shared SearchFlowField
// inputs, actions pinned at the bottom, hint while chapter/type
// are unpicked. No old screen/route is touched.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/search_flow_strings.dart';
import 'guide_answer_holder.dart';
import 'lesson_selection.dart';
import 'search_flow_bangla_papers.dart';
import 'search_flow_browse_extras.dart';
import 'search_flow_controller.dart';
import 'search_flow_jump.dart';
import 'search_flow_list_query.dart';
import 'search_flow_picker_host.dart';
import 'search_flow_types.dart';
import 'widgets/search_flow_actions.dart';
import 'widgets/search_flow_field_states.dart';
import 'widgets/search_flow_identity_fields.dart';
import 'widgets/search_flow_picker_section.dart';
import 'widgets/search_flow_summary.dart';
import 'package:yes_sir_ai/theme/themed_scaffold.dart';

class SearchFlowScreen extends StatefulWidget {
  const SearchFlowScreen({
    super.key,
    this.initialSubjectId = 'math',
    this.initialSchoolClass,
    this.initialSource,
  });
  final String initialSubjectId;
  final int? initialSchoolClass;
  final String? initialSource;

  @override
  State<SearchFlowScreen> createState() => _SearchFlowScreenState();
}

class _SearchFlowScreenState extends State<SearchFlowScreen> {
  late final SearchFlowController _c;
  late final SearchFlowBrowseExtras _extras;
  final _englishHost = GlobalPickerEnglishHost();
  String? _jumpMessage;

  void _ensureEnglish() => _englishHost.ensure(
    subjectId: _c.subjectId,
    source: _c.source,
    schoolClass: _c.schoolClass,
    onChanged: () {
      if (mounted) setState(() {});
    },
  );

  /// One place to refresh everything that depends on class/subject/
  /// source, so the three identity pickers can never drift apart.
  void _afterChange() {
    _extras.refreshGuide(_c.effectiveSubjectId, _c.effectiveClass);
    _ensureEnglish();
  }

  @override
  void initState() {
    super.initState();
    _c = SearchFlowController(
      initialSubjectId: widget.initialSubjectId,
      initialSchoolClass: widget.initialSchoolClass,
      initialSource: widget.initialSource,
      onChanged: () {
        if (mounted) setState(() {});
      },
    );
    _extras = SearchFlowBrowseExtras(
      onChanged: () {
        if (mounted) setState(() {});
      },
    );
    _c.init(languageNotifier.value.languageCode == 'bn').then((_) {
      if (mounted) {
        _extras.refreshGuide(_c.effectiveSubjectId, _c.effectiveClass);
        prefetchFirstSubjectPickerData(_c, _extras);
        _ensureEnglish();
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _goList({int? questionNumber}) {
    final banglaFirst = isBanglaFirstMode(_c.subjectId, _c.source);
    final banglaSecond = isBanglaSecondMode(_c.subjectId, _c.source);
    final paper2Mode = _c.source == 'guide' && _c.subjectId == 'english-2nd';
    if (banglaSecond) {
      context.go('/bangla-second');
      return;
    }
    context.go(
      '/search-flow-list?${_c.listQuery(questionNumber: questionNumber, setId: _extras.setId, paper2Section: _extras.paper2Section, chapterless: _extras.setId == null && (banglaFirst || paper2Mode))}',
    );
  }

  Future<void> _jump(Map<String, String> s, bool bn) async {
    final result = await _c.jump(
      s,
      bn,
      paper2Section: _extras.paper2Section,
      setId: _extras.setId,
    );
    if (!mounted) return;
    switch (result.kind) {
      case SearchFlowJumpKind.guideQuestion:
        // Step 7: back from the answer returns to this search screen.
        GuideAnswerHolder.set(
          q: result.question!,
          subject: _c.subjectId,
          chapter: _c.chapter!,
          schoolClass: _c.schoolClass,
          returnTo: '/search-flow?subject=${_c.subjectId}',
        );
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? searchFlowStringsBn : searchFlowStringsEn;
        final englishGuideMode =
            _c.source == 'guide' && _c.subjectId == 'english';
        final paper2Mode =
            _c.source == 'guide' && _c.subjectId == 'english-2nd';
        final banglaFirst = isBanglaFirstMode(_c.subjectId, _c.source);
        final banglaSecond = isBanglaSecondMode(_c.subjectId, _c.source);
        final setMode = _extras.setId != null;
        final needType = searchFlowNeedsType(
          setMode: setMode,
          banglaFirst: banglaFirst,
          banglaSecond: banglaSecond,
          paper2Mode: paper2Mode,
          paper2SectionPicked: _extras.paper2Section != null,
          typePicked: _c.type != null,
        );
        final canSubmit =
            (setMode ||
                banglaFirst ||
                banglaSecond ||
                paper2Mode ||
                _c.chapter != null) &&
            !needType;
        final actionHint = searchFlowActionHint(
          setMode: setMode,
          banglaFirst: banglaFirst,
          banglaSecond: banglaSecond,
          paper2Mode: paper2Mode,
          paper2SectionPicked: _extras.paper2Section != null,
          chapterPicked: _c.chapter != null,
          needType: needType,
          s: s,
        );
        return ThemedScaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/home'),
            ),
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
                      Text(
                        s['subtitle']!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      SearchFlowGroupLabel(s['identityGroup']!),
                      const SizedBox(height: 12),
                      SearchFlowIdentityFields(
                        controller: _c,
                        s: s,
                        bn: bn,
                        onClass: (v) => _c.changeClass(v, bn).then((_) {
                          if (mounted) _afterChange();
                        }),
                        onSubject: (v) {
                          _c.applySubject(v);
                          _afterChange();
                        },
                        onSource: (v) {
                          _c.changeSource(v);
                          _afterChange();
                        },
                      ),
                      const SizedBox(height: 20),
                      SearchFlowGroupLabel(s['questionGroup']!),
                      const SizedBox(height: 12),
                      SearchFlowSummary(c: _c, bn: bn, s: s),
                      SearchFlowPickerSection(
                        c: _c,
                        extras: _extras,
                        english: _englishHost,
                        s: s,
                        bn: bn,
                        jumpMessage: _jumpMessage,
                        onChanged: () => setState(() {}),
                        onJump: () => _jump(s, bn),
                        onNumberCleared: () =>
                            setState(() => _jumpMessage = null),
                      ),
                    ],
                  ),
                ),
              ),
              if (!englishGuideMode)
                SearchFlowActions(
                  canSubmit: canSubmit,
                  jumping: _c.jumping,
                  actionHint: actionHint,
                  s: s,
                  // No number field in Bangla 1st/2nd, so no jump button (was dead).
                  showJump: !banglaFirst && !banglaSecond,
                  onShowList: () => _goList(),
                  onJump: () => _jump(s, bn),
                ),
            ],
          ),
        );
      },
    );
  }
}
