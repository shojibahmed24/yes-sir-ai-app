// Achievement rules: thresholds are data-free, so they are tested
// directly. Locked badges keep their real requirement string.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/features/progress/achievement_badges.dart';

List<AchievementBadge> badges({
  int quizCount = 0,
  int modelCount = 0,
  bool perfect = false,
  bool genius = false,
  int streakDays = 0,
}) => buildAchievementBadges(
  quizCount: quizCount,
  modelCount: modelCount,
  perfect: perfect,
  genius: genius,
  streakDays: streakDays,
);

void main() {
  test('no activity earns nothing and keeps the requirements', () {
    final list = badges();
    expect(list.length, 7);
    expect(list.every((b) => !b.earned), isTrue);
    expect(list.first.progress, '0/1');
    expect(list[1].progress, '0/5');
    expect(list[6].progress, '0/1');
  });

  test('quiz thresholds earn at 1 and 5', () {
    final one = badges(quizCount: 1);
    expect(one[0].earned, isTrue);
    expect(one[1].earned, isFalse);
    expect(one[1].progress, '1/5');
    final five = badges(quizCount: 5);
    expect(five[1].earned, isTrue);
    expect(five[1].progress, '5/5');
  });

  test('streak thresholds earn at 3 and 7', () {
    final two = badges(streakDays: 2);
    expect(two[2].earned, isFalse);
    expect(two[3].earned, isFalse);
    final three = badges(streakDays: 3);
    expect(three[2].earned, isTrue);
    expect(three[3].earned, isFalse);
    final seven = badges(streakDays: 7);
    expect(three[2].earned && seven[3].earned, isTrue);
  });

  test('perfect and genius are passed straight through', () {
    final list = badges(perfect: true, genius: true);
    expect(list[4].earned, isTrue);
    expect(list[5].earned, isTrue);
    expect(list[4].progress, '90%+');
    expect(list[5].progress, '1/1');
  });

  test('a model test earns the model badge', () {
    final list = badges(modelCount: 1);
    expect(list[6].earned, isTrue);
    expect(list[6].progress, '1/1');
  });
}
