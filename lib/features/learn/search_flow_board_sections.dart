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
import 'widgets/board_filter_chips.dart';
import 'widgets/digits.dart';
import 'widgets/search_flow_message.dart';
import 'package:yes_sir_ai/theme/themed_scaffold.dart';

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
                    FutureBuilder<List<BoardFacet>?>(
                      future: _facets,
                      builder: (context, facetSnap) {
                        final facets = facetSnap.data;
                        if (facets == null || facets.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return BoardFilterChips(
                          facets: facets,
                          bn: bn,
                          board: _board,
                          year: _year,
                          onBoard: (v) => setState(() => _board = v),
                          onYear: (v) => setState(() => _year = v),
                        );
                      },
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
