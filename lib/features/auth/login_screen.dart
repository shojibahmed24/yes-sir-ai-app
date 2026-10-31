// Route: /login
// Design: stitch-reference/login_screen/code.html
// Start screen after splash/onboarding. Email sign-in is real via
// Supabase (AuthService.signInEmail); phone OTP lives on /otp.
// Google sign-in is deferred — its button and service method are
// untouched this round (see BACKEND_DETAILS_LIST.md).
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/auth_signin_listener.dart';
import '../../core/widgets/demo_banner.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/login_strings.dart';
import 'widgets/auth_buttons.dart';
import 'widgets/auth_fields.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/fade_slide.dart';
// Phase 6 (H1, M2): real logo, matching splash — no more drawn
// RobotAvatar on login, so both screens share one brand mark.

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
  void Function()? _cancelAuthListener;

  @override
  void initState() {
    super.initState();
    // Confirmation link tapped while on /login: the SDK signs the
    // user in, so go home instead of leaving a live session here.
    // Also covers a session that landed just before this screen
    // mounted (cold-start race).
    if (authService.currentUserId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/home');
      });
    }
    _cancelAuthListener = listenForFreshSignIn((user) {
      authService.saveSession(user.id);
      context.go('/home');
    });
  }

  Future<void> _signIn() async {
    if (_busy) return;
    final s = isBangla ? loginStringsBn : loginStringsEn;
    final contact = _contact.text.trim();
    // Previously empty contact/password sailed through DEMO mode
    // straight to /home. Also, a phone number was passed to Supabase
    // email auth in real mode and failed confusingly.
    if (contact.isEmpty || _password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s['emptyError']!)),
      );
      return;
    }
    if (!authService.isDemo && !contact.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s['phoneLoginError']!)),
      );
      return;
    }
    setState(() => _busy = true);
    final res = await authService.signInEmail(contact, _password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (res.ok) {
      // Persisted session: splash routes a signed-in user to /home.
      // "Remember me" off means DEMO sessions are not persisted;
      // a real Supabase session persists via Supabase itself.
      if (_remember && res.userId != null) {
        await authService.saveSession(res.userId!);
      }
      if (mounted) context.go('/home');
    } else if (res.emailNotConfirmed) {
      // Unconfirmed address: offer a resend instead of a dead end.
      // The contact field holds the email here (phone logins are
      // rejected above in real mode), so resending to it is safe.
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.error ?? s['loginFailed']!)),
      );
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
        content: Text(res.ok
            ? s['confirmationResent']!
            : (res.error ?? s['loginFailed']!)),
      ),
    );
  }

  Future<void> _signInGoogle() async {
    // Previously a failed Google sign-in did nothing silently.
    final s = isBangla ? loginStringsBn : loginStringsEn;
    final res = await authService.signInWithGoogle();
    if (!mounted) return;
    if (res.ok) {
      // DEMO Google is labelled by the DEMO banner on this screen;
      // it never claims a real Google account was linked.
      if (res.userId != null) await authService.saveSession(res.userId!);
      if (mounted) context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.error ?? s['loginFailed']!)),
      );
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
                const FadeSlide(
                  child: Image(
                    image: AssetImage('assets/logo/yes-sir-ai-icon.png'),
                    width: 96,
                    height: 96,
                  ),
                ),
                const SizedBox(height: 16),
                FadeSlide(
                  delayMs: 80,
                  child: Text(s['title']!,
                      style: Theme.of(context).textTheme.displayLarge,
                      textAlign: TextAlign.center),
                ),
                const SizedBox(height: 8),
                FadeSlide(
                  delayMs: 160,
                  child: Text(s['subtitle']!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center),
                ),
                const SizedBox(height: 20),
                FadeSlide(
                  delayMs: 240,
                  child: AuthTextField(
                    label: s['phoneEmail']!,
                    hint: s['phoneEmailHint']!,
                    icon: Icons.phone,
                    controller: _contact,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(height: 16),
                FadeSlide(
                  delayMs: 300,
                  child: PasswordField(
                    label: s['password']!,
                    hint: s['passwordHint']!,
                    controller: _password,
                  ),
                ),
                Row(
                  children: [
                    Checkbox(
                      value: _remember,
                      onChanged: (v) => setState(() => _remember = v ?? true),
                    ),
                    Expanded(child: Text(s['rememberMe']!)),
                    AuthTextLink(
                      label: s['forgot']!,
                      onPressed: () => context.go('/forgot-password'),
                    ),
                  ],
                ),
                AuthPrimaryButton(
                  label: s['login']!,
                  onPressed: _signIn,
                ),
                const SizedBox(height: 12),
                Text(s['or']!, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),
                AuthGoogleButton(
                  label: s['google']!,
                  onPressed: _signInGoogle,
                ),
                const SizedBox(height: 8),
                AuthTextLink(
                  label: s['otp']!,
                  onPressed: () => context.go('/otp?from=/login'),
                ),
                AuthTextLink(
                  label: s['newAccount']!,
                  onPressed: () => context.go('/register/welcome'),
                ),
                const SizedBox(height: 8),
                Text(s['safe']!,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center),
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
