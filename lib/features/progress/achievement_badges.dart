// Achievement badge rules, in one pure place so the thresholds can
// be tested without storage: earned state and the "x/y" progress
// string are computed from REAL counters only.
import 'package:flutter/material.dart';

class AchievementBadge {
  const AchievementBadge({
    required this.titleKey,
    required this.subKey,
    required this.earned,
    required this.progress,
    required this.icon,
  });
  final String titleKey;
  final String subKey;
  final bool earned;
  final String progress;
  final IconData icon;
}

List<AchievementBadge> buildAchievementBadges({
  required int quizCount,
  required int modelCount,
  required bool perfect,
  required bool genius,
  required int streakDays,
}) => [
  AchievementBadge(
    titleKey: 'badgeFirst',
    subKey: 'badgeFirstSub',
    earned: quizCount >= 1,
    progress: '$quizCount/1',
    icon: Icons.play_arrow,
  ),
  AchievementBadge(
    titleKey: 'badgeQuiz5',
    subKey: 'badgeQuiz5Sub',
    earned: quizCount >= 5,
    progress: '$quizCount/5',
    icon: Icons.bolt,
  ),
  AchievementBadge(
    titleKey: 'badgeStreak3',
    subKey: 'badgeStreak3Sub',
    earned: streakDays >= 3,
    progress: '$streakDays/3',
    icon: Icons.local_fire_department,
  ),
  AchievementBadge(
    titleKey: 'badgeStreak7',
    subKey: 'badgeStreak7Sub',
    earned: streakDays >= 7,
    progress: '$streakDays/7',
    icon: Icons.local_fire_department,
  ),
  AchievementBadge(
    titleKey: 'badgeGenius',
    subKey: 'badgeGeniusSub',
    earned: genius,
    progress: genius ? '90%+' : '<90%',
    icon: Icons.calculate,
  ),
  AchievementBadge(
    titleKey: 'badgePerfect',
    subKey: 'badgePerfectSub',
    earned: perfect,
    progress: perfect ? '1/1' : '0/1',
    icon: Icons.star,
  ),
  AchievementBadge(
    titleKey: 'badgeModel',
    subKey: 'badgeModelSub',
    earned: modelCount >= 1,
    progress: '$modelCount/1',
    icon: Icons.assignment,
  ),
];
