// Bulk guide flags (quick-load): one class-wide call replaces the
// per-subject chapter -> sets -> bank probe, and a failed bulk call
// must fall back to that probe instead of claiming "no guide".
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/backend_models.dart';
import 'package:yes_sir_ai/core/services/guide_flags_service.dart';
import 'package:yes_sir_ai/core/services/guide_subject_flags.dart';

SubjectInfo _subject(String id, {bool locked = true, int chapters = 0}) =>
    SubjectInfo(
      id: id,
      nameBn: id,
      nameEn: id,
      locked: locked,
      chapterCount: chapters,
    );

void main() {
  test('parser: only a real found:true reply yields flags', () {
    expect(parseGuideFlagsResponse(null), isNull);
    expect(parseGuideFlagsResponse({'error': 'bad-request'}), isNull);
    expect(parseGuideFlagsResponse({'found': true}), isNull);
    expect(
      parseGuideFlagsResponse({
        'found': true,
        'flags': {
          'math': {'hasGuide': true},
          'arabic': {'hasGuide': false},
        },
      }),
      {'math': true, 'arabic': false},
    );
  });

  test('bulk flags mark locked AND unlocked subjects', () async {
    final result = await withBulkGuideFlags(
      [
        _subject('math', locked: false, chapters: 8),
        _subject('biology'),
        _subject('arabic'),
      ],
      9,
      fetchFlags: (cls) async => {'math': true, 'biology': true},
    );
    expect(result.complete, isTrue);
    expect(result.subjects[0].hasGuide, isTrue); // book + guide
    expect(result.subjects[0].chapterCount, 8); // counts untouched
    expect(result.subjects[1].hasGuide, isTrue); // guide only
    expect(result.subjects[2].hasGuide, isFalse); // honestly empty
  });

  test('a missing bulk reply falls back to the per-subject probe',
      () async {
    var probed = 0;
    final result = await withBulkGuideFlags(
      [_subject('math'), _subject('arabic')],
      9,
      fetchFlags: (cls) async => null,
      fetchChapters: (s, {schoolClass = 6}) async {
        probed++;
        return s == 'math' ? <int, int>{2: 10} : null;
      },
      fetchSetCount: (s, {schoolClass = 6}) async => 0,
      probeBank: (s, {schoolClass = 6}) async => false,
    );
    expect(probed, 2);
    expect(result.subjects[0].hasGuide, isTrue);
    expect(result.subjects[1].hasGuide, isFalse);
  });
}
