// Guide portion of the new type list (Step 5). Creative rows are
// GROUPED by stimulus_id into one row per question; other types
// render one row per bank row. Grouping is per loaded page:
// set lists are group-paged by the screen (visibleSetRows), so
// their groups never split; server-paged lists keep the known
// interim limit of a group split across a page boundary.
// Practice-work lists carry the warning banner. The parent owns
// paging state and the paywall gate; this widget only renders.
//
// Paging (B2): the list is a builder that asks for the next page
// when the scroll position gets close to the end, so the student
// never taps "load more". A footer spinner marks an in-flight page
// and the first page stays at 10 rows.
import 'package:flutter/material.dart';

import '../../../core/models/guide_bank_model.dart';
import '../../../core/services/app_config.dart';
import '../../../core/services/guide_bank_service.dart';
import '../board_creative_parse.dart';
import '../search_flow_types.dart';
import '../set_display_labels.dart';
import 'board_creative_card.dart';
import 'digits.dart';
import 'guide_creative_groups.dart';
import 'guide_question_row.dart';

// Re-exported for search_flow_list_screen (at the 250-line cap:
// it cannot add its own import for the loading shimmer, nor for
// the set slice).
export 'guide_list_loading_shimmer.dart';
export '../search_flow_set_slice.dart';

class SearchFlowGuideListView extends StatelessWidget {
  const SearchFlowGuideListView({
    super.key,
    required this.rows,
    required this.total,
    required this.hasMore,
    required this.isPremium,
    required this.subjectId,
    required this.chapterNumber,
    required this.type,
    required this.bn,
    required this.s,
    required this.gs,
    required this.onOpen,
    this.onOpenGroup,
    required this.onLoadMore,
  });
  final List<GuideBankQuestion> rows;
  final int? total;
  final bool hasMore;
  final bool isPremium;
  final String subjectId;
  final int chapterNumber;
  final SearchFlowType type;
  final bool bn;

  /// search_flow strings (Bn or En).
  final Map<String, String> s;

  /// guide_bank strings (Bn or En) for GuideQuestionRow.
  final Map<String, String> gs;
  final void Function(int index, GuideBankQuestion q) onOpen;

  /// Step 7 (Fix A): creative group tap. Null = fall back to
  /// the single-question onOpen for the first part. Args: the
  /// first part's list index (paywall gate), ALL currently
  /// loaded parts of the stimulus, and the stimulus text.
  final void Function(
    int firstIndex,
    List<GuideBankQuestion> parts,
    String stimulusText,
  )?
  onOpenGroup;
  final VoidCallback onLoadMore;

  String? _boardLabel(GroupedRows g) {
    final q = g.parts.first.$2;
    if (q.section?.startsWith('board') != true || q.setId == null) return null;
    return setDisplayTitle(q.setId!, bn, g.parts.first.$1 + 1);
  }

  Widget _row(GroupedRows g, bool locked) {
    final first = g.parts.first;
    final q = first.$2;
    final boardLabel = _boardLabel(g);
    void open() {
      final openGroup = onOpenGroup;
      if (type == SearchFlowType.creative &&
          g.stimulusId != null &&
          openGroup != null) {
        openGroup(first.$1, [
          for (final p in g.parts) p.$2,
        ], q.stimulusText ?? '');
      } else {
        onOpen(first.$1, q);
      }
    }

    if (q.section == 'board-creative' &&
        parseBoardCreative(q.questionText) != null) {
      return BoardCreativeCard(
        question: q,
        locked: locked,
        s: gs,
        boardLabel: boardLabel,
        onTap: open,
      );
    }
    return GuideQuestionRow(
      question: q,
      locked: locked,
      s: gs,
      subjectId: subjectId,
      chapterNumber: chapterNumber,
      boardLabel: boardLabel,
      numberLabel: '#${numStr(first.$1 + 1, bn)}',
      onTap: open,
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = [for (var i = 0; i < rows.length; i++) (i, rows[i])];
    final groups = type == SearchFlowType.creative
        ? groupQuestionRows(entries)
        : [
            for (final e in entries) GroupedRows(stimulusId: null, parts: [e]),
          ];
    final showing = total != null
        ? s['showingTotal']!
              .replaceAll('{total}', numStr(total!, bn))
              .replaceAll('{shown}', numStr(rows.length, bn))
        : s['showingOf']!.replaceAll('{shown}', numStr(rows.length, bn));
    return NotificationListener<ScrollNotification>(
      // Auto-page: request the next page ~600px before the end.
      // The parent guards duplicate calls (_loadingMore), so a
      // fast scroll cannot append the same page twice.
      onNotification: (n) {
        if (!hasMore) return false;
        if (n.metrics.pixels >= n.metrics.maxScrollExtent - 600) {
          onLoadMore();
        }
        return false;
      },
      child: ListView(
        // PageStorageKey keeps the scroll offset when the student
        // opens a question and comes back (B6).
        key: const PageStorageKey<String>('search-flow-guide-list'),
        padding: const EdgeInsets.all(20),
        children: [
          if (type == SearchFlowType.practiceWork)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(s['practiceWorkWarning']!),
              ),
            ),
          Text(showing),
          const SizedBox(height: 8),
          for (final g in groups) ...[
            if (g.stimulusId != null && g.parts.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  s['groupParts']!.replaceAll(
                    '{n}',
                    numStr(g.parts.length, bn),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            // Step 7 (Fix A): a creative group opens worker E's
            // grouped view with ALL currently loaded parts; any
            // other row keeps the single-question path. Known
            // limit kept, not hidden (server-paged lists only;
            // set lists page by whole groups): a group split
            // across a 20-row page boundary still renders as two
            // groups until the next page loads (grouping above
            // runs over all loaded rows, so loading more merges
            // them); tapping the first half before that opens
            // only that half — groups are never merged across
            // rows that have not been loaded, so no wrong
            // group can be assembled.
            _row(
              g,
              !guideBankService.isUnlocked(
                isPremium: isPremium,
                index: g.parts.first.$1,
                freeLimit: AppConfig.freeGuideLimit,
              ),
            ),
          ],
          if (hasMore) ...[
            const SizedBox(height: 16),
            // The next page loads by itself; this is only a status
            // line, not an action the student must find.
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      s['loadingMore']!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
