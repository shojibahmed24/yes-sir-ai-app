// D1 regression: BanglaFirstEntryCard renders, and the search
// flow's Bangla guide view actually hosts it below the Board
// tile — the card was defined but used nowhere, so /bangla-first
// was unreachable from inside the app.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/features/learn/bangla_first_entry_card.dart';
import 'package:yes_sir_ai/l10n/pages/bangla_first_strings.dart';

void main() {
  testWidgets('BanglaFirstEntryCard renders its entry title',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: BanglaFirstEntryCard())),
    );
    expect(find.text(banglaFirstStringsBn['entryTitle']!), findsOneWidget);
    expect(find.text(banglaFirstStringsBn['entrySub']!), findsOneWidget);
    expect(find.byIcon(Icons.menu_book), findsOneWidget);
  });

  test('search flow hosts the card in Bangla 1st guide mode', () {
    // The picker half moved to its own widget (250-line cap); the
    // guard follows it so the card can never be dropped silently.
    final src = File(
      'lib/features/learn/widgets/search_flow_picker_section.dart',
    ).readAsStringSync();
    expect(src.contains("import '../bangla_first_entry_card.dart';"), isTrue);
    expect(src.contains('BanglaFirstEntryCard'), isTrue);
    // Guarded by Bangla 1st guide mode, directly below the Board tile.
    final board = src.indexOf('SearchFlowBoardTile(');
    final card = src.indexOf('BanglaFirstEntryCard()');
    expect(board, isNot(-1));
    expect(card, greaterThan(board));
    expect(src.substring(board, card).contains('banglaFirst'), isTrue);
  });
}
