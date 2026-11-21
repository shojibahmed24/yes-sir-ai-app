// Native Google sign-in (A14).
//
// The browser OAuth flow always shows "to continue to
// <project>.supabase.co" on the Google screen, because Supabase's
// default auth domain cannot be renamed outside the Pro plan. The
// native flow uses the phone's own Google account picker instead:
// no browser, no supabase.co line, only "Yes Sir AI" plus consent.
//
// Requirements (documented in docs/apk-issues-2026-11-22.md):
//  * an Android OAuth client for package com.yessirai.app with the
//    release SHA-1 in Google Cloud;
//  * a Web application OAuth client id passed as serverClientId
//    through GOOGLE_OAUTH_CLIENT_ID (needed for the ID token).
// When either is missing the plugin fails and we fall back to the
// browser flow, so login never dead-ends.
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_config.dart';

enum GoogleNativeStatus { success, cancelled, unavailable, failed }

class GoogleNativeOutcome {
  const GoogleNativeOutcome(this.status, {this.userId, this.error});

  final GoogleNativeStatus status;
  final String? userId;
  final Object? error;
}

/// Thin wrapper so auth_service.dart stays small and the flow is
/// testable: [signedIn] can be injected with a fake account source.
class GoogleNativeSignIn {
  GoogleNativeSignIn({Future<GoogleSignInAccount?> Function()? accountSource})
    : _accountSource = accountSource;

  final Future<GoogleSignInAccount?> Function()? _accountSource;

  GoogleSignIn? _google;

  GoogleSignIn get _instance => _google ??= GoogleSignIn(
    scopes: const ['email', 'profile'],
    // The WEB client id: google_sign_in returns an ID token only
    // when a server client id is set.
    serverClientId: AppConfig.googleOAuthClientId,
  );

  /// Picks a Google account on the device and exchanges its ID token
  /// for a Supabase session. Never returns success without a session.
  Future<GoogleNativeOutcome> signIn(SupabaseClient client) async {
    if (AppConfig.googleOAuthClientId.isEmpty) {
      return const GoogleNativeOutcome(GoogleNativeStatus.unavailable);
    }
    try {
      final GoogleSignInAccount? account;
      if (_accountSource != null) {
        account = await _accountSource();
      } else {
        // Force the account picker instead of a silent reuse.
        await _instance.signOut();
        account = await _instance.signIn();
      }
      if (account == null) {
        return const GoogleNativeOutcome(GoogleNativeStatus.cancelled);
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        // No ID token = the Android client / SHA-1 pair is missing.
        return GoogleNativeOutcome(
          GoogleNativeStatus.failed,
          error: 'no_id_token',
        );
      }
      final res = await client.auth
          // Stable in practice; the annotation is still experimental.
          // ignore: experimental_member_use
          .signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: idToken,
            accessToken: auth.accessToken,
          );
      if (res.session == null) {
        return const GoogleNativeOutcome(GoogleNativeStatus.failed);
      }
      return GoogleNativeOutcome(
        GoogleNativeStatus.success,
        userId: res.user?.id,
      );
    } catch (e) {
      final text = e.toString();
      // Plugin missing / platform unsupported: use the browser flow.
      if (text.contains('MissingPluginException') ||
          text.contains('UnimplementedError') ||
          text.contains('PlatformException(sign_in_failed') ||
          text.contains('ApiException: 10')) {
        return GoogleNativeOutcome(GoogleNativeStatus.unavailable, error: e);
      }
      return GoogleNativeOutcome(GoogleNativeStatus.failed, error: e);
    }
  }
}

/// Production instance used by authService.
final googleNativeSignIn = GoogleNativeSignIn();
