// Settings — appearance section (language, font size, theme).
// Split out of settings_screen.dart (250-line cap): the screen
// keeps the state and persistence, this widget is pure — it
// renders what it is given and reports taps through callbacks.
// Language, font and theme all apply LIVE app-wide; the choice
// is persisted by the screen, not here. Sepia has no theme of
// its own, so it falls back to light and the note says so.
import 'package:flutter/material.dart';

import '../../../l10n/language_provider.dart';
import '../../../l10n/pages/settings_strings.dart';
import '../../../theme/app_tokens.dart';
import 'settings_group_card.dart';

class SettingsAppearanceSection extends StatelessWidget {
  const SettingsAppearanceSection({
    super.key,
    required this.languageCode,
    required this.onLanguageChanged,
    required this.font,
    required this.onFontChanged,
    required this.theme,
    required this.onThemeChanged,
  });

  final String languageCode;
  final ValueChanged<String> onLanguageChanged;
  final String font;
  final ValueChanged<String> onFontChanged;
  final String theme;
  final ValueChanged<String> onThemeChanged;

  /// Same mapping the app-wide textScaler uses: 0.85 / 1.0 / 1.25.
  static double scaleFor(String font) => font == 'small'
      ? 0.85
      : font == 'large'
      ? 1.25
      : 1.0;

  static double _previewSize(String font) => font == 'small'
      ? 13.0
      : font == 'large'
      ? 19.0
      : 15.0;

  @override
  Widget build(BuildContext context) {
    final s = isBangla ? settingsStringsBn : settingsStringsEn;
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        SettingsGroupCard(
          title: s['language']!,
          subtitle: s['languageSub']!,
          children: [
            RadioListTile<String>(
              title: Text(s['bangla']!),
              value: 'bn',
              groupValue: languageCode,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) {
                if (v != null) onLanguageChanged(v);
              },
            ),
            RadioListTile<String>(
              title: Text(s['english']!),
              value: 'en',
              groupValue: languageCode,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) {
                if (v != null) onLanguageChanged(v);
              },
            ),
          ],
        ),
        const SizedBox(height: Sp.lg),
        SettingsGroupCard(
          title: s['fontSize']!,
          subtitle: s['fontSizeSub']!,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'small', label: Text(s['small']!)),
                  ButtonSegment(value: 'normal', label: Text(s['normal']!)),
                  ButtonSegment(value: 'large', label: Text(s['large']!)),
                ],
                selected: {font},
                onSelectionChanged: (v) => onFontChanged(v.first),
              ),
              const SizedBox(height: Sp.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Sp.lg),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Rad.md),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Text(
                  s['preview']!,
                  style: text.bodyMedium?.copyWith(
                    fontSize: _previewSize(font),
                    height: 1.7,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Sp.lg),
        SettingsGroupCard(
          title: s['theme']!,
          subtitle: s['themeSub']!,
          footnote: theme == 'sepia' ? s['sepiaNote']! : null,
          child: SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'day', label: Text(s['day']!)),
              ButtonSegment(value: 'night', label: Text(s['night']!)),
              ButtonSegment(value: 'sepia', label: Text(s['sepia']!)),
            ],
            selected: {theme},
            onSelectionChanged: (v) => onThemeChanged(v.first),
          ),
        ),
      ],
    );
  }
}
