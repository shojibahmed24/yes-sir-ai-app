// Route: /profile
// Profile hub. Buttons go to Settings, Parent PIN, Premium, Help.
// Phase 17 (L1): the old duplicate is gone — 'My info' and the
// separate 'Settings' tile BOTH went to /settings, so only one tile
// remains, retitled 'My info & settings' (that screen IS the profile
// edit form: name / school / class / goal + language / theme /
// notifications). About (/about, previously unreachable) and
// Notifications (/notifications, previously only from the home top
// bar) now have tiles here too.
// Sign-out calls AuthService.signOut (clears Supabase + local
// session) and goes to /login. Class change is NOT here (Settings
// only). Name / class / school / goal show the saved profile when
// one exists (registration or a Settings edit); otherwise the
// placeholder strings are shown, never invented as real data.
// Stats below are REAL only: streak from progress_service.summary(),
// medals = badges earned under the achievements screen's own rules
// applied to that same summary, saved count from
// LocalStore.savedQuestions(). Study time has no store anywhere, so
// the week-time line is an honest empty state, never a number.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/local_store.dart';
import '../../core/services/profile_service.dart';
import '../../core/services/profile_source.dart';
import '../../core/services/progress_service.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/profile_strings.dart';
import '../parent/parent_session.dart';
import 'widgets/delete_account_tile.dart';
import 'widgets/profile_hero.dart';
import 'widgets/profile_stats.dart';
import '../../theme/app_theme.dart';
import '../learn/widgets/digits.dart';
import 'widgets/profile_menu_tile.dart';
import '../../theme/themed_scaffold.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  // Real stats; 0 until the stores load (a fresh install honestly
  // shows 0, never a made-up number).
  int _streakDays = 0;
  int _medals = 0;
  int _savedCount = 0;

  @override
  void initState() {
    super.initState();
    // Batch 2, item 6: subscribe to the single profile source, so a
    // Settings name/picture edit refreshes Profile even though this
    // screen stays alive underneath the pushed Settings route.
    profileNotifier.addListener(_onProfileChanged);
    profileService.loadProfile().then((p) {
      if (mounted) setState(() => _profile = p);
    });
    _loadStats();
  }

  void _onProfileChanged() {
    if (mounted) setState(() => _profile = profileNotifier.value);
  }

  @override
  void dispose() {
    profileNotifier.removeListener(_onProfileChanged);
    super.dispose();
  }

  Future<void> _loadStats() async {
    final summary = await progressService.summary();
    final saved = await LocalStore.savedQuestions();
    if (!mounted) return;
    setState(() {
      _streakDays = summary.streakDays;
      _medals = _earnedMedals(summary);
      _savedCount = saved.length;
    });
  }

  // Earned-badge count, using EXACTLY the badge rules in
  // achievements_screen.dart applied to the same summary. If that
  // screen's badge set ever changes, this must change with it.
  int _earnedMedals(ProgressSummary sum) {
    final quizCount = sum.attempts.where((a) => a.kind == 'quiz').length;
    final modelCount = sum.attempts.where((a) => a.kind == 'model').length;
    final perfect = sum.attempts.any(
      (a) => a.total > 0 && a.correct == a.total,
    );
    final genius = sum.totalAnswered >= 5 && sum.averageScore >= 90;
    var earned = 0;
    if (quizCount >= 1) earned++;
    if (quizCount >= 5) earned++;
    if (sum.streakDays >= 3) earned++;
    if (sum.streakDays >= 7) earned++;
    if (genius) earned++;
    if (perfect) earned++;
    if (modelCount >= 1) earned++;
    return earned;
  }

  Future<void> _signOut() async {
    await authService.signOut();
    parentSession.clear();
    if (mounted) context.go('/login');
  }

  Widget _header(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 6),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final s = isBangla ? profileStringsBn : profileStringsEn;
    // Batch 2, item 6: name/picture from the single profile source.
    final name = ProfileFields.name(_profile);
    final school = (_profile?['school_name'] as String?) ?? '';
    final cls = _profile?['school_class'];
    final displayName = name.isEmpty ? s['student']! : name;
    final classInfo = cls == null
        ? s['classInfo']!
        : ('${s['classLabel']!} $cls') + (school.isEmpty ? '' : ' • $school');
    // Real stored id only (profile_service: 'id' = Supabase userId,
    // or 'demo-user' in local DEMO). Empty / no profile = no ID line
    // at all: never show an invented student number.
    final rawId = (_profile?['id'] as String?)?.trim() ?? '';
    // One-line menu rows: same widget, same route-push, no repeated
    // five-line constructor per tile.
    Widget tile(IconData icon, String title, String sub, String route) =>
        ProfileMenuTile(
          icon: icon,
          title: title,
          subtitle: sub,
          onTap: () => context.push(route),
        );
    return ThemedScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: Text(s['title']!),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          ProfileHero(
            name: name,
            displayName: displayName,
            classInfo: classInfo,
            idLine: rawId.isEmpty ? '' : '${s['studentIdPrefix']!} $rawId',
            localPath: ProfileFields.localPicture(_profile),
            remoteUrl: ProfileFields.remotePicture(_profile),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ProfileStatCard(
                  color: AppTheme.amber,
                  icon: Icons.local_fire_department,
                  label: s['streak']!.replaceFirst(
                    '{n}',
                    numStr(_streakDays, isBangla),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ProfileStatCard(
                  color: AppTheme.primary,
                  icon: Icons.emoji_events,
                  label: s['medals']!.replaceFirst(
                    '{n}',
                    numStr(_medals, isBangla),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.bookmark),
              title: Text(
                s['saved']!.replaceFirst('{n}', numStr(_savedCount, isBangla)),
              ),
              subtitle: Text(s['weekTime']!),
            ),
          ),
          const SizedBox(height: 16),
          _header(context, s['sectionStudy']!),
          tile(Icons.bookmark_added, s['savedQ']!, s['savedQSub']!, '/saved'),
          _header(context, s['sectionAccount']!),
          tile(Icons.person, s['myInfo']!, s['myInfoSub']!, '/settings'),
          tile(
            Icons.supervisor_account,
            s['parentMode']!,
            s['parentModeSub']!,
            '/parent-pin',
          ),
          tile(
            Icons.workspace_premium,
            s['premium']!,
            s['premiumSub']!,
            '/premium',
          ),
          tile(
            Icons.notifications_outlined,
            s['notifications']!,
            s['notificationsSub']!,
            '/notifications',
          ),
          _header(context, s['sectionHelp']!),
          tile(Icons.info_outline, s['about']!, s['aboutSub']!, '/about'),
          tile(Icons.help_center, s['help']!, s['helpSub']!, '/help'),
          DeleteAccountTile(
            s: s,
            onDeleted: () async {
              await authService.signOut();
              if (context.mounted) context.go('/login');
            },
          ),
          ProfileMenuTile(
            icon: Icons.logout,
            title: s['signOut']!,
            subtitle: s['signOutSub']!,
            onTap: _signOut,
          ),
          const SizedBox(height: 16),
          Text(
            s['quote']!,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          Text(
            s['version']!,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
