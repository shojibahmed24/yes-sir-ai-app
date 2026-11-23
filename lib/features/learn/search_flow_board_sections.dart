// Board sub-section screen (Board revision 2026-11-02; year/board
// filters round 4).
//
// Reached from the Board tile. Each sub-section opens the board list
// with board=true + its section, so MCQ and Creative never mix. The
// chips above are built from the REAL (board, year) facets the server
// reports for this subject — no guessed years — and the chosen
// filters travel to the list, which the server applies and echoes.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/board_facets_service.dart';
import '../../core/services/guide_bank_service.dart';
import '../../core/services/guide_quiz_service.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/search_flow_strings.dart';
import '../../theme/app_tokens.dart';
import '../practice/practice_store.dart';
import 'search_flow_types.dart';
import 'widgets/digits.dart';
import 'widgets/search_flow_message.dart';
import 'package:yes_sir_ai/theme/themed_scaffold.dart';

const _boardLabels = <String, (String, String)>{
  'dhaka': ('ঢাকা', 'Dhaka'),
  'rajshahi': ('রাজশাহী', 'Rajshahi'),
  'chattogram': ('চট্টগ্রাম', 'Chattogram'),
  'cumilla': ('কুমিল্লা', 'Cumilla'),
  'jessore': ('যশোর', 'Jashore'),
  'barishal': ('বরিশাল', 'Barishal'),
  'sylhet': ('সিলেট', 'Sylhet'),
  'dinajpur': ('দিনাজপুর', 'Dinajpur'),
  'mymensingh': ('ময়মনসিংহ', 'Mymensingh'),
  'all': ('সকল বোর্ড', 'All boards'),
};

String boardLabel(String id, bool bn) {
  final pair = _boardLabels[id];
  if (pair == null) return id;
  return bn ? pair.$1 : pair.$2;
}

class SearchFlowBoardSectionsScreen extends StatefulWidget {
  const SearchFlowBoardSectionsScreen({
    super.key,
    required this.subjectId,
    required this.schoolClass,
  });
  final String subjectId;
  final int schoolClass;

  @override
  State<SearchFlowBoardSectionsScreen> createState() =>
      _SearchFlowBoardSectionsScreenState();
}

class _SearchFlowBoardSectionsScreenState
    extends State<SearchFlowBoardSectionsScreen> {
  String? _board;
  int? _year;
  bool _startingQuiz = false;
  late final Future<List<BoardFacet>?> _facets = fetchBoardFacets(
    subject: widget.subjectId,
    schoolClass: widget.schoolClass,
  );

  /// Starts a subject-wise board MCQ quiz for the current filters.
  Future<void> _startBoardQuiz(bool bn) async {
    if (_startingQuiz) return;
    setState(() => _startingQuiz = true);
    final items = await guideQuizService.boardMcqQuiz(
      subject: widget.subjectId,
      schoolClass: widget.schoolClass,
      bangla: bn,
      limit: 10,
      boardName: _board,
      boardYear: _year,
    );
    if (!mounted) return;
    setState(() => _startingQuiz = false);
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          content: Text(
            bn
                ? 'এই বোর্ড/বছরে চাবিযুক্ত MCQ পাওয়া যায়নি।'
                : 'No keyed MCQ for this board/year.',
          ),
        ),
      );
      return;
    }
    PracticeSession.selectedSubject = widget.subjectId;
    PracticeSession.quizItems = items;
    PracticeSession.quizSource = 'board';
    PracticeSession.quizShortfall = 0;
    PracticeSession.quizIsRevision = false;
    context.go('/quiz');
  }

  String _listUrl(String section, String type) {
    final b = _board == null ? '' : '&boardName=$_board';
    final y = _year == null ? '' : '&boardYear=$_year';
    return '/search-flow-list?subject=${widget.subjectId}'
        '&class=${widget.schoolClass}'
        '&source=guide&board=true&section=$section&type=$type$b$y';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? searchFlowStringsBn : searchFlowStringsEn;
        final back = '/search-flow?subject=${widget.subjectId}';
        return ThemedScaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go(back),
            ),
            title: Text(s['boardQuestions']!),
          ),
          body: FutureBuilder<({int total, int mcq, int creative})?>(
            future: guideBankService.fetchGuideBoard(
              widget.subjectId,
              schoolClass: widget.schoolClass,
            ),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return Center(child: Text(s['loading']!));
              }
              final board = snap.data;
              if (board == null) {
                return searchFlowMessage(
                  context,
                  s['unavailableTitle']!,
                  s['unavailableBody']!,
                  s,
                  back,
                );
              }
              if (board.total <= 0 || (board.mcq <= 0 && board.creative <= 0)) {
                return searchFlowMessage(context, s['emptyList']!, '', s, back);
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.all(Sp.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FacetChips(
                      future: _facets,
                      bn: bn,
                      s: s,
                      board: _board,
                      year: _year,
                      onBoard: (v) => setState(() => _board = v),
                      onYear: (v) => setState(() => _year = v),
                    ),
                    const SizedBox(height: Sp.md),
                    if (board.mcq > 0)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.check_box_outlined),
                          title: Text(
                            '${searchFlowTypeLabel(SearchFlowType.mcq, s)} · '
                            '${numStr(board.mcq, bn)}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.go(_listUrl('board-mcq', 'mcq')),
                        ),
                      ),
                    if (board.creative > 0)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.edit_note),
                          title: Text(
                            '${searchFlowTypeLabel(SearchFlowType.creative, s)}'
                            ' · ${numStr(board.creative, bn)}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.go(
                            _listUrl('board-creative', 'creative'),
                          ),
                        ),
                      ),
                    const SizedBox(height: Sp.md),
                    // Board MCQ quiz (round 4): the chosen year/board
                    // narrows the quiz too; subject-wise only.
                    if (board.mcq > 0)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.play_circle_outline),
                          title: Text(
                            s['boardQuiz'] ??
                                (bn ? 'বোর্ড MCQ কুইজ' : 'Board MCQ quiz'),
                          ),
                          subtitle: Text(
                            s['boardQuizSub'] ??
                                (bn
                                    ? 'নির্বাচিত বছর/বোর্ডের এমসিকিউ'
                                    : 'MCQs of the selected year/board'),
                          ),
                          trailing: _startingQuiz
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.chevron_right),
                          onTap: _startingQuiz
                              ? null
                              : () => _startBoardQuiz(bn),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Year + board chips from the server facets. Unknown facets (null)
/// show no chips at all — never a fake list — and the list stays
/// available unfiltered.
class _FacetChips extends StatelessWidget {
  const _FacetChips({
    required this.future,
    required this.bn,
    required this.s,
    required this.board,
    required this.year,
    required this.onBoard,
    required this.onYear,
  });

  final Future<List<BoardFacet>?> future;
  final bool bn;
  final Map<String, String> s;
  final String? board;
  final int? year;
  final void Function(String?) onBoard;
  final void Function(int?) onYear;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BoardFacet>?>(
      future: future,
      builder: (context, snap) {
        final facets = snap.data;
        if (facets == null || facets.isEmpty) return const SizedBox.shrink();
        final years = facets.map((f) => f.year).toSet().toList()
          ..sort((a, b) => b.compareTo(a));
        final boards = facets.map((f) => f.board).toSet().toList()..sort();
        final allLabel = bn ? 'সব' : 'All';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bn ? 'বছর' : 'Year',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: Sp.xs),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(allLabel),
                  selected: year == null,
                  onSelected: (_) => onYear(null),
                ),
                for (final y in years)
                  ChoiceChip(
                    label: Text(numStr(y, bn)),
                    selected: year == y,
                    onSelected: (_) => onYear(y),
                  ),
              ],
            ),
            const SizedBox(height: Sp.md),
            Text(
              bn ? 'বোর্ড' : 'Board',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: Sp.xs),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(allLabel),
                  selected: board == null,
                  onSelected: (_) => onBoard(null),
                ),
                for (final b in boards)
                  ChoiceChip(
                    label: Text(boardLabel(b, bn)),
                    selected: board == b,
                    onSelected: (_) => onBoard(b),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
