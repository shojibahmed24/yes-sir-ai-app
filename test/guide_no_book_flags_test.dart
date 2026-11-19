// No-book flag resolution: the server gates every guide-bank
// action on books, so found:false + reason no-book is a
// definitive empty (not unknown). Without this mapping, the
// 14 book-less class-9 subjects could never resolve complete,
// so home subjects were never cached and refetched on every
// mount — the repeated-loading bug.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/backend_models.dart';
import 'package:yes_sir_ai/core/services/guide_bank_service.dart';
import 'package:yes_sir_ai/core/services/guide_subject_flags.dart';
import 'package:yes_sir_ai/core/services/model_test_set_service.dart';

void main() {
  test('chapters parser: no-book is empty, other found-false is null',
      () {
    expect(parseGuideChaptersResponse(null), isNull);
    expect(
      parseGuideChaptersResponse({'found': false, 'reason': 'no-book'}),
      isEmpty,
    );
    expect(parseGuideChaptersResponse({'found': false}), isNull);
    expect(
      parseGuideChaptersResponse(
          {'found': false, 'reason': 'pilot-columns-missing'}),
      isNull,
    );
    expect(
      parseGuideChaptersResponse({
        'found': true,
        'guideChapters': [
          {'chapter': 8, 'totalCount': 100},
          {'chapter': 9, 'totalCount': 50},
        ],
      }),
      {8: 100, 9: 50},
    );
  });

  test('sets: no-book is empty list, other found-false is null',
      () async {
    final noBook = ModelTestSetService(
      post: (_, {endpoint}) async => {'found': false, 'reason': 'no-book'},
    );
    expect(await noBook.fetchSetsFromServer('science', schoolClass: 9),
        isEmpty);
    final unknown = ModelTestSetService(
      post: (_, {endpoint}) async => {'found': false},
    );
    expect(await unknown.fetchSetsFromServer('science', schoolClass: 9),
        isNull);
    final empty = ModelTestSetService(
      post: (_, {endpoint}) async => {'found': true, 'sets': []},
    );
    expect(await empty.fetchSetsFromServer('science', schoolClass: 9),
        isEmpty);
  });

  test('bank presence: no-book is false, other found-false is null',
      () {
    expect(chapterlessBankPresence(null), isNull);
    expect(
      chapterlessBankPresence({'found': false, 'reason': 'no-book'}),
      isFalse,
    );
    expect(chapterlessBankPresence({'found': false}), isNull);
    expect(chapterlessBankPresence({'found': true, 'total': 0}), isFalse);
    expect(chapterlessBankPresence({'found': true, 'total': 2}), isTrue);
    expect(
      chapterlessBankPresence({'found': true, 'questions': []}),
      isFalse,
    );
    expect(
      chapterlessBankPresence({
        'found': true,
        'questions': [{}],
      }),
      isTrue,
    );
  });

  test('withGuideFlags: civics chapter count adds set-only chapters',
      () async {
    final result = await withGuideFlags(
      [
        SubjectInfo(
          id: 'civics',
          nameBn: 'পৌরনীতি',
          nameEn: 'Civics',
          locked: true,
          chapterCount: 0,
        ),
      ],
      9,
      // Edge chapter list returns only 6/7/8; ch 1/3/4 are
      // set-only and must still count (tile shows 6, not 3).
      fetchChapters: (s, {schoolClass = 6}) async =>
          <int, int>{6: 100, 7: 100, 8: 100},
      fetchSetCount: (s, {schoolClass = 6}) async => 0,
      probeBank: (s, {schoolClass = 6}) async => false,
    );
    expect(result.complete, isTrue);
    expect(result.subjects.single.hasGuide, isTrue);
    expect(result.subjects.single.guideChapterCount, 6);
  });

  test('withGuideFlags: non-civics chapter count is unchanged',
      () async {
    final result = await withGuideFlags(
      [
        SubjectInfo(
          id: 'math',
          nameBn: 'গণিত',
          nameEn: 'Math',
          locked: true,
          chapterCount: 0,
        ),
      ],
      9,
      fetchChapters: (s, {schoolClass = 6}) async =>
          <int, int>{2: 50, 3: 50},
      fetchSetCount: (s, {schoolClass = 6}) async => 0,
      probeBank: (s, {schoolClass = 6}) async => false,
    );
    expect(result.subjects.single.guideChapterCount, 2);
  });
}
