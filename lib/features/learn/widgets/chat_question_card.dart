// Question card above the chat messages for guide chats
// (2026-11-03 chat fix): the tutor UI must clearly show WHICH
// question the chat was opened for — question text + verbatim
// options from the selection. It renders only what the
// selection actually carries; nothing is invented. When the
// selection carries neither, only the label shows — itself an
// honest signal that context is absent.
// R6 (2026-11-08): a long question + 4-5 options used to eat
// the whole header and squeeze the message list to zero. The
// card now shows 3 lines of the question + the first 2 options
// with an "আরও দেখুন" toggle for the rest.
import 'package:flutter/material.dart';

import '../lesson_selection.dart';

const _bnLabels = ['ক', 'খ', 'গ', 'ঘ', 'ঙ'];

class ChatQuestionCard extends StatefulWidget {
  const ChatQuestionCard({super.key, required this.sel, required this.s});
  final LessonSelection sel;
  final Map<String, String> s;

  @override
  State<ChatQuestionCard> createState() => _ChatQuestionCardState();
}

class _ChatQuestionCardState extends State<ChatQuestionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final sel = widget.sel;
    final s = widget.s;
    final style = Theme.of(context).textTheme.bodySmall;
    // Collapse only when there is something to collapse: a
    // long question, or more than 2 options.
    final collapsible =
        sel.queryText.length > 120 || sel.guideOptions.length > 2;
    final shownOptions = _expanded
        ? sel.guideOptions
        : sel.guideOptions.take(2).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s['chatForQuestion']!,
          style: style?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (sel.queryText.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(sel.queryText,
              style: style,
              maxLines: _expanded ? null : 3,
              overflow:
                  _expanded ? null : TextOverflow.ellipsis),
        ],
        for (var i = 0; i < shownOptions.length; i++)
          Text(
            '${i < _bnLabels.length ? _bnLabels[i] : '${i + 1}'}. '
            '${shownOptions[i]}',
            style: style,
            maxLines: _expanded ? null : 2,
            overflow: _expanded ? null : TextOverflow.ellipsis,
          ),
        if (collapsible)
          TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(_expanded ? s['showLess']! : s['showMore']!),
          ),
      ],
    );
  }
}
