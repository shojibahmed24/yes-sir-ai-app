// Board chip counts must be cross-filtered from the real facets:
// picking a year changes every board chip and vice versa.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/services/board_facets_service.dart';
import 'package:yes_sir_ai/features/learn/widgets/board_filter_chips.dart';

BoardFacet _f(String board, int year, int mcq, [int creative = 0]) =>
    BoardFacet(board: board, year: year, mcq: mcq, creative: creative);

void main() {
  final facets = [
    _f('dhaka', 2024, 30),
    _f('dhaka', 2023, 29),
    _f('rajshahi', 2024, 30, 4),
    _f('rajshahi', 2019, 12),
    _f('all', 2018, 30),
  ];

  test('year count respects the selected board', () {
    expect(yearCount(facets, 2024, null), 64);
    expect(yearCount(facets, 2024, 'dhaka'), 30);
    expect(yearCount(facets, 2023, 'rajshahi'), 0);
  });

  test('board count respects the selected year', () {
    expect(boardCount(facets, 'rajshahi', null), 46);
    expect(boardCount(facets, 'rajshahi', 2024), 34);
    expect(boardCount(facets, 'dhaka', 2019), 0);
  });

  test('grand total follows both filters', () {
    expect(filteredTotal(facets, null, null), 135);
    expect(filteredTotal(facets, 'dhaka', 2024), 30);
    expect(filteredTotal(facets, null, 2024), 64);
  });

  test('years newest first, boards alphabetical, labels localized', () {
    expect(facetYears(facets), [2024, 2023, 2019, 2018]);
    expect(facetBoards(facets), ['all', 'dhaka', 'rajshahi']);
    expect(boardDisplayName('dhaka', true), 'ঢাকা');
    expect(boardDisplayName('dhaka', false), 'Dhaka');
    expect(boardDisplayName('unknown', false), 'unknown');
  });
}
