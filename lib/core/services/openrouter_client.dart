// Server-side generation proxy (2026-10-30: keys moved server-side).
// The app NEVER calls OpenRouter directly and NEVER holds the key:
// both call sites POST their already-built prompts to the
// explain-question Edge Function (Mode GEN), which calls OpenRouter
// with its function secret. Prompt construction stays here (the
// locked grounding rules live in Dart); only the key and the HTTP
// call moved server-side. GenResult.keyMissing tells callers the
// Edge secret is not set, so the UI shows an honest error instead
// of a fabricated answer. Null text = call failed / empty reply.
import 'dart:convert';
import 'dart:io';

import '../models/backend_models.dart';
import 'app_config.dart';

class GenResult {
  final String? text;
  final bool keyMissing;
  const GenResult({this.text, this.keyMissing = false});
}

class OpenRouterClient {
  /// Raw chat call with a caller-built system + user prompt.
  /// Used by the structured solution path, which owns its prompt
  /// contract and parses the reply itself. The caller guarantees
  /// grounded context.
  Future<GenResult> chatRaw({
    required String systemPrompt,
    required String userPrompt,
  }) =>
      _generate(systemPrompt: systemPrompt, userPrompt: userPrompt);

  /// Full-context call. userQuestion is the student's typed
  /// follow-up (chat) or null. Prompt built exactly as before;
  /// only the transport changed (Edge proxy, no client key).
  Future<GenResult> explain({
    required GroundedContext ctx,
    required String style,
    required bool bangla,
    String? userQuestion,
  }) async {
    final followUp = (userQuestion ?? '').trim();
    final userContent = StringBuffer()
      ..writeln('Book: ${ctx.bookTitle}')
      ..writeln('Chapter ${ctx.chapterNumber}: ${ctx.chapterTitle}')
      ..writeln('Page ${ctx.page}, Question ${ctx.problem}')
      ..writeln('Book question (verbatim): ${ctx.questionText}');
    // Phase 3 chunk grounding: at most 3 chunks, each cited
    // with its own book page range. Chunks are OCR chapter
    // text for context only — never quoted to the student
    // as verbatim book proof beyond the question itself.
    final chunks = ctx.chunkTexts.take(3).toList();
    if (chunks.isNotEmpty) {
      userContent.writeln(
          'Book chapter text for this question (same book and chapter):');
      for (var i = 0; i < chunks.length; i++) {
        final range = i < ctx.chunkPageRanges.length
            ? ctx.chunkPageRanges[i]
            : '';
        userContent.writeln(
            'Chunk ${i + 1}${range.isNotEmpty ? ' (pages $range)' : ''}: ${chunks[i]}');
      }
      userContent.writeln(
          'Base the explanation on the question and this chapter text.');
    } else {
      // Honest fallback: no chapter text exists for this
      // question, so the prompt must NOT claim it. The
      // explanation is grounded in the verbatim question
      // only (or chapter-only where a real chapter exists).
      userContent.writeln(
          'No chapter text is available for this question. '
          'Explain ONLY from the verbatim book question above, '
          'and do NOT claim chapter-text grounding.');
    }
    if (followUp.isNotEmpty) {
      userContent.writeln('Student follow-up question: $followUp');
    }
    userContent.writeln('Explain in style: $style.');
    return _generate(
      systemPrompt: 'You are a school teacher. Explain ONLY the '
          'given textbook question, in the requested style, in '
          '${bangla ? 'Bangla' : 'English'}. Write every math '
          'formula in LaTeX wrapped in \$...\$ delimiters so it '
          'renders as typeset math, never caret-text. Use only the book '
          'context given. Do not invent a different question. '
          'Never claim chapter-text grounding when no chapter '
          'text was given. If the context is not enough to '
          'answer, say so plainly instead of guessing. '
          'QUESTION SCOPE (verbatim-first chat rule, 2026-10-31): '
          'answer ONLY this question and what is needed to '
          'understand it (its terms, formulas, and prerequisite '
          'ideas). If the student asks about anything else — '
          'another subject, another question, general knowledge, '
          'personal chat, or writing work for them — politely '
          'refuse in the same language and redirect them to '
          'this question. Never answer off-topic questions, '
          'even partially.',
      userPrompt: userContent.toString(),
    );
  }

  /// POST prompts to Edge Mode GEN. Non-200 / bad body / empty
  /// text = generic failure; the Edge's 'openrouter-key-missing'
  /// error maps to keyMissing so callers report it honestly.
  /// Per-call cap (2026-11-01 diagnosis): one GEN call is capped
  /// at 55s total, so a slow free-model call fails fast enough
  /// for the caller's trimmed retry to still run inside the
  /// screen's 120s explanation window. The client is closed on
  /// ALL paths (including timeout) via finally — previously a
  /// timeout/hang leaked the HttpClient, since close() only ran
  /// after a successful response body.
  Future<GenResult> _generate({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    final url = AppConfig.explainEndpoint;
    if (url.isEmpty) return const GenResult();
    final client = HttpClient();
    try {
      return await _generateInner(
        client: client,
        url: url,
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
      ).timeout(const Duration(seconds: 55));
    } catch (_) {
      return const GenResult();
    } finally {
      client.close();
    }
  }

  Future<GenResult> _generateInner({
    required HttpClient client,
    required String url,
    required String systemPrompt,
    required String userPrompt,
  }) async {
    final req = await client.postUrl(Uri.parse(url));
    req.headers.set('Authorization', 'Bearer ${AppConfig.supabaseAnonKey}');
    req.headers.set('apikey', AppConfig.supabaseAnonKey);
    req.headers.set('Content-Type', 'application/json');
    req.add(utf8.encode(jsonEncode({
      'generate': true,
      'systemPrompt': systemPrompt,
      'userPrompt': userPrompt,
    })));
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    final data = jsonDecode(body);
    if (data is Map<String, dynamic>) {
      if (data['error'] == 'openrouter-key-missing') {
        return const GenResult(keyMissing: true);
      }
      if (res.statusCode == 200 && data['generated'] == true) {
        final text = data['text'];
        if (text is String && text.isNotEmpty) {
          return GenResult(text: text);
        }
      }
    }
    return const GenResult();
  }
}

final openRouterClient = OpenRouterClient();
