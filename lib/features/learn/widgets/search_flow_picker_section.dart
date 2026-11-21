// The picker half of the search screen: the one global picker, the
// guide-only extras (Board tile, Bangla 1st entry), the question
// number field, the type field and the jump message. Split out of
// search_flow_screen.dart (250-line cap); it renders controller state
// and forwards picks — no I/O and no navigation of its own.
import 'package:flutter/material.dart';

import '../bangla_first_entry_card.dart';
import '../global_picker_english.dart';
import '../global_picker_tree.dart';
import '../search_flow_bangla_papers.dart';
import '../search_flow_browse_extras.dart';
import '../search_flow_controller.dart';
import '../search_flow_picker_host.dart';
import 'global_picker.dart';
import 'search_flow_board_tile.dart';
import 'search_flow_field.dart';
import 'search_flow_field_states.dart';
import 'search_flow_type_field.dart';

class SearchFlowPickerSection extends StatelessWidget {
  const SearchFlowPickerSection({
    super.key,
    required this.c,
    required this.extras,
    required this.english,
    required this.s,
    required this.bn,
    required this.jumpMessage,
    required this.onChanged,
    required this.onJump,
    this.onNumberCleared,
  });
  final SearchFlowController c;
  final SearchFlowBrowseExtras extras;
  final GlobalPickerEnglishHost english;
  final Map<String, String> s;
  final bool bn;
  final String? jumpMessage;

  /// Rebuild the screen (controller/extras mutate in place).
  final VoidCallback onChanged;

  /// Jump button / submit on the number field.
  final VoidCallback onJump;

  /// Typing clears a stale jump message.
  final VoidCallback? onNumberCleared;

  @override
  Widget build(BuildContext context) {
    final englishGuideMode = c.source == 'guide' && c.subjectId == 'english';
    final paper2Mode = c.source == 'guide' && c.subjectId == 'english-2nd';
    final banglaFirst = isBanglaFirstMode(c.subjectId, c.source);
    final banglaSecond = isBanglaSecondMode(c.subjectId, c.source);
    final setMode = extras.setId != null;
    const gap = SizedBox(height: 12);
    // 3-step indicator (S6.1): identity is always chosen before this
    // widget renders, so only chapter and type can be pending.
    final step = c.type != null
        ? 3
        : c.chapter != null
        ? 2
        : 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 1; i <= 3; i++) ...[
              if (i > 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: step >= i
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: step >= i
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  border: Border.all(
                    color: step >= i
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Text(
                  '$i',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: step >= i
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        // THE picker: one widget for every subject.
        if (englishGuideMode && english.controller == null)
          SearchFlowLoadingBars(
            label: s['pickerLoading']!,
            semanticsLabel: s['pickerLoading']!,
          )
        else
          GlobalPicker(
            treeKey: '${c.subjectId}|${c.source}|${c.schoolClass}',
            tree: englishGuideMode
                ? buildEnglishPickerTree(
                    c: english.controller!,
                    schoolClass: c.schoolClass,
                    s: s,
                    bn: bn,
                  )
                : buildGlobalPickerTree(c: c, extras: extras, s: s, bn: bn),
            s: s,
            selectedId: globalPickerSelectedId(c, extras),
            onPick: (pick) => applyGlobalPickerPick(
              context: context,
              c: c,
              extras: extras,
              pick: pick,
              onChanged: onChanged,
            ),
            onBranch: (node) => onGlobalPickerBranch(
              node: node,
              c: c,
              extras: extras,
              english: english,
            ),
          ),
        // Board questions are SUBJECT-wide, not chapter-scoped: one        // entry at the root only. Showing it inside every chapter made
        // the same 984-question set look chapter-specific.
        if (c.source == 'guide' &&
            c.chapter == null &&
            extras.setId == null &&
            !paper2Mode &&
            !banglaFirst)
          SearchFlowBoardTile(
            subjectId: c.effectiveSubjectId,
            schoolClass: c.effectiveClass,
            s: s,
            bn: bn,
          ),
        // Bangla 1st Paper entry card: the only in-app way into
        // /bangla-first.
        if (banglaFirst) const BanglaFirstEntryCard(),
        if (!englishGuideMode) ...[
          gap,
          SearchFlowTextField(
            label: s['questionNumberLabel']!,
            icon: Icons.numbers,
            controller: c.numberCtrl,
            hint: s['questionNumberHint']!,
            keyboardType: TextInputType.number,
            onChanged: (_) {
              if (jumpMessage != null) onNumberCleared?.call();
            },
            onSubmitted: onJump,
          ),
        ],
        if (!englishGuideMode &&
            !banglaFirst &&
            !banglaSecond &&
            !setMode &&
            !paper2Mode) ...[
          gap,
          SearchFlowTypeField(
            value: c.type,
            s: s,
            bn: bn,
            chapter: c.chapter,
            guide: c.source == 'guide',
            lesson: c.lesson,
            subject: c.effectiveSubjectId,
            schoolClass: c.effectiveClass,
            onChanged: (v) {
              c.type = v;
              onChanged();
            },
          ),
        ],
        if (jumpMessage != null) ...[
          gap,
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(jumpMessage!),
            ),
          ),
        ],
      ],
    );
  }
}
