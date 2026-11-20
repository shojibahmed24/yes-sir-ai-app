// English 2nd paper section nodes for the global picker, split out
// of global_picker_tree.dart to stay under the file-line cap.
//
// The 15 section values are the exam order (a static list), but the
// live paper does not carry all of them. Zero is a server fact
// (hidden); an unknown count stays visible, never a guess; all-zero
// data keeps the full list so the picker is never blank.
import '../../core/data/paper2_sections.dart';
import 'global_picker_model.dart';
import 'search_flow_browse_extras.dart';
import 'widgets/digits.dart';

List<GlobalPickerNode> paper2SectionNodes({
  required SearchFlowBrowseExtras extras,
  required Map<String, String> s,
  required bool bn,
}) {
  final known = extras.paper2SectionCounts;
  final offered = known.isEmpty
      ? paperTwoSections
      : paperTwoSections.where((v) {
          final n = known[v];
          return n == null || n > 0;
        }).toList();
  final list = offered.isEmpty ? paperTwoSections : offered;
  final nodes = <GlobalPickerNode>[
    for (final v in list)
      GlobalPickerNode(
        id: 'paper2:$v',
        title: s[paperTwoSectionStringKey(v)]!,
        subtitle: (known[v] ?? 0) > 0 ? numStr(known[v]!, bn) : null,
        kind: GlobalPickerNodeKind.section,
        pick: GlobalPickerPick.paper2(v),
      ),
  ];
  // The live paper's grammar (Q1-Q10) is printed only inside the
  // 60 model tests, never as a standalone bank. The note is the
  // honest pointer (and a drill-down), not a fake grammar list.
  if (extras.sets.isNotEmpty) {
    nodes.add(
      GlobalPickerNode(
        id: 'paper2-grammar-note',
        title: s['paper2GrammarInSetsNote']!,
        subtitle: s['setLabel']!,
        kind: GlobalPickerNodeKind.setsGroup,
        hasChildren: true,
      ),
    );
  }
  return nodes;
}
