// Phase 2 quiz explanation (pure, offline): bank-id detection
// and the option-wise prompt builder. The live Mode G path
// needs the Edge and is covered by the phone checklist, not
// by unit tests.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/backend_models.dart';
import 'package:yes_sir_ai/core/services/quiz_explanation_service.dart';

QuizItem _item() => const QuizItem(
      id: 'pilot3-mcq_bank-015',
      questionBn: 'q',
      questionEn: 'q',
      options: ['১৫', '২০', '২৪', '২৫'],
      correctIndex: 2,
    );

void main() {
  group('isBankQuizId', () {
    test('bank prefixes are bank ids', () {
      for (final id in ['mq1', 'mm6', 'mp2', 'sq1', 'sm8', 'sp1']) {
        expect(isBankQuizId(id), isTrue, reason: id);
      }
    });
    test('guide ids are not bank ids', () {
      expect(isBankQuizId('pilot3-mcq_bank-015'), isFalse);
      expect(isBankQuizId('class7-math-bn-guide-ch2-p44-ex21-mcq18'),
          isFalse);
      expect(isBankQuizId(''), isFalse);
    });
  });

  group('optionWiseInstruction', () {
    test('bangla names every option + the verified key + LaTeX', () {
      final text = optionWiseInstruction(
          item: _item(), correctLetter: 'গ', bangla: true);
      expect(text, contains('ক) ১৫'));
      expect(text, contains('খ) ২০'));
      expect(text, contains('গ) ২৪'));
      expect(text, contains('ঘ) ২৫'));
      expect(text, contains('সঠিক উত্তর: গ'));
      expect(text, contains(r'$...$'));
      expect(text, contains(r'\frac{}{}'));
    });
    test('english names every option + the verified key + LaTeX', () {
      final text = optionWiseInstruction(
          item: _item(), correctLetter: 'C', bangla: false);
      expect(text, contains('A) ১৫'));
      expect(text, contains('B) ২০'));
      expect(text, contains('C) ২৪'));
      expect(text, contains('D) ২৫'));
      expect(text, contains('Correct answer: C'));
      expect(text, contains(r'$...$'));
    });
  });

  group('acceptedAnswerLabel', () {
    QuizItem multi() => const QuizItem(
          id: 'p2',
          questionBn: 'q',
          questionEn: 'q',
          options: ['have', 'enjoy', 'go', 'play'],
          correctIndex: 0,
          correctIndices: [0, 1],
        );

    test('multi-key item names every accepted letter', () {
      expect(
          acceptedAnswerLabel(
              item: multi(), answerKey: '["have", "enjoy"]', bangla: true),
          'ক, খ');
      expect(
          acceptedAnswerLabel(
              item: multi(), answerKey: '["have", "enjoy"]', bangla: false),
          'A, B');
    });

    test('JSON-list key maps to letters even without item indices', () {
      expect(
          acceptedAnswerLabel(
              item: _item(), answerKey: '["২৪", "২৫"]', bangla: true),
          'গ, ঘ');
    });

    test('single-key item is unchanged (one letter, raw key kept)', () {
      expect(acceptedAnswerLabel(item: _item(), answerKey: 'গ', bangla: true),
          'গ');
      expect(
          acceptedAnswerLabel(item: _item(), answerKey: '', bangla: true),
          'গ');
    });

    test('multi-key prompt pluralises the correct-option wording', () {
      final text = optionWiseInstruction(
          item: multi(), correctLetter: 'ক, খ', bangla: true, multiKey: true);
      expect(text, contains('সঠিক অপশনগুলো কেন ঠিক'));
      expect(text, contains('সঠিক উত্তর: ক, খ'));
    });
  });
}
