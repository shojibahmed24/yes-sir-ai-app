// Type list screen (Step 5): one type, 20 rows at a time, with
// "আরো দেখুন" for the next 20. NEVER all rows at once, and NO
// "all questions" option exists anywhere in this flow.
// Guide mode: server-filtered paging when the new server echoes
// the filter, client-filtered scan on the old server (see
// guide_flow_list_service). Textbook mode: the chapter list
// (existing listByChapter path) filtered client-side by the
// verified type mapping; rows show NO marks (textbooks print
// none — never invented). questionNumber (textbook jump with
// several same-number rows): the list shows ONLY those rows.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/guide_bank_model.dart';
import '../../core/services/billing_service.dart';
import '../../core/services/guide_flow_list_service.dart';
import '../../core/services/textbook_chapter_service.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/chapter_questions_strings.dart';
import '../../l10n/pages/guide_bank_strings.dart';
import '../../l10n/pages/search_flow_strings.dart';
import 'lesson_selection.dart';
import 'search_flow_answer_nav.dart';
import 'search_flow_types.dart';
import 'widgets/search_flow_book_list.dart';
import 'widgets/search_flow_guide_list.dart';

class SearchFlowListScreen extends StatefulWidget {
  const SearchFlowListScreen({
    super.key,
    required this.subjectId,
    required this.schoolClass,
    required this.source,
    required this.chapterNumber,
    required this.type,
    this.lesson,
    this.questionNumber,
  });
  final String subjectId;
  final int schoolClass;

  /// 'textbook' or 'guide'.
  final String source;
  final int chapterNumber;
  final SearchFlowType type;
  final String? lesson;
  final int? questionNumber;

  @override
  State<SearchFlowListScreen> createState() => _SearchFlowListScreenState();
}

class _SearchFlowListScreenState extends State<SearchFlowListScreen> {
  bool _loading = true;
  GuideFlowMode _mode = GuideFlowMode.serverFiltered;
  List<GuideBankQuestion> _guideRows = [];
  int? _guideTotal;
  bool _guideHasMore = false;
  int _scanOffset = 0;
  List<TextbookChapterQuestion> _bookRows = [];
  int _visible = 20;
  bool _isPremium = false;

  bool get _guide => widget.source == 'guide';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_guide) {
      final premium =
          await billingService.isPremium().catchError((_) => false);
      final page = await guideFlowListService.fetchPage(
          subject: widget.subjectId, schoolClass: widget.schoolClass,
          chapter: widget.chapterNumber, type: widget.type,
          lesson: widget.lesson);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _isPremium = premium;
        _mode = page.mode;
        _guideRows = page.rows;
        _guideTotal = page.total;
        _guideHasMore = page.hasMore;
        _scanOffset = page.nextScanOffset;
      });
    } else {
      final bn = languageNotifier.value.languageCode == 'bn';
      final rows = await textbookChapterService.fetchChapter(
          widget.subjectId, widget.schoolClass, widget.chapterNumber, bn);
      if (!mounted) return;
      final filtered = (rows ?? [])
          .where((r) =>
              searchFlowTextbookMatches(widget.type, r.questionType) &&
              (widget.questionNumber == null ||
                  r.problem == widget.questionNumber))
          .toList();
      setState(() {
        _loading = false;
        _mode = rows == null
            ? GuideFlowMode.unavailable
            : GuideFlowMode.serverFiltered;
        _bookRows = filtered;
      });
    }
  }

  Future<void> _loadMoreGuide() async {
    final page = await guideFlowListService.fetchPage(
        subject: widget.subjectId, schoolClass: widget.schoolClass,
        chapter: widget.chapterNumber, type: widget.type,
        lesson: widget.lesson,
        offset: _guideRows.length, scanOffset: _scanOffset);
    if (!mounted) return;
    setState(() {
      _mode = page.mode;
      _guideRows = [..._guideRows, ...page.rows];
      _guideTotal = page.total;
      _guideHasMore = page.hasMore;
      _scanOffset = page.nextScanOffset;
    });
  }

  // Step 7: list URL + answer openings live in
  // search_flow_answer_nav.dart (line-cap split).
  String _listUrl() => searchFlowListUrl(
        subjectId: widget.subjectId,
        schoolClass: widget.schoolClass,
        source: widget.source,
        chapterNumber: widget.chapterNumber,
        typeName: widget.type.name,
        lesson: widget.lesson,
        questionNumber: widget.questionNumber,
      );

  void _openGuide(int index, GuideBankQuestion q) =>
      openSearchFlowGuideAnswer(context,
          isPremium: _isPremium, index: index, q: q,
          subjectId: widget.subjectId,
          chapterNumber: q.chapterNumber ?? widget.chapterNumber,
          schoolClass: widget.schoolClass, returnTo: _listUrl());

  void _openGuideGroup(
          int firstIndex, List<GuideBankQuestion> parts, String stimulusText) =>
      openSearchFlowGuideGroupAnswer(context,
          isPremium: _isPremium, firstIndex: firstIndex, parts: parts,
          stimulusText: stimulusText, subjectId: widget.subjectId,
          chapterNumber: widget.chapterNumber,
          schoolClass: widget.schoolClass, returnTo: _listUrl());

  void _openBook(TextbookChapterQuestion q) {
    LessonSelectionHolder.set(LessonSelection(
        subject: widget.subjectId, chapter: widget.chapterNumber, page: q.page,
        problem: q.problem ?? 0, questionId: q.id,
        schoolClass: widget.schoolClass));
    context.go('/lesson');
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? searchFlowStringsBn : searchFlowStringsEn;
        final back = '/search-flow?subject=${widget.subjectId}';
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go(back),
            ),
            title: Text(s['listTitle']!),
          ),
          body: _loading
              ? Center(child: Text(s['loading']!))
              : _mode == GuideFlowMode.unavailable
                  ? _message(
                      s['unavailableTitle']!, s['unavailableBody']!, s, back)
                  : _mode == GuideFlowMode.filterPending
                      ? _message(s['filterPendingTitle']!,
                          s['filterPendingBody']!, s, back)
                      : _guide
                          ? _guideRows.isEmpty
                              ? _message(s['emptyList']!, '', s, back)
                              : SearchFlowGuideListView(
                                  rows: _guideRows,
                                  total: _guideTotal,
                                  hasMore: _guideHasMore,
                                  isPremium: _isPremium,
                                  subjectId: widget.subjectId,
                                  chapterNumber: widget.chapterNumber,
                                  type: widget.type,
                                  bn: bn,
                                  s: s,
                                  gs: bn
                                      ? guideBankStringsBn
                                      : guideBankStringsEn,
                                  onOpen: _openGuide,
                                  onOpenGroup: _openGuideGroup,
                                  onLoadMore: _loadMoreGuide,
                                )
                          : _bookRows.isEmpty
                              ? _message(s['emptyList']!, '', s, back)
                              : SearchFlowBookListView(
                                  rows: _bookRows,
                                  visible: _visible,
                                  bn: bn,
                                  s: s,
                                  cs: bn
                                      ? chapterQuestionsStringsBn
                                      : chapterQuestionsStringsEn,
                                  onOpen: _openBook,
                                  onLoadMore: () =>
                                      setState(() => _visible += 20),
                                ),
        );
      },
    );
  }

  Widget _message(
      String title, String body, Map<String, String> s, String back) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(body),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.go(back),
            child: Text(s['backToSearch']!),
          ),
        ],
      ),
    );
  }
}
