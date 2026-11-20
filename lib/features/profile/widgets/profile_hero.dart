// Profile hero band: avatar + name + class on the app's gradient.
// White text only on the deep stops (WCAG AA); nothing here reads
// storage — the screen passes the saved values in.
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import 'profile_avatar.dart';

class ProfileHero extends StatelessWidget {
  const ProfileHero({
    super.key,
    required this.name,
    required this.displayName,
    required this.classInfo,
    required this.idLine,
    this.localPath,
    this.remoteUrl,
  });
  final String name;
  final String displayName;
  final String classInfo;
  final String idLine;
  final String? localPath;
  final String? remoteUrl;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      key: const Key('profile-hero'),
      width: double.infinity,
      padding: const EdgeInsets.all(Sp.xl),
      decoration: BoxDecoration(
        gradient: dark ? AppTheme.heroGradientDark : AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(Rad.xl),
      ),
      child: Column(
        children: [
          ProfileAvatar(
            name: name,
            localPath: localPath,
            remoteUrl: remoteUrl,
            radius: 40,
          ),
          const SizedBox(height: Sp.md),
          Text(
            displayName,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          Text(
            classInfo,
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          if (idLine.isNotEmpty)
            Text(
              idLine,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}
