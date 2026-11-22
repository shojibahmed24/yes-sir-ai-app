// THE picker for the search flow: one widget, every subject.
// Renders the tree the adapters build: a search field on top, a
// drill-down list below, a back row when drilled in. Quick-load
// rules: no network calls of its own (data lives in the
// controller/extras state, loaded once per subject change),
// client-side filtering only, and a lazily built list — so
// opening, drilling, and going back are all instant after the
// first load. Branch taps drill; leaf taps pick.
import 'package:flutter/material.dart';

import '../global_picker_model.dart';
import 'search_flow_field_states.dart';

class GlobalPicker extends StatefulWidget {
  const GlobalPicker({
    super.key,
    required this.treeKey,
    required this.tree,
    required this.s,
    required this.selectedId,
    required this.onPick,
    this.onBranch,
  });
  final String treeKey;
  final GlobalPickerTree tree;
  final Map<String, String> s;
  final String? selectedId;
  final void Function(GlobalPickerPick pick) onPick;

  /// Fired when a branch node is drilled into (stateful adapters,
  /// e.g. English, load the branch's lessons here).
  final void Function(GlobalPickerNode node)? onBranch;

  @override
  State<GlobalPicker> createState() => _GlobalPickerState();
}

class _GlobalPickerState extends State<GlobalPicker> {
  final _filterCtrl = TextEditingController();
  final _path = <GlobalPickerNode>[];
  String _filter = '';

  @override
  void didUpdateWidget(GlobalPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.treeKey != widget.treeKey) {
      _path.clear();
      _filter = '';
      _filterCtrl.clear();
    }
  }

  @override
  void dispose() {
    _filterCtrl.dispose();
    super.dispose();
  }

  List<GlobalPickerNode>? get _current {
    if (_path.isEmpty) return widget.tree.rootNodes;
    return widget.tree.childrenOf(_path.last);
  }

  void _onTap(GlobalPickerNode node) {
    if (node.hasChildren) {
      widget.onBranch?.call(node);
      setState(() => _path.add(node));
      return;
    }
    final pick = node.pick;
    if (pick != null) widget.onPick(pick);
  }

  @override
  Widget build(BuildContext context) {
    final nodes = _current;
    final q = _filter.trim().toLowerCase();
    final visible = nodes == null
        ? null
        : q.isEmpty
        ? nodes
        : nodes
              .where(
                (n) =>
                    n.title.toLowerCase().contains(q) ||
                    (n.subtitle?.toLowerCase().contains(q) ?? false),
              )
              .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _filterCtrl,
          decoration: InputDecoration(
            hintText: widget.s['pickerSearchHint'],
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
          ),
          onChanged: (v) => setState(() => _filter = v),
        ),
        const SizedBox(height: 12),
        if (_path.isNotEmpty)
          InkWell(
            onTap: () => setState(() => _path.removeLast()),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.arrow_back, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _path.last.title,
                      style: Theme.of(context).textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (widget.tree.loading && _path.isEmpty)
          SearchFlowLoadingBars(
            label: widget.s['pickerLoading']!,
            semanticsLabel: widget.s['pickerLoading']!,
          )
        else if (nodes == null)
          SearchFlowLoadingBars(
            label: widget.s['pickerLoading']!,
            semanticsLabel: widget.s['pickerLoading']!,
          )
        else if (visible!.isEmpty)
          SearchFlowEmptyCard(
            // The field label names the picker; "Loading." here read
            // as a contradiction next to "No items found".
            label: widget.s['chapterLabel']!,
            message: widget.s['pickerEmpty']!,
          )
        else
          // C6: one grouped card with hairline dividers instead of five
          // separate outlined boxes. Each row keeps a clear hierarchy:
          // index/type badge, bold title, one-line subtitle, chevron;
          // the selected row is tinted with a check.
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  if (i > 0) const Divider(height: 1, thickness: 1),
                  _PickerRow(
                    node: visible[i],
                    index: i,
                    selected: visible[i].id == widget.selectedId,
                    onTap: () => _onTap(visible[i]),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// One row of the grouped picker list (C6).
class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.node,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  final GlobalPickerNode node;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: selected ? cs.primary.withValues(alpha: 0.08) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? cs.primary
                      : cs.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: node.hasChildren
                    ? Icon(
                        Icons.folder_outlined,
                        size: 17,
                        color: selected ? cs.onPrimary : cs.primary,
                      )
                    : Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: selected ? cs.onPrimary : cs.primary,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (node.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        node.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                node.hasChildren
                    ? Icons.chevron_right
                    : (selected ? Icons.check : Icons.chevron_right),
                size: 20,
                color: selected ? cs.primary : cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
