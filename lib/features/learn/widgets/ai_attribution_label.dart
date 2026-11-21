// Small attribution line under an AI explanation.
//
// It shows ONLY what the Edge response itself reported
// (see GenResult): 'AI: Gemini • gemini-3.8-flash',
// 'AI: OpenRouter • nvidia/...', or — when the Edge deploy
// predates attribution and reported neither field — the
// caller-supplied localized unknown text, never a guess from
// the provider the user merely selected in Settings.
//
// B5: students never see provider/model names. The technical line
// is DEBUG-only (support/debugging); a release build renders
// nothing here, because the card already labels the text as an AI
// explanation.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AiAttributionLabel extends StatelessWidget {
  const AiAttributionLabel({
    super.key,
    required this.provider,
    required this.model,
    required this.unknownText,
  });

  /// 'openrouter' | 'gemini' | 'unknown'.
  final String provider;
  final String? model;

  /// Localized honest text for the unknown case, e.g.
  /// 'AI: জানা যায়নি — সার্ভার আপডেট হয়নি, OpenRouter
  /// চলতে পারে' (from the page's strings).
  final String unknownText;

  @override
  Widget build(BuildContext context) {
    // Release builds show no provider/model names at all (B5).
    if (kReleaseMode) return const SizedBox.shrink();
    final style = Theme.of(context).textTheme.bodySmall;
    if (provider != 'openrouter' && provider != 'gemini') {
      return Text(unknownText, style: style);
    }
    final name = provider == 'gemini' ? 'Gemini' : 'OpenRouter';
    final label = model != null && model!.isNotEmpty
        ? 'AI: $name • $model'
        : 'AI: $name';
    return Text(label, style: style);
  }
}
