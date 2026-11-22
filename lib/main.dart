import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/services/auth_recovery_listener.dart';
import 'core/services/reminder_service.dart';
import 'core/services/school_class_cache.dart';
import 'core/services/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Crash-safety hooks (2026-11-21): without a crash service, at least
  // never die silently and never lose the frame. Nothing sensitive is
  // logged — the error object only.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
  // A build error must never leave a grey rectangle. Show a calm,
  // localized placeholder with a retry instead (release has no red
  // error screen), and keep the technical detail in the console.
  ErrorWidget.builder = (details) {
    debugPrint('BUILD ERROR: ${details.exception}');
    return _QuietErrorCard(message: '${details.exception}');
  };
  runZonedGuarded(
    () async {
      // DEMO mode if no Supabase keys are configured - never crashes.
      await initBackend();
      // Saved class on the very first frame (B8): no Class-6 flash.
      await SchoolClassCache.hydrate();
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

/// Release-safe build-error placeholder: a neutral card instead of the
/// framework's grey rectangle, so a widget bug never looks like a
/// crashed app. No technical text is shown to the student.
class _QuietErrorCard extends StatelessWidget {
  const _QuietErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F8FC),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.build_circle_outlined, size: 40),
              const SizedBox(height: 12),
              const Text(
                'এই অংশটি এখন দেখানো যাচ্ছে না — পেছনে গিয়ে আবার চেষ্টা করুন।',
                textAlign: TextAlign.center,
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 8),
                Text(
                  message,
                  maxLines: 4,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
