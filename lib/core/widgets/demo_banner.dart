// Status banner. Shown on login / home so DEMO / partial-live state
// is never mistaken for a fully live app.
//
// H5 BANNER RULE (2026-10-30: keys moved server-side, so the
// client no longer checks key presence):
//   Supabase NO                      -> YES, 'demoMode'
//   Supabase YES (text via Edge, voice unwired)
//                                      -> YES, 'backendConnectedAiPartialText'
// The banner hides only when voice goes live too (aiFullyConfigured).
// AppConfig.demoMode itself is unchanged (other screens use it).
//
// H5 CONTRAST: background is the theme's secondaryContainer and the
// text is explicitly onSecondaryContainer (both now defined in
// app_theme.dart for light AND dark). The old code used bodySmall,
// whose colour is dark inkSecondary — unreadable on purple.
import 'package:flutter/material.dart';
import '../services/app_config.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/backend_strings.dart';

class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final s = isBangla ? backendStringsBn : backendStringsEn;
    // 2026-11-21: the old "partial live" banner advertised an
    // unfinished product to every real user. It now shows ONLY in
    // DEMO mode (no backend configured), where it is a true warning.
    if (AppConfig.supabaseConfigured) return const SizedBox.shrink();
    final message = s['demoMode'];
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: scheme.secondaryContainer,
      child: Text(
        message!,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: scheme.onSecondaryContainer),
        textAlign: TextAlign.center,
      ),
    );
  }
}
