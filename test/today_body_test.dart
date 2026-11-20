// Today body: real counters, the plain goal text (minutes, never
// divided into a fake percentage), and three honest next actions.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/features/today/today_body.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('shows today lessons and the three stats', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const TodayBody(
          info: TodayInfo(
            todayLessons: 3,
            goalMinutes: 60,
            totalLessons: 24,
            chaptersOpened: 5,
            savedCount: 7,
          ),
          bn: true,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('৩'), findsOneWidget);
    expect(find.text('২৪'), findsOneWidget);
    expect(find.text('৫'), findsOneWidget);
    expect(find.text('৭'), findsOneWidget);
    expect(find.textContaining('৬০'), findsOneWidget);
  });

  testWidgets('missing goal shows the honest note, never a fake target', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const TodayBody(
          info: TodayInfo(
            todayLessons: 0,
            goalMinutes: 0,
            totalLessons: 0,
            chaptersOpened: 0,
            savedCount: 0,
          ),
          bn: true,
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('লক্ষ্য এখনো সেট করা হয়নি'), findsOneWidget);
    expect(find.text('আজ এখনো কিছু খোলা হয়নি'), findsOneWidget);
  });

  testWidgets('no-lessons-today shows the start prompt', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const TodayBody(
          info: TodayInfo(
            todayLessons: 0,
            goalMinutes: 30,
            totalLessons: 10,
            chaptersOpened: 2,
            savedCount: 1,
          ),
          bn: false,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Nothing opened today yet'), findsOneWidget);
    expect(find.text('Start learning'), findsOneWidget);
  });

  testWidgets('with lessons today the empty prompt is gone', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const TodayBody(
          info: TodayInfo(
            todayLessons: 2,
            goalMinutes: 30,
            totalLessons: 10,
            chaptersOpened: 2,
            savedCount: 1,
          ),
          bn: false,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Nothing opened today yet'), findsNothing);
  });
}
