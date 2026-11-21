// Route: /notifications
// Every item tap opens a real in-app detail dialog (title + full
// body) with a button that goes to that item's target screen, and
// marks that item read. Mark-all-read and clear are persisted in
// SharedPreferences, so they survive a restart. Clearing removes
// the list and shows a real empty state, not a placeholder list.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/notifications_strings.dart';
import '../../theme/app_theme.dart';
import 'package:yes_sir_ai/theme/themed_scaffold.dart';

class _Notif {
  final String id;
  final IconData icon;
  final String title;
  final String body;
  final String action;
  final String route;
  const _Notif(
    this.id,
    this.icon,
    this.title,
    this.body,
    this.action,
    this.route,
  );
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Set<String> _read = {};
  bool _cleared = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _read = (prefs.getStringList('ys_notif_read') ?? const []).toSet();
      _cleared = prefs.getBool('ys_notif_cleared') ?? false;
      _loaded = true;
    });
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('ys_notif_read', _read.toList());
    await prefs.setBool('ys_notif_cleared', _cleared);
  }

  // 2026-11-21: the five hardcoded rows were a "Demo list", not real
  // delivered notifications. With no push/local notification pipeline
  // yet, the honest screen is the empty state (the screen's own
  // `empty` text), never invented items.
  List<_Notif> _items(Map<String, String> s) => const [];

  void _open(_Notif item, Map<String, String> s) {
    setState(() => _read.add(item.id));
    _persist();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item.title),
        content: Text(item.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(s['open']!),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.push(item.route);
            },
            child: Text(item.action.isEmpty ? s['open']! : item.action),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = isBangla ? notificationsStringsBn : notificationsStringsEn;
    final items = _cleared ? const <_Notif>[] : _items(s);
    return ThemedScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          // Return to the screen that opened this one (Profile or
          // Home), never a hardcoded /home.
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text(s['title']!),
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                24 + MediaQuery.of(context).padding.bottom,
              ),
              children: [
                Text(
                  s['centre']!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                // Mark-all / clear act on real items only: with an
                // empty list they were dead controls.
                if (items.isNotEmpty)
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _read = items.map((i) => i.id).toSet();
                            });
                            _persist();
                          },
                          child: Text(s['markAll']!),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() => _cleared = true);
                          _persist();
                        },
                        child: Text(s['clear']!),
                      ),
                    ],
                  ),
                if (items.isEmpty) ...[
                  const SizedBox(height: 32),
                  Icon(
                    Icons.notifications_none,
                    size: 48,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s['empty']!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s['emptyHint']!,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/settings'),
                      icon: const Icon(Icons.tune, size: 18),
                      label: Text(s['openSettings']!),
                    ),
                  ),
                ] else ...[
                  // Phase 16 (M8): NO fake Today/Earlier grouping by
                  // list position — these items carry no stored dates,
                  // so they are shown as one honest ungrouped list
                  // labelled as a demo/static list.
                  Text(
                    s['demoNote']!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  for (final item in items) _tile(item, s),
                ],
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.tune, color: AppTheme.primary),
                    title: Text(s['prefs']!),
                    subtitle: Text(s['prefsSub']!),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/settings'),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _tile(_Notif item, Map<String, String> s) {
    final isUnread = !_read.contains(item.id);
    return Card(
      child: ListTile(
        leading: Stack(
          children: [
            Icon(item.icon, color: AppTheme.primary),
            if (isUnread)
              const Positioned(
                right: 0,
                top: 0,
                child: CircleAvatar(radius: 4, backgroundColor: Colors.red),
              ),
          ],
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.body),
            if (item.action.isNotEmpty)
              Text(
                item.action,
                style: const TextStyle(
                  color: AppTheme.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        onTap: () => _open(item, s),
      ),
    );
  }
}
