// Board year/board filter chips (round 4 polish).
//
// Counts are CROSS-FILTERED from the same facets the server reported:
// picking a year updates every board chip's count and vice versa — so
// a chip never promises questions that do not exist for the current
// filters. Selected chips carry a check and the brand fill; nothing
// here guesses a year or a board.
import 'package:flutter/material.dart';

import '../../../core/services/board_facets_service.dart';
import '../../../theme/app_tokens.dart';
import '../widgets/digits.dart';

/// Bengali display names for the nine boards (+ the combined set).
const boardDisplayNames = <String, (String, String)>{
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

String boardDisplayName(String id, bool bn) {
  final pair = boardDisplayNames[id];
  if (pair == null) return id;
  return bn ? pair.$1 : pair.$2;
}

/// Total questions of one year under the current board filter.
int yearCount(List<BoardFacet> facets, int year, String? board) => facets
    .where((f) => f.year == year && (board == null || f.board == board))
    .fold(0, (sum, f) => sum + f.total);

/// Total questions of one board under the current year filter.
int boardCount(List<BoardFacet> facets, String board, int? year) => facets
    .where((f) => f.board == board && (year == null || f.year == year))
    .fold(0, (sum, f) => sum + f.total);

/// Grand total under the current filters (both chips included).
int filteredTotal(List<BoardFacet> facets, String? board, int? year) => facets
    .where(
      (f) =>
          (board == null || f.board == board) &&
          (year == null || f.year == year),
    )
    .fold(0, (sum, f) => sum + f.total);

/// Years, newest first, and boards, alphabetical — derived from data.
List<int> facetYears(List<BoardFacet> facets) =>
    facets.map((f) => f.year).toSet().toList()..sort((a, b) => b.compareTo(a));

List<String> facetBoards(List<BoardFacet> facets) =>
    facets.map((f) => f.board).toSet().toList()..sort();

class BoardFilterChips extends StatelessWidget {
  const BoardFilterChips({
    super.key,
    required this.facets,
    required this.bn,
    required this.board,
    required this.year,
    required this.onBoard,
    required this.onYear,
  });

  final List<BoardFacet> facets;
  final bool bn;
  final String? board;
  final int? year;
  final void Function(String?) onBoard;
  final void Function(int?) onYear;

  @override
  Widget build(BuildContext context) {
    final years = facetYears(facets);
    final boards = facetBoards(facets);
    final total = filteredTotal(facets, board, year);
    final allLabel = bn ? 'সব' : 'All';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Sp.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    bn ? 'বছর ও বোর্ড' : 'Year & board',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                Text(
                  '${numStr(total, bn)} ${bn ? 'প্রশ্ন' : 'questions'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: Sp.md),
            _GroupLabel(text: bn ? 'বছর' : 'Year'),
            const SizedBox(height: Sp.xs),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChip(
                  label: allLabel,
                  count: year == null
                      ? total
                      : filteredTotal(facets, board, null),
                  selected: year == null,
                  onTap: () => onYear(null),
                ),
                for (final y in years)
                  _FilterChip(
                    label: numStr(y, bn),
                    count: yearCount(facets, y, board),
                    selected: year == y,
                    onTap: () => onYear(y),
                  ),
              ],
            ),
            const SizedBox(height: Sp.md),
            _GroupLabel(text: bn ? 'বোর্ড' : 'Board'),
            const SizedBox(height: Sp.xs),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChip(
                  label: allLabel,
                  count: board == null
                      ? total
                      : filteredTotal(facets, null, year),
                  selected: board == null,
                  onTap: () => onBoard(null),
                ),
                for (final b in boards)
                  _FilterChip(
                    label: boardDisplayName(b, bn),
                    count: boardCount(facets, b, year),
                    selected: board == b,
                    onTap: () => onBoard(b),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

/// One chip: label + live count, check when selected, brand fill.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: selected ? cs.primary : cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check, size: 15, color: cs.onPrimary),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected ? cs.onPrimary : cs.onSurface,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? cs.onPrimary.withValues(alpha: 0.18)
                      : cs.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? cs.onPrimary : cs.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
