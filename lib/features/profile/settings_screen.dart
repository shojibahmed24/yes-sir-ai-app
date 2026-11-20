// Route: /settings — ONLY place where class can be changed.
// Language, font, theme, notifications and profile edits persist
// here and apply LIVE app-wide. Sepia falls back to light.
// No bKash anywhere: premium is Google Play Billing only.
// Layout: appearance and account groups were split into
// widgets/ (250-line cap); this screen owns all state and writes.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/profile_service.dart';
import 'widgets/ai_provider_settings_section.dart';
import 'widgets/demo_premium_toggle.dart';
import 'widgets/settings_account_section.dart';
import 'widgets/settings_appearance_section.dart';
import 'widgets/settings_group_card.dart';
import 'widgets/settings_profile_header.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/settings_strings.dart';
import '../../theme/app_tokens.dart';
import '../../theme/theme_mode.dart';
import '../../theme/themed_scaffold.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _font = 'normal';
  String _theme = 'day';
  bool _daily = true, _tests = true, _streak = true;
  // Phase 16 (M5): NO invented defaults. Null class / empty goal mean
  // "not chosen yet"; Save must never write Class 10 / 30 min unchosen.
  String? _cls;
  late final _name = TextEditingController();
  late final _school = TextEditingController();
  late final _goal = TextEditingController();
  late final _guardianName = TextEditingController(),
      _guardianPhone = TextEditingController();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final profile = await profileService.loadProfile();
    if (!mounted) return;
    setState(() {
      _daily = prefs.getBool('ys_notif_daily') ?? true;
      _tests = prefs.getBool('ys_notif_tests') ?? true;
      _streak = prefs.getBool('ys_notif_streak') ?? true;
      _theme = prefs.getString('ys_theme') ?? 'day';
      final scale = prefs.getDouble('ys_font_scale') ?? 1.0;
      _font = scale < 1.0
          ? 'small'
          : scale > 1.0
          ? 'large'
          : 'normal';
      if (profile != null) {
        _name.text = (profile['full_name'] as String?) ?? '';
        _school.text = (profile['school_name'] as String?) ?? '';
        _guardianName.text = (profile['guardian_name'] as String?) ?? '';
        _guardianPhone.text = (profile['guardian_phone'] as String?) ?? '';
        final goal = profile['daily_goal_minutes'];
        if (goal != null) _goal.text = '$goal';
        // Batch 2, item 3: shared class parser — the same source
        // Home reads, so a String/double-stored class cannot show
        // here while vanishing on Home (or vice versa).
        final cls = ProfileService.parseSchoolClass(profile['school_class']);
        if (cls != null) _cls = '$cls';
      }
      _loaded = true;
    });
  }

  // Font and theme persist IMMEDIATELY, like language — no
  // lost-on-exit trap if Save is skipped (Phase 16, M4).
  void _setFont(String font) {
    final scale = SettingsAppearanceSection.scaleFor(font);
    setState(() => _font = font);
    fontScaleNotifier.value = scale;
    persistFontScale(scale);
  }

  void _setTheme(String theme) {
    setState(() => _theme = theme);
    themeModeNotifier.value = theme == 'night'
        ? ThemeMode.dark
        : ThemeMode.light;
    persistTheme(theme);
  }

  Future<void> _save() async {
    final s = isBangla ? settingsStringsBn : settingsStringsEn;
    // Phase 16 (M5): empty goal / no class = null = "not chosen";
    // updateProfileFields leaves a null field untouched, so Save
    // writes no default the user never chose.
    final goal = int.tryParse(_goal.text.trim());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ys_notif_daily', _daily);
    await prefs.setBool('ys_notif_tests', _tests);
    await prefs.setBool('ys_notif_streak', _streak);
    persistTheme(_theme);
    persistFontScale(SettingsAppearanceSection.scaleFor(_font));
    final ok = await profileService.updateProfileFields(
      fullName: _name.text.trim(),
      schoolName: _school.text.trim(),
      dailyGoalMinutes: goal,
      schoolClass: _cls == null ? null : int.tryParse(_cls!),
      guardianName: _guardianName.text.trim(),
      guardianPhone: _guardianPhone.text.trim(),
    );
    if (!mounted) return;
    // Local copy is always saved; ok=false only means the Supabase
    // cloud upsert failed, and the local copy still holds the edit.
    // The header refreshes itself from the profile notifier on Save.
    if (!ok) debugPrint('Settings: Supabase upsert failed, local kept');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(s['saved']!)));
  }

  @override
  void dispose() {
    _name.dispose();
    _school.dispose();
    _goal.dispose();
    _guardianName.dispose();
    _guardianPhone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = isBangla ? settingsStringsBn : settingsStringsEn;
    return ThemedScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/profile'),
        ),
        title: Text(s['title']!),
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.fromLTRB(
                Sp.xxl,
                Sp.xxl,
                Sp.xxl,
                Sp.xxl + MediaQuery.of(context).padding.bottom,
              ),
              children: [
                // Batch 2, item 6: header reads the SAVED name and
                // picture from the single profile source itself.
                SettingsProfileHeader(
                  classText: _cls == null
                      ? s['notChosen']!
                      : '${s['classLabel']} $_cls',
                ),
                const SizedBox(height: Sp.lg),
                SettingsAppearanceSection(
                  languageCode: languageNotifier.value.languageCode,
                  onLanguageChanged: (code) {
                    setLanguage(code);
                    setState(() {});
                  },
                  font: _font,
                  onFontChanged: _setFont,
                  theme: _theme,
                  onThemeChanged: _setTheme,
                ),
                const SizedBox(height: Sp.lg),
                SettingsAccountSection(
                  daily: _daily,
                  tests: _tests,
                  streak: _streak,
                  onDailyChanged: (v) => setState(() => _daily = v),
                  onTestsChanged: (v) => setState(() => _tests = v),
                  onStreakChanged: (v) => setState(() => _streak = v),
                  schoolClass: _cls,
                  onClassChanged: (v) => setState(() => _cls = v),
                  nameController: _name,
                  schoolController: _school,
                  goalController: _goal,
                  guardianNameController: _guardianName,
                  guardianPhoneController: _guardianPhone,
                ),
                const SizedBox(height: Sp.lg),
                const SettingsGroupCard(child: AiProviderSettingsSection()),
                const SizedBox(height: Sp.lg),
                // Demo-only test control: renders nothing with a real
                // backend, so it stays outside the group cards.
                const DemoPremiumToggle(),
                const SizedBox(height: Sp.xl),
                ElevatedButton(onPressed: _save, child: Text(s['save']!)),
              ],
            ),
    );
  }
}
