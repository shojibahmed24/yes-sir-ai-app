import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/services/auth_recovery_listener.dart';
import 'core/services/reminder_service.dart';
import 'core/services/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Crash-safety hooks (2026-11-21): without a crash service, at least
  // never die silently and never lose the frame. Nothing sensitive is
  // logged — the error object only.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
  runZonedGuarded(
    () async {
      // DEMO mode if no Supabase keys are configured - never crashes.
      await initBackend();
      // Refresh the session once at start: an expired access token is
      // what made every guide-bank call answer 401 after a while.
      try {
        await supabaseOrNull?.auth.refreshSession();
      } catch (_) {
        // Offline: the anon-retry path keeps public reads working.
      }
      // No-op in DEMO mode; in real mode it routes password-recovery
      // email links to /reset-password (see auth_recovery_listener).
      startAuthRecoveryListener();
      runApp(const ProviderScope(child: YesSirApp()));
      // Local reminders (2026-11-22): permission + schedules are set
      // AFTER the first frame, so a denied permission never delays
      // the app from opening.
      unawaited(ReminderService.reschedule());
    },
    (error, stack) {
      debugPrint('Uncaught error: $error');
    },
  );
}
