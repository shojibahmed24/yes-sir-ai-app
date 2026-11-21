// Minimal POST helper for Edge Functions (default:
// explain-question; pass [endpoint] for guide-bank).
// Shared by services that resolve grounding without duplicating
// the HttpClient boilerplate. Null = unreachable / non-200 /
// bad body. No secret is ever logged or echoed.
//
// QUICK-LOAD (2026-11-20): ONE shared HttpClient for the whole app,
// so small calls reuse the TCP/TLS connection instead of paying a
// handshake per request; timeouts tightened from 30s to 12s (open)
// and 15s (body), so a dead network ends the wait much sooner.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show compute;

import 'app_config.dart';
import 'supabase_client.dart';

/// The Authorization token for Edge calls: the signed-in student's own
/// access token when a session exists, otherwise the anon key.
///
/// Why this matters: explain-question enforces a real session (it
/// meters the daily generation quota). Sending the anon key made every
/// AI explanation return 401 "sign-in-required" — the whole AI feature
/// looked broken.
String edgeAuthToken() {
  final token = supabaseOrNull?.auth.currentSession?.accessToken;
  return (token == null || token.isEmpty) ? AppConfig.supabaseAnonKey : token;
}

/// Connection reuse: created once, kept alive with idle connections.
final HttpClient _sharedClient = HttpClient()
  ..idleTimeout = const Duration(seconds: 15)
  ..connectionTimeout = const Duration(seconds: 12)
  ..maxConnectionsPerHost = 8;

/// Exposed for tests/teardown only; production code must not close it.
HttpClient get sharedEdgeHttpClient => _sharedClient;

const _openTimeout = Duration(seconds: 30);
const _bodyTimeout = Duration(seconds: 45);

/// Bodies above this size are decoded off the UI isolate: a bulk
/// chapter/bank reply can be 1,500+ rows, and decoding it inline
/// caused a visible jank on open.
const int _offloadDecodeBytes = 60 * 1000;

Map<String, dynamic>? _decodeBody(String text) {
  final data = jsonDecode(text);
  return data is Map<String, dynamic> ? data : null;
}

Future<Map<String, dynamic>?> edgePost(
  Map<String, dynamic> body, {
  String? endpoint,
}) async {
  final url = endpoint ?? AppConfig.explainEndpoint;
  if (url.isEmpty) return null;
  try {
    final req = await _sharedClient
        .postUrl(Uri.parse(url))
        .timeout(_openTimeout);
    req.headers.set('Authorization', 'Bearer ${edgeAuthToken()}');
    req.headers.set('apikey', AppConfig.supabaseAnonKey);
    req.headers.set('Content-Type', 'application/json');
    req.add(utf8.encode(jsonEncode(body)));
    final res = await req.close().timeout(_openTimeout);
    final text = await res.transform(utf8.decoder).join().timeout(_bodyTimeout);
    if (res.statusCode != 200) return null;
    if (text.length > _offloadDecodeBytes) {
      return await compute(_decodeBody, text);
    }
    return _decodeBody(text);
  } catch (_) {
    return null;
  }
}
