// Phone OTP through the owner's httpSMS gateway (Edge `phone-otp`).
// Replaces Supabase Phone Auth (which needs a paid Twilio/Vonage
// provider): the phone sends the SMS, the Edge Function stores only a
// hash and enforces the limits. Nothing secret is in the app — the
// httpSMS key is a function secret.
//
// Pure verification: a successful check proves the number belongs to
// the student. It does NOT create a session by itself (registration
// creates the account at step 12 with email + password).
import 'dart:convert';
import 'dart:io';

import 'auth_service.dart';
import 'app_config.dart';

/// E.164 phone check: '+' followed by 7-15 digits, first digit
/// non-zero. The Edge function also accepts a local 01… number and
/// normalises it; this check is for values already in E.164 form.
bool isValidE164Phone(String phone) {
  return RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(phone);
}

/// Local BD number (01XXXXXXXXX) -> E.164. Empty when unusable.
String toE164Bd(String raw) {
  var d = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (d.startsWith('880')) d = d.substring(3);
  if (d.startsWith('0')) d = d.substring(1);
  if (d.length != 10) return '';
  return '+880$d';
}

class AuthPhoneService {
  bool get configured => AppConfig.phoneOtpConfigured;

  Future<AuthResult> sendPhoneOtp(
    String phone, {
    String purpose = 'register',
  }) async {
    if (!configured) {
      return const AuthResult(ok: true, mode: AuthMode.demo);
    }
    final res = await _post({
      'action': 'send',
      'phone': phone,
      'purpose': purpose,
    });
    if (res == null) {
      return const AuthResult(
        ok: false,
        error: 'network',
        mode: AuthMode.supabase,
      );
    }
    if (res['ok'] == true) {
      return const AuthResult(ok: true, mode: AuthMode.supabase);
    }
    return AuthResult(
      ok: false,
      error: '${res['error'] ?? 'sms-failed'}',
      mode: AuthMode.supabase,
    );
  }

  Future<AuthResult> verifyPhoneOtp(
    String phone,
    String code, {
    String purpose = 'register',
  }) async {
    if (!configured) {
      return const AuthResult(ok: true, mode: AuthMode.demo);
    }
    final res = await _post({
      'action': 'verify',
      'phone': phone,
      'purpose': purpose,
      'code': code,
    });
    if (res == null) {
      return const AuthResult(
        ok: false,
        error: 'network',
        mode: AuthMode.supabase,
      );
    }
    if (res['ok'] == true) {
      return const AuthResult(ok: true, mode: AuthMode.supabase);
    }
    return AuthResult(
      ok: false,
      error: '${res['error'] ?? 'wrong'}',
      mode: AuthMode.supabase,
    );
  }

  Future<Map<String, dynamic>?> _post(Map<String, dynamic> body) async {
    final url = AppConfig.phoneOtpEndpoint;
    if (url.isEmpty) return null;
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final req = await client.postUrl(Uri.parse(url));
      req.headers.set('apikey', AppConfig.supabaseAnonKey);
      req.headers.set('Authorization', 'Bearer ${AppConfig.supabaseAnonKey}');
      req.headers.set('Content-Type', 'application/json');
      req.add(utf8.encode(jsonEncode(body)));
      final res = await req.close().timeout(const Duration(seconds: 30));
      final text = await res.transform(utf8.decoder).join();
      final data = jsonDecode(text);
      return data is Map<String, dynamic> ? data : null;
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}

/// Localized line for a phone-otp error code; [s] must carry the keys
/// (both otp and registration step-9 maps do).
String phoneOtpErrorLabel(String? code, Map<String, String> s) {
  switch (code) {
    case 'cooldown':
      return s['errCooldown'] ?? s['error'] ?? '';
    case 'daily-limit':
      return s['errDaily'] ?? s['error'] ?? '';
    case 'expired':
      return s['errExpired'] ?? s['error'] ?? '';
    case 'too-many':
      return s['errTooMany'] ?? s['error'] ?? '';
    case 'wrong':
      return s['errWrong'] ?? s['error'] ?? '';
    case 'bad-phone':
      return s['phoneFormatError'] ?? s['error'] ?? '';
    case 'sms-failed':
      return s['errSms'] ?? s['error'] ?? '';
    default:
      return s['errNetwork'] ?? s['error'] ?? '';
  }
}

final authPhoneService = AuthPhoneService();
