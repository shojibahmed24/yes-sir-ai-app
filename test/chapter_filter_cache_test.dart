// Chapter filter cache: same inputs reuse the last result, any real
// input change re-filters, and the epoch key forces a refresh.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/services/textbook_chapter_service.dart';
import 'package:yes_sir_ai/features/learn/chapter_filter_cache.dart';

TextbookChapterQuestion _q({
  required String id,
  String text = '২ + ২ কত?',
  String type = 'mcq',
  int page = 10,
}) => TextbookChapterQuestion(
  id: id,
  questionText: text,
  page: page,
  questionType: type,
);

void main() {
  test('same inputs return the cached list, changed inputs re-filter', () {
    final cache = ChapterFilterCache();
    final all = [_q(id: 'a'), _q(id: 'b', text: '৩ + ৩ কত?', page: 12)];
    final first = cache.filter(
      all: all,
      type: 'all',
      query: '',
      pageText: '',
      epoch: 0,
    );
    expect(first.length, 2);
    final again = cache.filter(
      all: all,
      type: 'all',
      query: '',
      pageText: '',
      epoch: 0,
    );
    expect(identical(first, again), isTrue, reason: 'cache hit');
    final filtered = cache.filter(
      all: all,
      type: 'all',
      query: '৩ + ৩',
      pageText: '',
      epoch: 0,
    );
    expect(filtered.length, 1);
    expect(filtered.single.id, 'b');
  });

  test('a page filter and an epoch change both invalidate', () {
    final cache = ChapterFilterCache();
    final all = [_q(id: 'a', page: 10), _q(id: 'b', page: 12)];
    expect(
      cache
          .filter(all: all, type: 'all', query: '', pageText: '10', epoch: 0)
          .single
          .id,
      'a',
    );
    expect(
      cache
          .filter(all: all, type: 'all', query: '', pageText: '12', epoch: 0)
          .single
          .id,
      'b',
    );
    final before = cache.filter(
      all: all,
      type: 'all',
      query: '',
      pageText: '',
      epoch: 1,
    );
    final after = cache.filter(
      all: all,
      type: 'all',
      query: '',
      pageText: '',
      epoch: 2,
    );
    expect(identical(before, after), isFalse, reason: 'epoch refresh');
  });
}
