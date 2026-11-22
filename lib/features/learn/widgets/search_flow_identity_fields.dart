// Identity fields for the search screen: class + subject pickers.
//
// Guide-only app (round 4): the "source" (textbook/guide) dropdown is
// gone everywhere. Every question comes from the supplied guide, so a
// source choice would only be a second way to reach the same rows.
// Split out so the screen stays under the 250-line cap; the widget
// only renders and the screen owns refreshes.
import 'package:flutter/material.dart';

import '../class_choices.dart';
import '../search_flow_controller.dart';
import 'search_flow_field.dart';

class SearchFlowIdentityFields extends StatelessWidget {
  const SearchFlowIdentityFields({
    super.key,
    required this.controller,
    required this.s,
    required this.bn,
    required this.onClass,
    required this.onSubject,
  });
  final SearchFlowController controller;
  final Map<String, String> s;
  final bool bn;
  final void Function(int value) onClass;
  final void Function(String value) onSubject;

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 12);
    final classItems = classChoices(controller.schoolClass);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SearchFlowDropdownField<int>(
          label: s['classLabel']!,
          icon: Icons.school,
          value: controller.schoolClass,
          items: classItems
              .map((c) => SearchFlowDropdownItem(value: c, label: '$c'))
              .toList(),
          onChanged: (v) {
            if (v != null) onClass(v);
          },
        ),
        gap,
        SearchFlowDropdownField<String>(
          label: s['subjectLabel']!,
          icon: Icons.book,
          value: controller.subjects.any((x) => x.id == controller.subjectId)
              ? controller.subjectId
              : null,
          items: controller.subjects
              .map(
                (x) => SearchFlowDropdownItem(value: x.id, label: x.name(bn)),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onSubject(v);
          },
        ),
      ],
    );
  }
}
