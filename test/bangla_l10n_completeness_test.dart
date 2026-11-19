// R4 regression: every l10n key used by the Bangla 1st/2nd
// screens must exist in BOTH the bn and en maps. The screens
// force-unwrap (s['...']!), so one missing key in one locale
// would crash that screen. The scan reads the actual screen
// sources, so a new key used without its translations fails
// here instead of on a user's phone.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/l10n/pages/bangla_first_strings.dart';
import 'package:yes_sir_ai/l10n/pages/bangla_second_strings.dart';

final _firstDir = Directory('lib/features/learn');

/// Files whose `s` map is the Bangla 1st Paper strings.
final _firstSFiles = <String>{
  'bangla_first_creative_screen.dart',
  'bangla_first_entry_card.dart',
  'bangla_first_lesson_screen.dart',
  'bangla_first_mcq_screen.dart',
  'bangla_first_model_test_set_card.dart',
  'bangla_first_model_tests_screen.dart',
  'bangla_first_quiz_screen.dart',
  'bangla_first_section_screen.dart',
  'bangla_first_sections_screen.dart',
};

/// `s` in bangla_first_creative_group_body.dart and
/// bangla_first_creative_group_screen.dart is the guide-bank
/// map passed in from the parent — only their `bs['...']`
/// keys belong to Bangla 1st, so those two files are excluded
/// from the `s` scan above.

Set<String> _keys(String src, String prefix) => RegExp(
      "\\b$prefix\\['([A-Za-z0-9_]+)'\\]",
    ).allMatches(src).map((m) => m.group(1)!).toSet();

void main() {
  test('Bangla 1st: bn and en key sets match', () {
    expect(banglaFirstStringsBn.keys.toSet(),
        banglaFirstStringsEn.keys.toSet());
  });

  test('Bangla 2nd: bn and en key sets match', () {
    expect(banglaSecondStringsBn.keys.toSet(),
        banglaSecondStringsEn.keys.toSet());
  });

  test('new chip/section/unkeyed keys exist in both locales', () {
    for (final k in [
      'chipNctb',
      'chipExamCommon',
      'chipExam',
      'sectionBoardMcq',
      'sectionBoardWritten',
      'mcqShort',
    ]) {
      expect(banglaSecondStringsBn[k], isNotNull, reason: 'bn $k');
      expect(banglaSecondStringsEn[k], isNotNull, reason: 'en $k');
    }
    expect(banglaFirstStringsBn['unkeyedSuffix'], isNotNull);
    expect(banglaFirstStringsEn['unkeyedSuffix'], isNotNull);
  });

  test('every key used by Bangla 1st screens exists in both locales',
      () {
    final used = <String>{};
    for (final f in _firstDir.listSync()) {
      final name = f.uri.pathSegments.last;
      if (!name.startsWith('bangla_first')) continue;
      final src = File(f.path).readAsStringSync();
      used.addAll(_keys(src, 'bs'));
      if (_firstSFiles.contains(name)) used.addAll(_keys(src, 's'));
    }
    for (final k in used) {
      expect(banglaFirstStringsBn[k], isNotNull, reason: 'bn $k');
      expect(banglaFirstStringsEn[k], isNotNull, reason: 'en $k');
    }
  });

  test('every key used by Bangla 2nd screens exists in both locales',
      () {
    final used = <String>{};
    for (final f in _firstDir.listSync()) {
      final name = f.uri.pathSegments.last;
      if (!name.startsWith('bangla_second')) continue;
      used.addAll(_keys(File(f.path).readAsStringSync(), 's'));
    }
    for (final k in used) {
      expect(banglaSecondStringsBn[k], isNotNull, reason: 'bn $k');
      expect(banglaSecondStringsEn[k], isNotNull, reason: 'en $k');
    }
  });
}
