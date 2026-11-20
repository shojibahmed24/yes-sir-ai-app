// Voice hero: mic state, status and note on the app gradient.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/features/premium/widgets/voice_hero.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('shows remaining minutes and the gradient band', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const VoiceHero(
          title: 'ভয়েস টিউটর',
          status: 'বাকি: ৩০ মিনিট / মাস',
          micOn: false,
          note: '',
        ),
      ),
    );
    expect(find.byKey(const Key('voice-hero')), findsOneWidget);
    expect(find.text('বাকি: ৩০ মিনিট / মাস'), findsOneWidget);
    expect(find.byIcon(Icons.mic_none), findsOneWidget);
    final band = tester.widget<Container>(find.byKey(const Key('voice-hero')));
    expect((band.decoration as BoxDecoration).gradient, isNotNull);
  });

  testWidgets('in-call shows the clock and the live mic icon', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const VoiceHero(
          title: 'Voice tutor',
          status: '02:15',
          micOn: true,
          note: 'Live session',
          big: true,
        ),
      ),
    );
    expect(find.text('02:15'), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsOneWidget);
    expect(find.text('Live session'), findsOneWidget);
  });

  testWidgets('an empty note renders no empty line', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const VoiceHero(
          title: 'T',
          status: '30 min left',
          micOn: false,
          note: '',
        ),
      ),
    );
    expect(find.text(''), findsNothing);
  });
}
