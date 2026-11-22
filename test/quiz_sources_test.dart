// Round 3 quiz registry: one subject's quiz is filled from every
// source of THAT subject (guide first, then its own bank), never
// mixed with another subject and never duplicated.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/backend_models.dart';
import 'package:yes_sir_ai/features/practice/quiz_sources.dart';

QuizItem _item(String id) => QuizItem(
  id: id,
  questionBn: 'প্রশ্ন $id',
  questionEn: 'Question $id',
  options: const ['ক', 'খ', 'গ', 'ঘ'],
  correctIndex: 0,
);

void main() {
  test('guide items lead and are never duplicated', () async {
    final pool = await buildSubjectQuizPool(
      subject: 'math',
      count: 5,
      guideFetcher: () async => [_item('g1'), _item('g2'), _item('g2')],
      bankFetcher: () => [_item('b1'), _item('g1'), _item('b2')],
    );
    expect(pool.items.map((q) => q.id).toList(), ['g1', 'g2', 'b1', 'b2']);
    expect(pool.guideCount, 2);
    expect(pool.bankCount, 2);
    expect(pool.usedBank, isTrue);
  });

  test('a full guide set leaves the bank untouched', () async {
    final pool = await buildSubjectQuizPool(
      subject: 'science',
      count: 2,
      guideFetcher: () async => [_item('g1'), _item('g2')],
      bankFetcher: () => [_item('b1')],
    );
    expect(pool.items.length, 2);
    expect(pool.bankCount, 0);
    expect(pool.usedBank, isFalse);
  });

  test('a failing guide call still yields the subject bank', () async {
    final pool = await buildSubjectQuizPool(
      subject: 'math',
      count: 3,
      guideFetcher: () async => throw StateError('offline'),
      bankFetcher: () => [_item('b1'), _item('b2')],
    );
    expect(pool.items.map((q) => q.id).toList(), ['b1', 'b2']);
    expect(pool.guideCount, 0);
  });

  test('nothing anywhere = an honestly empty pool', () async {
    final pool = await buildSubjectQuizPool(subject: 'math', count: 5);
    expect(pool.isEmpty, isTrue);
  });
}
