// Route: /about
// Version + package are REAL app data: version comes from the
// installed package via package_info_plus (never a hardcoded number
// that drifts from pubspec), package com.yessirai.app. The terms
// button does NOT fake a full legal text: it opens a dialog stating
// plainly that the full terms/privacy text is not in the app yet,
// plus the real rules that do apply (voice premium-only, Play
// Billing only).
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/language_provider.dart';
import '../../l10n/pages/help_about_strings.dart';
import 'package:yes_sir_ai/theme/themed_scaffold.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _version = '${info.version}+${info.buildNumber}');
    } catch (_) {
      // Tests / unsupported platform: keep the placeholder.
    }
  }

  Future<void> _open(BuildContext context, String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final s = isBangla ? aboutStringsBn : aboutStringsEn;
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
          const CircleAvatar(
            radius: 40,
            child: Text('🤖', style: TextStyle(fontSize: 36)),
          ),
          const SizedBox(height: 16),
          Text(s['body']!, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 12),
          Text(s['features']!, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          Text(
            s['version']!.replaceFirst(
              '{v}',
              _version.isEmpty ? '…' : _version,
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(s['package']!, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          // Legal links (2026-11-21): hosted bilingual pages open in
          // the browser; no legal text is duplicated inside the app.
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: () => _open(
                  context,
                  'https://shojibahmed24.github.io/yes-sir-ai-app/privacy-policy.html',
                ),
                child: Text(s['privacy']!),
              ),
              TextButton(
                onPressed: () => _open(
                  context,
                  'https://shojibahmed24.github.io/yes-sir-ai-app/terms.html',
                ),
                child: Text(s['terms']!),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            child: Text(s['home']!),
          ),
        ],
      ),
    );
  }
}
