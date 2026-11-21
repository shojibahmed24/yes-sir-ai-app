import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/profile_service.dart';
import '../../../core/services/profile_source.dart';
import '../../profile/widgets/profile_avatar.dart';
import '../../../l10n/language_provider.dart';
import '../../../theme/app_theme.dart';

/// Home top bar: avatar -> /profile, gear -> /settings, bell ->
/// /notifications. The gear previously pointed at /profile; fixed.
/// Greeting/class/avatar now come from the saved profile (Settings
/// edits show here); the passed-in strings are only the fallback
/// when no profile has been saved yet - never a hardcoded person.
class HomeTopBar extends StatefulWidget {
  const HomeTopBar({
    super.key,
    required this.greeting,
    required this.classChip,
    this.streakDays = 0,
    this.xp = 0,
    this.streakSuffix = 'days',
  });
  final String greeting;
  final String classChip;

  /// Real numbers from ProgressSummary (D1). Zero is honest: a new
  /// student really has no streak/xp yet.
  final int streakDays;
  final int xp;
  final String streakSuffix;

  @override
  State<HomeTopBar> createState() => _HomeTopBarState();
}

class _HomeTopBarState extends State<HomeTopBar> {
  String? _name;
  int? _schoolClass;
  String? _localPicture;
  String? _remotePicture;

  @override
  void initState() {
    super.initState();
    profileService.loadProfile().then((p) {
      if (!mounted || p == null) return;
      setState(() {
        final n = p['full_name'];
        if (n is String && n.isNotEmpty) _name = n;
        // Same picture source as the Profile hero (2026-11-21): the
        // saved photo now shows on the dashboard too.
        _localPicture = ProfileFields.localPicture(p);
        _remotePicture = ProfileFields.remotePicture(p);
        // Batch 2, item 3: parse via the shared profile source,
        // not `is int` — a String-stored class used to vanish
        // here while Settings still showed it.
        _schoolClass = ProfileService.parseSchoolClass(p['school_class']);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final bn = Localizations.localeOf(context).languageCode == 'bn';
    final name = _name;
    final greeting = name == null
        ? widget.greeting
        : bn
        ? 'হ্যালো, $name'
        : 'Hello, $name';
    final classChip = _schoolClass == null
        ? widget.classChip
        : bn
        ? 'ক্লাস $_schoolClass'
        : 'Class $_schoolClass';
    // Phase 16 (M3): language toggle reachable from Home itself, not
    // only auth screens + Settings. Language names need no translation.
    final langCode = languageNotifier.value.languageCode;
    Widget langChip(String label, String code) {
      final active = langCode == code;
      return GestureDetector(
        onTap: () => setLanguage(code),
        child: Container(
          // J1: touch target is at least 48px tall (minHeight
          // constraint, not padding alone, so it holds at any
          // font scale).
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => context.go('/profile'),
              child: ProfileAvatar(
                name: _name ?? '',
                localPath: _localPicture,
                remoteUrl: _remotePicture,
                radius: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 2),
                  Chip(
                    label: Text(classChip),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => context.go('/notifications'),
              tooltip: 'Notifications',
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.go('/settings'),
              tooltip: 'Settings',
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _statChip(
              context,
              Icons.local_fire_department,
              '${widget.streakDays} ${widget.streakSuffix}',
              AppTheme.amber,
            ),
            const SizedBox(width: 8),
            _statChip(
              context,
              Icons.star_rounded,
              '${widget.xp} XP',
              AppTheme.amber,
            ),
            const Spacer(),
            langChip('বাংলা', 'bn'),
            const SizedBox(width: 6),
            langChip('English', 'en'),
          ],
        ),
      ],
    );
  }

  Widget _statChip(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}
