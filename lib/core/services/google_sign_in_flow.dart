// Google sign-in flow (A14): native first, browser OAuth as fallback.
//
// Kept out of auth_service.dart (already long) so the two paths and
// their error mapping live in one small, readable place.
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_config.dart';
import 'auth_result.dart';
import 'google_native_sign_in.dart';

/// Runs Google sign-in for [client].
///
/// ONE step only (C1): the native account picker creates the session
/// directly. There is no automatic browser fallback any more — the
/// browser flow exposed "vvyiwyzredqoulufqgmg.supabase.co" on the
/// Google screen, and a student who just picked an account must not
/// be sent to a second login page. A configuration problem (missing
/// Android OAuth client / SHA-1) reports itself instead.
Future<AuthResult> performGoogleSignIn({
  required SupabaseClient? client,
  GoogleNativeSignIn? native,
}) async {
  if (client == null || AppConfig.googleOAuthClientId.isEmpty) {
    // No real OAuth path: never a fake success (button hidden too).
    return AuthResult(
      ok: false,
      mode: client == null ? AuthMode.demo : AuthMode.supabase,
      googleNotConfigured: true,
    );
  }
  final attempt = await (native ?? googleNativeSignIn).signIn(client);
  switch (attempt.status) {
    case GoogleNativeStatus.success:
      return AuthResult(
        ok: true,
        userId: attempt.userId,
        mode: AuthMode.supabase,
      );
    case GoogleNativeStatus.cancelled:
      return const AuthResult(
        ok: false,
        mode: AuthMode.supabase,
        googleCancelled: true,
      );
    case GoogleNativeStatus.unavailable:
      // Plugin missing or the Android OAuth client is not set up:
      // say so and keep email login. Never open a browser (C1).
      return const AuthResult(
        ok: false,
        mode: AuthMode.supabase,
        googleNotConfigured: true,
      );
    case GoogleNativeStatus.failed:
      return AuthResult(
        ok: false,
        error: attempt.error?.toString(),
        mode: AuthMode.supabase,
        errorKind: classifySignInError(attempt.error ?? ''),
      );
  }
}
