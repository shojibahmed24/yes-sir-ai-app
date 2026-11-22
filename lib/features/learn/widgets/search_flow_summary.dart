// Picker header summary: one glanceable line of what is currently
// picked (class · subject · chapter · type). It is a read-only
// reflection of controller state — no network, no picks of its own —
// so a student coming back to the screen never has to re-read the
// whole form to know where they are.
import 'package:flutter/material.dart';

import '../../../theme/app_tokens.dart';
import '../../home/home_design.dart';
import '../search_flow_controller.dart';
import '../search_flow_types.dart';
import 'digits.dart';
import 'mock_data.dart';

class SearchFlowSummary extends StatelessWidget {
  const SearchFlowSummary({
    super.key,
    required this.c,
    required this.bn,
    required this.s,
  });
  final SearchFlowController c;
  final bool bn;
  final Map<String, String> s;

  @override
  Widget build(BuildContext context) {
    // C7: never print a raw subject id. Localized name first, then
    // the paper-aware name, then an honest generic label.
    final rawName = subjectNameFor(c.subjectId, bn);
    final named = paperSubjectName(c.subjectId, rawName, bn, c.effectiveClass);
    final subjectName = named == c.subjectId
        ? (s['subjectLabel'] ?? (bn ? 'বিষয়' : 'Subject'))
        : named;
    final parts = <String>[
      '${s['classLabel']!} ${numStr(c.effectiveClass, bn)}',
      subjectName,
      if (c.chapter != null) '${s['chapterLabel']!} ${numStr(c.chapter!, bn)}',
      if (c.type != null) searchFlowTypeLabel(c.type!, s),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.md),
      child: Text(
        parts.join(' · '),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
