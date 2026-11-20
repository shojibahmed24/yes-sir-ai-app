// Settings appearance section (split from settings_screen.dart):
// pure widget tests, no I/O. The section must render the Bangla +
// English language options, the three font sizes, the three theme
// modes, and report taps through the callbacks exactly once with
// the value the screen expects (font label + its 0.85/1.0/1.25
// scale, which is what the app-wide textScaler uses).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/features/profile/widgets/settings_appearance_section.dart';
import 'package:yes_sir_ai/l10n/language_provider.dart';
import 'package:yes_sir_ai/l10n/pages/settings_strings.dart';
import 'package:yes_sir_ai/theme/app_theme.dart';
import 'package:yes_sir_ai/theme/app_tokens.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(Sp.xxl),
      child: child,
    ),
  ),
);

Widget _section({
  String languageCode = 'en',
  String font = 'normal',
  String theme = 'day',
  ValueChanged<String>? onLanguage,
  ValueChanged<String>? onFont,
  ValueChanged<String>? onTheme,
}) => SettingsAppearanceSection(
  languageCode: languageCode,
  onLanguageChanged: onLanguage ?? (_) {},
  font: font,
  onFontChanged: onFont ?? (_) {},
  theme: theme,
  onThemeChanged: onTheme ?? (_) {},
);

void main() {
  setUp(() => languageNotifier.value = const Locale('bn'));
  tearDown(() => languageNotifier.value = const Locale('bn'));

  testWidgets('renders language, font and theme options', (tester) async {
    await tester.pumpWidget(_wrap(_section()));

    expect(find.text(settingsStringsBn['language']!), findsOneWidget);
    expect(find.text(settingsStringsBn['bangla']!), findsOneWidget);
    expect(find.text(settingsStringsBn['english']!), findsOneWidget);

    expect(find.text(settingsStringsBn['fontSize']!), findsOneWidget);
    expect(find.text(settingsStringsBn['small']!), findsOneWidget);
    expect(find.text(settingsStringsBn['normal']!), findsOneWidget);
    expect(find.text(settingsStringsBn['large']!), findsOneWidget);
    expect(find.text(settingsStringsBn['preview']!), findsOneWidget);

    expect(find.text(settingsStringsBn['theme']!), findsOneWidget);
    expect(find.text(settingsStringsBn['day']!), findsOneWidget);
    expect(find.text(settingsStringsBn['night']!), findsOneWidget);
    expect(find.text(settingsStringsBn['sepia']!), findsOneWidget);

    // Sepia has no theme of its own: the note only shows for sepia.
    expect(find.text(settingsStringsBn['sepiaNote']!), findsNothing);
  });

  testWidgets('sepia selection shows the honest fallback note', (tester) async {
    await tester.pumpWidget(_wrap(_section(theme: 'sepia')));
    expect(find.text(settingsStringsBn['sepiaNote']!), findsOneWidget);
  });

  testWidgets('tapping a language option calls back once', (tester) async {
    final calls = <String>[];
    await tester.pumpWidget(_wrap(_section(onLanguage: calls.add)));

    await tester.tap(find.text(settingsStringsBn['bangla']!));
    await tester.pumpAndSettle();

    expect(calls, ['bn']);
  });

  testWidgets('tapping "large" calls back once with the font key', (
    tester,
  ) async {
    final calls = <String>[];
    await tester.pumpWidget(_wrap(_section(onFont: calls.add)));

    await tester.tap(find.text(settingsStringsBn['large']!));
    await tester.pumpAndSettle();

    expect(calls, ['large']);
    // The screen turns this key into the app-wide text scale.
    expect(SettingsAppearanceSection.scaleFor('large'), 1.25);
    expect(SettingsAppearanceSection.scaleFor('normal'), 1.0);
    expect(SettingsAppearanceSection.scaleFor('small'), 0.85);
  });

  testWidgets('tapping a theme option calls back once', (tester) async {
    final calls = <String>[];
    await tester.pumpWidget(_wrap(_section(onTheme: calls.add)));

    final night = find.text(settingsStringsBn['night']!);
    await tester.ensureVisible(night);
    await tester.pumpAndSettle();
    await tester.tap(night);
    await tester.pumpAndSettle();

    expect(calls, ['night']);
  });

  testWidgets('English mode renders the English labels', (tester) async {
    languageNotifier.value = const Locale('en');
    await tester.pumpWidget(_wrap(_section()));

    expect(find.text(settingsStringsEn['bangla']!), findsOneWidget);
    expect(find.text(settingsStringsEn['large']!), findsOneWidget);
    expect(find.text(settingsStringsEn['sepia']!), findsOneWidget);
  });

  // A phone is 360dp wide; the three segmented labels must fit
  // inside the group card padding without a layout overflow.
  testWidgets('fits a 360dp phone width', (tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(_section()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
