// Route: /register/otp (Step 9/13)
// Real phone verification: the `phone-otp` Edge Function sends a
// 6-digit code through the owner's httpSMS gateway (the app never
// holds the key). Only the code's hash is stored server-side, with a
// 5-minute expiry, a 60s resend cooldown and 5 wrong guesses max.
// DEMO mode (no backend configured) keeps the labelled local check so
// the flow still works offline, never silently pretending an SMS went
// out.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_phone_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../l10n/language_provider.dart';
import '../../../l10n/pages/reg_step09_strings.dart';
import '../../../theme/app_theme.dart';
import '../registration_data.dart';
import '../widgets/reg_scaffold.dart';
import '../widgets/reg_widgets.dart';

class Step09Otp extends StatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  const Step09Otp({super.key, this.onNext, this.onBack});

  @override
  State<Step09Otp> createState() => _Step09OtpState();
}

class _Step09OtpState extends State<Step09Otp> with RegLangMixin {
  final _boxes = List.generate(6, (_) => TextEditingController());
  String? _error;
  bool _busy = false;
  bool _sent = false;
  int _cooldown = 0;
  Timer? _cooldownTimer;

  Map<String, String> get _s => isBangla ? regStep09Bn : regStep09En;

  @override
  void initState() {
    super.initState();
    // Send the first code after the first frame (no setState during
    // initState, and the phone is already saved by step 7).
    WidgetsBinding.instance.addPostFrameCallback((_) => _send());
  }

  @override
  void dispose() {
    for (final c in _boxes) {
      c.dispose();
    }
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldown = 30);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_cooldown <= 1) {
        t.cancel();
        setState(() => _cooldown = 0);
      } else {
        setState(() => _cooldown--);
      }
    });
  }

  Future<void> _send() async {
    if (_busy || _cooldown > 0) return;
    final s = _s;
    final phone = toE164Bd(registrationDataNotifier.value.phone);
    if (phone.isEmpty) {
      setState(() => _error = s['phoneMissing']);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final res = await authPhoneService.sendPhoneOtp(phone, purpose: 'register');
    if (!mounted) return;
    setState(() => _busy = false);
    if (res.ok) {
      setState(() => _sent = true);
      _startCooldown();
      if (authService.isDemo) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(s['demoResend']!)));
      }
      return;
    }
    setState(() => _error = phoneOtpErrorLabel(res.error, s));
  }

  Future<void> _next() async {
    final s = _s;
    final code = _boxes.map((c) => c.text).join();
    if (code.length != 6) {
      setState(() => _error = s['error']);
      return;
    }
    final phone = toE164Bd(registrationDataNotifier.value.phone);
    if (phone.isEmpty) {
      setState(() => _error = s['phoneMissing']);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final res = await authPhoneService.verifyPhoneOtp(
      phone,
      code,
      purpose: 'register',
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!res.ok) {
      setState(() => _error = phoneOtpErrorLabel(res.error, s));
      for (final c in _boxes) {
        c.clear();
      }
      return;
    }
    updateRegistration(registrationDataNotifier.value.copyWith(otp: code));
    if (widget.onNext != null) {
      widget.onNext!();
    } else {
      context.go('/register/goal');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    return RegScaffold(
      step: 9,
      title: s['title']!,
      subtitle: s['subtitle']!,
      nextLabel: s['next']!,
      onNext: _busy ? null : _next,
      onBack: widget.onBack,
      child: Column(
        children: [
          Text(
            !_sent && authService.isDemo
                ? s['demoNote']!
                : (_sent ? s['codeSent']! : s['sending']!),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          OtpField(controllers: _boxes),
          const SizedBox(height: 16),
          Center(
            child: _busy
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton(
                    onPressed: _cooldown > 0 ? null : _send,
                    child: Text(
                      _cooldown > 0
                          ? s['resendWait']!.replaceFirst('{n}', '$_cooldown')
                          : s['resend']!,
                    ),
                  ),
          ),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: AppTheme.error)),
        ],
      ),
    );
  }
}
