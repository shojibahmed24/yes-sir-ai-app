// Route: /login. Email sign-in is real via Supabase; phone OTP
// lives on /otp. Google button shows only with an OAuth client id.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/auth_signin_listener.dart';
import '../../core/services/profile_restore_service.dart';
import '../../core/widgets/demo_banner.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/login_strings.dart';
import 'widgets/auth_buttons.dart';
import 'widgets/auth_fields.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/fade_slide.dart';

// Phase 6: real logo, matching splash (no drawn RobotAvatar).

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _contact = TextEditingController();
  final _password = TextEditingController();
  bool _remember = true;
  bool _busy = false;

  /// Inline, dismissible error: a snackbar vanished before the user
  /// could read it; a professional form keeps the message next to the
  /// fields until the next attempt.
  String? _error;
  void Function()? _cancelAuthListener;

  @override
  void initState() {
    super.initState();
    // Cold-start session (OAuth redirect landed before mount):
    // same post-sign-in work as the live listener below.
    if (authService.currentUserId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await profileRestoreService.ensureGoogleProfile();
        await profileRestoreService.restoreAfterSignIn();
        if (mounted) context.go('/home');
      });
    }
    _cancelAuthListener = listenForFreshSignIn((user) async {
      await authService.saveSession(user.id);
      await profileRestoreService.ensureGoogleProfile();
      await profileRestoreService.restoreAfterSignIn();
      if (mounted) context.go('/home');
    });
  }

  Future<void> _signIn() async {
    if (_busy) return;
    final s = isBangla ? loginStringsBn : loginStringsEn;
    final contact = _contact.text.trim();
    // Empty contact/password used to sail through DEMO to /home.
    if (contact.isEmpty || _password.text.isEmpty) {
      setState(() => _error = s['emptyError']);
      return;
    }
    if (!authService.isDemo && !contact.contains('@')) {
      setState(() => _error = s['phoneLoginError']);
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    final res = await authService.signInEmail(contact, _password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (res.ok) {
      // Session for splash routing ("Remember me" off skips DEMO only).
      if (_remember && res.userId != null) {
        await authService.saveSession(res.userId!);
      }
      // Real-mode sign-in: restore the server profile before /home.
      if (res.mode == AuthMode.supabase) {
        await profileRestoreService.restoreAfterSignIn();
      }
      if (mounted) context.go('/home');
    } else if (res.emailNotConfirmed) {
      // Unconfirmed address: offer a resend (contact holds the email).
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s['emailNotConfirmed']!),
            action: SnackBarAction(
              label: s['resend']!,
              onPressed: () => _resendConfirmation(contact),
            ),
          ),
        );
      }
    } else {
      // Mapped Bangla/English message only — never raw SDK text.
      setState(() => _error = s[signInErrorStringKey(res)]);
    }
  }

  Future<void> _resendConfirmation(String email) async {
    if (_busy) return;
    final s = isBangla ? loginStringsBn : loginStringsEn;
    setState(() => _busy = true);
    final res = await authService.resendConfirmationEmail(email);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.ok ? s['confirmationResent']! : s['loginFailed']!),
      ),
    );
  }

  Future<void> _signInGoogle() async {
    final s = isBangla ? loginStringsBn : loginStringsEn;
    final res = await authService.signInWithGoogle();
    if (!mounted) return;
    if (res.googleLaunched) {
      // Browser launched, NOT signed in: stay here for signedIn.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s['googleWaiting']!),
          duration: const Duration(minutes: 5),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s[signInErrorStringKey(res)]!)));
    }
  }

  @override
  void dispose() {
    _cancelAuthListener?.call();
    _contact.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final s = isBangla ? loginStringsBn : loginStringsEn;
        return AuthScaffold(
          showBack: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              children: [
                const DemoBanner(),
                const SizedBox(height: 8),
                const FadeSlide(child: _Logo()),
                const SizedBox(height: 16),
                FadeSlide(
                  delayMs: 80,
                  child: Text(
                    s['title']!,
                    style: Theme.of(context).textTheme.displayLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                FadeSlide(
                  delayMs: 160,
                  child: Text(
                    s['subtitle']!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                FadeSlide(
                  delayMs: 240,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                      child: Column(
                        children: [
                          AuthTextField(
                            label: s['phoneEmail']!,
                            hint: s['phoneEmailHint']!,
                            icon: Icons.alternate_email,
                            controller: _contact,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          PasswordField(
                            label: s['password']!,
                            hint: s['passwordHint']!,
                            controller: _password,
                          ),
                          CheckboxListTile(
                            value: _remember,
                            onChanged: (v) =>
                                setState(() => _remember = v ?? true),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(s['rememberMe']!),
                          ),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _ErrorBanner(message: _error!),
                            ),
                          AuthPrimaryButton(
                            label: s['login']!,
                            busy: _busy,
                            busyLabel: s['loggingIn'] ?? s['login']!,
                            onPressed: _signIn,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (authService.googleSignInAvailable) ...[
                  const SizedBox(height: 16),
                  _OrDivider(label: s['or']!),
                  const SizedBox(height: 12),
                  AuthGoogleButton(
                    label: s['google']!,
                    onPressed: _signInGoogle,
                  ),
                ],
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/forgot-password'),
                  child: Text(s['forgot']!),
                ),
                const SizedBox(height: 8),
                // Phone OTP is verification-only (registration step 9):
                // it does not create a session, so it is not a login
                // method. The old link opened a flow that could not
                // sign anyone in.
                AuthTextLink(
                  label: s['newAccount']!,
                  onPressed: () => context.go('/register/welcome'),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        s['safe']!,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                AuthTextLink(
                  label: s['help']!,
                  onPressed: () => context.go('/help'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Brand mark in a soft tinted ring (a bare image looked pasted on).
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: primary.withValues(alpha: 0.08),
        border: Border.all(color: primary.withValues(alpha: 0.15)),
      ),
      child: Image(
        image: const AssetImage('assets/logo/yes-sir-ai-icon.png'),
        width: 84,
        height: 84,
      ),
    );
  }
}

/// "or" with rules on both sides (plain text read as a label).
class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outlineVariant;
    return Row(
      children: [
        Expanded(child: Divider(color: color)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(child: Divider(color: color)),
      ],
    );
  }
}

/// Inline form error: stays on screen until the next attempt.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: error.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 18, color: error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: error)),
          ),
        ],
      ),
    );
  }
}
