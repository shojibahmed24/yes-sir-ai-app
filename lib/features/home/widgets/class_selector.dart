// Class selector for the learning hub (Phase 2/0): a labelled row
// of 1–10 chips. Extracted from SubjectsScreen so that screen stays
// under the 250-line cap and the selector can be reused later.
import 'package:flutter/material.dart';

import '../../learn/widgets/digits.dart';
import '../../../theme/app_tokens.dart';
import '../../../theme/widgets/app_chip.dart';

class ClassSelector extends StatelessWidget {
  const ClassSelector({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.bn,
    required this.s,
  });

  final int? selected;
  final ValueChanged<int> onSelected;
  final bool bn;
  final Map<String, String> s;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s['classLabel']!, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: Sp.sm),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 10,
            separatorBuilder: (_, __) => const SizedBox(width: Sp.sm),
            itemBuilder: (context, i) {
              final cls = i + 1;
              return AppChip(
                label: numStr(cls, bn),
                selected: cls == selected,
                onTap: () => onSelected(cls),
              );
            },
          ),
        ),
      ],
    );
  }
}
