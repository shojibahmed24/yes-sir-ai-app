// Model-test set card for the Bangla 1st Paper model-tests
// screen, split out so that screen stays under the 250-line
// rule. The subtitle labels the unkeyed count (never a bare
// number) and the action button is at least 48dp tall.
import 'package:flutter/material.dart';

import '../../core/models/guide_bank_model.dart';
import 'widgets/digits.dart';

class BanglaFirstSetDisplay {
  const BanglaFirstSetDisplay(
      {required this.info, required this.title, required this.isCreative});
  final GuideModelSetInfo info;
  final String title;
  final bool isCreative;
}

class BanglaFirstSetCard extends StatelessWidget {
  const BanglaFirstSetCard(
      {super.key,
      required this.display,
      required this.s,
      required this.bn,
      required this.starting,
      required this.onTap});
  final BanglaFirstSetDisplay display;
  final Map<String, String> s;
  final bool bn;
  final bool starting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final info = display.info;
    final unkeyed = info.unkeyedCount;
    return Card(
      child: ListTile(
        title: Text(display.title),
        subtitle: Text(
          '${numStr(info.totalCount, bn)}${s['questionsSuffix']!} · '
          '${numStr(info.keyedCount, bn)}${s['keyedSuffix']!}'
          '${unkeyed > 0 ? ' · ${numStr(unkeyed, bn)}${s['unkeyedSuffix']!}' : ''}',
        ),
        trailing: starting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2))
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 48)),
                onPressed: info.keyedCount == 0 && !display.isCreative
                    ? null
                    : onTap,
                child: Text(display.isCreative
                    ? s['viewGroups']!
                    : s['startExam']!),
              ),
      ),
    );
  }
}
