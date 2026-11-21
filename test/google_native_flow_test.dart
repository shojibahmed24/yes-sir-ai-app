// A14: native Google sign-in flow — never a fake success.
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yes_sir_ai/core/services/app_config.dart';
import 'package:yes_sir_ai/core/services/google_native_sign_in.dart';
import 'package:yes_sir_ai/core/services/google_sign_in_flow.dart';

void main() {
  test('no client: Google stays unconfigured, never a fake success', () async {
    final res = await performGoogleSignIn(client: null);
    expect(res.ok, isFalse);
    expect(res.googleNotConfigured, isTrue);
    expect(res.googleCancelled, isFalse);
  });

  test('closing the account picker is a cancel, not an error', () async {
    // Skip when the build has no OAuth client id: the flow returns
    // early and would never reach the picker.
    if (AppConfig.googleOAuthClientId.isEmpty) return;
    final client = SupabaseClient('https://example.supabase.co', 'anon-key');
    final native = GoogleNativeSignIn(
      accountSource: () async => null as GoogleSignInAccount?,
    );
    final res = await performGoogleSignIn(client: client, native: native);
    expect(res.ok, isFalse);
    expect(res.googleCancelled, isTrue);
    expect(res.googleNotConfigured, isFalse);
    expect(res.googleLaunched, isFalse);
  });
}
