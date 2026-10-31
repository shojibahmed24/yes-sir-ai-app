// Auth result types, split out of auth_service.dart to keep
// it under the 250-line limit. auth_service.dart re-exports
// this file, so existing importers (e.g. auth_phone_service)
// keep working unchanged.
enum AuthMode { supabase, demo }

class AuthResult {
  final bool ok;
  final String? userId;
  final String? error;
  final AuthMode mode;

  /// True when sign-up succeeded but no session was established
  /// because email confirmation is pending (Supabase "Confirm email"
  /// on: res.user != null, res.session == null). Callers must NOT
  /// treat this as a signed-in user: no saved session, no /home.
  final bool confirmationPending;

  /// True when sign-in failed because the email address is not
  /// confirmed yet. Callers offer a resend instead of a dead end.
  final bool emailNotConfirmed;

  const AuthResult({
    required this.ok,
    this.userId,
    this.error,
    required this.mode,
    this.confirmationPending = false,
    this.emailNotConfirmed = false,
  });
}
