// Route: /today — today's plan. Reads the SAME stores Home reads
// (LearnStore summary, LocalStore profile goal, saved questions);
// no new source and no invented minutes.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/local_store.dart';
import '../../l10n/language_provider.dart';
import '../../theme/themed_scaffold.dart';
import '../../theme/widgets/app_state_view.dart';
import '../learn/learn_store.dart';
import 'today_body.dart';
import 'today_strings.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  Future<TodayInfo>? _future;

  Future<TodayInfo> _load() async {
    final summary = await LearnStore.summary();
    final saved = await LocalStore.savedQuestions();
    var goal = 0;
    final profileJson = await LocalStore.readProfile();
    if (profileJson != null) {
      try {
        final m = jsonDecode(profileJson) as Map<String, dynamic>;
        goal = (m['daily_goal_minutes'] as num?)?.toInt() ?? 0;
      } catch (_) {}
    }
    return TodayInfo(
      todayLessons: summary.lessonsToday,
      goalMinutes: goal,
      totalLessons: summary.lessonsOpened,
      chaptersOpened: summary.chaptersOpened,
      savedCount: saved.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? todayStringsBn : todayStringsEn;
        _future ??= _load();
        return ThemedScaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/home'),
            ),
            title: Text(s['title']!),
          ),
          body: FutureBuilder<TodayInfo>(
            future: _future,
            builder: (context, snap) {
              if (!snap.hasData) {
                if (snap.hasError) {
                  return AppStateView(
                    kind: AppStateKind.error,
                    title: s['retry']!,
                    actionLabel: s['retry']!,
                    onAction: () => setState(() => _future = null),
                  );
                }
                return AppStateView(
                  kind: AppStateKind.loading,
                  title: s['loading']!,
                );
              }
              return TodayBody(info: snap.data!, bn: bn);
            },
          ),
        );
      },
    );
  }
}
