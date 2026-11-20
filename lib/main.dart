import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/services/auth_recovery_listener.dart';
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
      // No-op in DEMO mode; in real mode it routes password-recovery
      // email links to /reset-password (see auth_recovery_listener).
      startAuthRecoveryListener();
      runApp(const ProviderScope(child: YesSirApp()));
    },
    (error, stack) {
      debugPrint('Uncaught error: $error');
    },
  );
}
