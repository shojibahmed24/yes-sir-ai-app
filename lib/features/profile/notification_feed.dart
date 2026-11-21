// Real notification feed (S5.1): built from the app's actual state —
// no demo rows. Each item has a date-stamped id so read/unread is
// per-day, and a route that completes the action.
import 'package:flutter/material.dart';
import '../../core/services/local_store.dart';
import '../../l10n/pages/notifications_strings.dart';
import '../learn/learn_store.dart';
import '../practice/practice_store.dart';
import '../../core/services/progress_service.dart';

class NotifItem {
  const NotifItem(
    this.id,
    this.icon,
    this.title,
    this.body,
    this.action,
    this.route,
  );
  final String id;
  final IconData icon;
  final String title;
  final String body;
  final String action;
  final String route;
}

Future<List<NotifItem>> buildNotificationFeed({required bool bn}) async {
  final s = bn ? notificationsStringsBn : notificationsStringsEn;
  final sum = await progressService.summary();
  final saved = await LocalStore.savedQuestions();
  final today = PracticeSession.today();
  final stamp = today.replaceAll('-', '');
  final out = <NotifItem>[];

  final didQuiz = sum.attempts.any((a) => a.kind == 'quiz' && a.date == today);
  if (!didQuiz) {
    out.add(
      NotifItem(
        'streak-$stamp',
        Icons.local_fire_department,
        s['streakTitle']!,
        s['streakBody']!,
        s['open']!,
        '/practice',
      ),
    );
  }
  if (sum.weakChapters.isNotEmpty) {
    out.add(
      NotifItem(
        'weak-$stamp',
        Icons.psychology,
        s['weakTitle']!,
        s['weakBody']!,
        s['open']!,
        '/practice',
      ),
    );
  }
  out.add(
    NotifItem(
      'test-$stamp',
      Icons.assignment_outlined,
      s['testTitle']!,
      s['testBody']!,
      s['open']!,
      '/guide-model-tests',
    ),
  );
  if (sum.goalMinutes > 0 && sum.goalProgress < 1) {
    out.add(
      NotifItem(
        'goal-$stamp',
        Icons.flag_outlined,
        s['goalTitle']!,
        s['goalBody']!,
        s['open']!,
        '/today',
      ),
    );
  }
  final savedQuestions = saved.where((e) => !e.startsWith('book:')).length;
  if (savedQuestions > 0) {
    out.add(
      NotifItem(
        'saved-$stamp',
        Icons.bookmark_border,
        s['savedTitle']!,
        s['savedBody']!.replaceFirst('{n}', '$savedQuestions'),
        s['open']!,
        '/saved',
      ),
    );
  }
  // Recent questions are LearnStore's own list; one item when present.
  final recent = await LearnStore.recentQuestions();
  if (recent.isNotEmpty) {
    out.add(
      NotifItem(
        'recent-$stamp',
        Icons.history,
        s['recentTitle']!,
        s['recentBody']!,
        s['open']!,
        '/search-flow',
      ),
    );
  }
  return out;
}
