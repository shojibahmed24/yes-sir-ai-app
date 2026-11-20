// "Delete account" row + its confirm flow, split out so the profile
// screen stays under the line cap. Deletion goes through the
// account-delete Edge function (session-verified, service role does the
// delete); on success the caller signs out and leaves the profile.
import 'package:flutter/material.dart';

import '../../../core/services/account_service.dart';
import 'profile_menu_tile.dart';

class DeleteAccountTile extends StatelessWidget {
  const DeleteAccountTile({
    super.key,
    required this.s,
    required this.onDeleted,
  });
  final Map<String, String> s;
  final Future<void> Function() onDeleted;

  Future<void> _confirm(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s['deleteAccountConfirm']!),
        content: Text(s['deleteAccountBody']!),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s['deleteAccountCancel']!),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(s['deleteAccount']!),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final result = await deleteMyAccount();
    if (!context.mounted) return;
    if (result == DeleteAccountResult.done) {
      await onDeleted();
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s['deleteAccountFailed']!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileMenuTile(
      icon: Icons.delete_forever_outlined,
      title: s['deleteAccount']!,
      subtitle: s['deleteAccountSub']!,
      onTap: () => _confirm(context),
    );
  }
}
