// Route: /help
// Every FAQ expands with its real answer (ExpansionTile). The
// contact button does NOT send a message anywhere: it opens a dialog
// with real in-app support info (app + package + where to fix
// language/class), because no support email/channel exists in the
// app data yet and inventing one would be fake.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/contact_info.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/help_about_strings.dart';
import 'package:yes_sir_ai/theme/themed_scaffold.dart';

class HelpFaqScreen extends StatelessWidget {
  const HelpFaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = isBangla ? helpStringsBn : helpStringsEn;
    final faqs = [
      (s['q1']!, s['a1']!),
      (s['q2']!, s['a2']!),
      (s['q3']!, s['a3']!),
      (s['q4']!, s['a4']!),
    ];
    return ThemedScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
          },
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
          for (final f in faqs)
            Card(
              child: ExpansionTile(
                title: Text(f.$1),
                children: [
                  Padding(padding: const EdgeInsets.all(16), child: Text(f.$2)),
                ],
              ),
            ),
          const SizedBox(height: 16),
          // Real support contact (Play listing requirement): the old
          // dialog only repeated the package name.
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s['contactTitle']!,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => launchUrl(
                      Uri.parse(
                        'mailto:$supportEmail?subject=Yes%20Sir%20AI%20support',
                      ),
                    ),
                    child: Text(
                      supportEmail,
                      style: const TextStyle(
                        color: Color(0xFF2A4BD7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s['contactBody']!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => launchUrl(
                      Uri.parse(accountDeletionUrl),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Text(s['deleteDataLink']!),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
