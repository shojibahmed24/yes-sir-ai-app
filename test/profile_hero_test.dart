// Profile hero: the saved name/class/id ride on the app gradient,
// and an empty id line never leaves a blank gap.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/features/profile/widgets/profile_hero.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('shows name, class and id on a gradient band', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const ProfileHero(
          name: 'রহিম',
          displayName: 'রহিম উদ্দিন',
          classInfo: 'ক্লাস ৯ · বাংলা মাধ্যম',
          idLine: 'শিক্ষার্থী আইডি: ১২৩',
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('profile-hero')), findsOneWidget);
    expect(find.text('রহিম উদ্দিন'), findsOneWidget);
    expect(find.text('ক্লাস ৯ · বাংলা মাধ্যম'), findsOneWidget);
    expect(find.text('শিক্ষার্থী আইডি: ১২৩'), findsOneWidget);
    final band = tester.widget<Container>(
      find.byKey(const Key('profile-hero')),
    );
    expect((band.decoration as BoxDecoration).gradient, isNotNull);
  });

  testWidgets('an empty id line renders nothing extra', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const ProfileHero(
          name: 'A',
          displayName: 'Student',
          classInfo: 'Class 7',
          idLine: '',
        ),
      ),
    );
    await tester.pump();
    expect(find.text(''), findsNothing);
    expect(find.text('Student'), findsOneWidget);
  });
}
