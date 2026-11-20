// Settings — notifications, class and profile-details groups.
// Split out of settings_screen.dart (250-line cap): the screen
// still owns every value and the Save write, this widget only
// renders the given state and reports edits through callbacks.
// No storage call happens here, so Save stays the one writer for
// notifications and profile fields. Class may only be changed on
// the Settings route — this group is that one entry point.
import 'package:flutter/material.dart';

import '../../../l10n/language_provider.dart';
import '../../../l10n/pages/settings_strings.dart';
import '../../../theme/app_tokens.dart';
import 'settings_group_card.dart';

class SettingsAccountSection extends StatelessWidget {
  const SettingsAccountSection({
    super.key,
    required this.daily,
    required this.tests,
    required this.streak,
    required this.onDailyChanged,
    required this.onTestsChanged,
    required this.onStreakChanged,
    required this.schoolClass,
    required this.onClassChanged,
    required this.nameController,
    required this.schoolController,
    required this.goalController,
    required this.guardianNameController,
    required this.guardianPhoneController,
  });

  final bool daily;
  final bool tests;
  final bool streak;
  final ValueChanged<bool> onDailyChanged;
  final ValueChanged<bool> onTestsChanged;
  final ValueChanged<bool> onStreakChanged;
  final String? schoolClass;
  final ValueChanged<String> onClassChanged;
  final TextEditingController nameController;
  final TextEditingController schoolController;
  final TextEditingController goalController;
  final TextEditingController guardianNameController;
  final TextEditingController guardianPhoneController;

  @override
  Widget build(BuildContext context) {
    final s = isBangla ? settingsStringsBn : settingsStringsEn;
    return Column(
      children: [
        SettingsGroupCard(
          title: s['notifications']!,
          // Honest label: these toggles save a preference but
          // control no real push/local notification yet.
          footnote: s['notifNote']!,
          children: [
            SwitchListTile(
              title: Text(s['dailyReminder']!),
              subtitle: Text(s['reminderTime']!),
              value: daily,
              contentPadding: EdgeInsets.zero,
              onChanged: onDailyChanged,
            ),
            SwitchListTile(
              title: Text(s['testUpdates']!),
              value: tests,
              contentPadding: EdgeInsets.zero,
              onChanged: onTestsChanged,
            ),
            SwitchListTile(
              title: Text(s['streakAlert']!),
              value: streak,
              contentPadding: EdgeInsets.zero,
              onChanged: onStreakChanged,
            ),
          ],
        ),
        const SizedBox(height: Sp.lg),
        SettingsGroupCard(
          title: s['classSection']!,
          subtitle: s['classSub']!,
          child: DropdownButton<String>(
            value: schoolClass,
            hint: Text(s['selectClass']!),
            isExpanded: true,
            items: const ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10']
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text('${s['classLabel']} $c'),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) onClassChanged(v);
            },
          ),
        ),
        const SizedBox(height: Sp.lg),
        SettingsGroupCard(
          title: s['profileDetails']!,
          subtitle: s['profileDetailsSub']!,
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: s['editName']!),
              ),
              const SizedBox(height: Sp.md),
              TextField(
                controller: schoolController,
                decoration: InputDecoration(labelText: s['editSchool']!),
              ),
              const SizedBox(height: Sp.md),
              TextField(
                controller: goalController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: s['editGoal']!),
              ),
              const SizedBox(height: Sp.md),
              TextField(
                controller: guardianNameController,
                decoration: InputDecoration(labelText: s['editGuardianName']!),
              ),
              const SizedBox(height: Sp.md),
              TextField(
                controller: guardianPhoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: s['editGuardianPhone']!),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
