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
/// 1. Native account picker (no browser, no supabase.co text on the
///    Google screen). Success = a real session, so ok:true.
/// 2. Only when the native path is unavailable (missing Android
///    client / SHA-1 / plugin) do we launch the browser OAuth flow,
///    which still works because Supabase holds the client secret.
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
    case GoogleNativeStatus.failed:
      return AuthResult(
        ok: false,
        error: attempt.error?.toString(),
        mode: AuthMode.supabase,
        errorKind: classifySignInError(attempt.error ?? ''),
      );
    case GoogleNativeStatus.unavailable:
      break;
  }
  try {
    final launched = await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: AppConfig.googleOAuthRedirectTo,
    );
    return AuthResult(
      ok: false,
      mode: AuthMode.supabase,
      googleLaunched: launched,
      errorKind: launched ? AuthErrorKind.none : AuthErrorKind.unknown,
    );
  } on AuthException catch (e) {
    return AuthResult(
      ok: false,
      error: e.message,
      mode: AuthMode.supabase,
      errorKind: classifySignInError(e),
    );
  } catch (e) {
    return AuthResult(
      ok: false,
      error: e.toString(),
      mode: AuthMode.supabase,
      errorKind: classifySignInError(e),
    );
  }
}
