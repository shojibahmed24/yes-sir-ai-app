// Set-rows screen (level 3): rows for exactly one set — a
// written model set (appendix-model-test) or a board set
// (board-mcq + board-written). Board rows group under their
// section headers; tapping a row opens the answer flow.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/guide_bank_model.dart';
import '../../core/services/bangla_second_fetch.dart';
import '../../core/services/billing_service.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/bangla_second_strings.dart';
import 'bangla_first_retry_state.dart';
import 'bangla_second_row_tile.dart';
import 'search_flow_answer_nav.dart';
import 'package:yes_sir_ai/theme/themed_scaffold.dart';

class _SetRowsLoaded {
  const _SetRowsLoaded({required this.rows, required this.isPremium});
  final List<GuideBankQuestion>? rows;
  final bool isPremium;
}

class BanglaSecondSetRowsScreen extends StatefulWidget {
  const BanglaSecondSetRowsScreen({
    super.key,
    required this.group,
    required this.setId,
  });
  final String group;
  final String setId;

  @override
  State<BanglaSecondSetRowsScreen> createState() =>
      _BanglaSecondSetRowsScreenState();
}

class _BanglaSecondSetRowsScreenState extends State<BanglaSecondSetRowsScreen> {
  late Future<_SetRowsLoaded> _future;

  String _sectionLabel(String? section, Map<String, String> s) {
    switch (section) {
      case 'board-mcq':
        return s['sectionBoardMcq']!;
      case 'board-written':
        return s['sectionBoardWritten']!;
      default:
        return section ?? '';
    }
  }

  String get _selfUrl =>
      '/bangla-second-set-rows?group=${widget.group}&setId=${Uri.encodeComponent(widget.setId)}';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_SetRowsLoaded> _load() async {
    final sections = widget.group == 'board'
        ? ['board-mcq', 'board-written']
        : ['appendix-model-test'];
    final results = await Future.wait([
      for (final section in sections)
        banglaSecondFetch.fetchSectionRows(section),
      billingService.isPremium().catchError((_) => false),
    ]);
    final rows = <GuideBankQuestion>[];
    var failed = false;
    for (var i = 0; i < sections.length; i++) {
      final part = results[i] as List<GuideBankQuestion>?;
      if (part == null) {
        failed = true;
      } else {
        rows.addAll(part.where((q) => q.setId == widget.setId));
      }
    }
    rows.sort((a, b) {
      final sa = a.section ?? '';
      final sb = b.section ?? '';
      if (sa != sb) return sa.compareTo(sb);
      return a.id.compareTo(b.id);
    });
    return _SetRowsLoaded(
      rows: failed ? null : rows,
      isPremium: results.last as bool,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? banglaSecondStringsBn : banglaSecondStringsEn;
        final title = widget.group == 'board'
            ? widget.setId
            : '${s['modelTestsTitle']!} ${widget.setId}';
        return ThemedScaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/bangla-second-model-tests'),
            ),
            title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          body: FutureBuilder<_SetRowsLoaded>(
            future: _future,
            builder: (context, snap) {
              if (snap.hasError) {
                return BanglaFirstRetryState(
                  message: s['unavailable']!,
                  retryLabel: s['retry']!,
                  onRetry: () => setState(() => _future = _load()),
                );
              }
              if (!snap.hasData) {
                return BanglaFirstLoadingState(label: s['loading']!);
              }
              final loaded = snap.data!;
              final rows = loaded.rows;
              if (rows == null) {
                return BanglaFirstRetryState(
                  message: s['unavailable']!,
                  retryLabel: s['retry']!,
                  onRetry: () => setState(() => _future = _load()),
                );
              }
              if (rows.isEmpty) {
                return Center(child: Text(s['empty']!));
              }
              // Lazy list (2026-11-20): a board set can exceed 100 rows,
              // so rows are built on demand. The item list only stores
              // indices/labels (no widgets), which is cheap to build.
              final items = <Object>[];
              String? lastSection;
              for (var i = 0; i < rows.length; i++) {
                final q = rows[i];
                if (widget.group == 'board' && q.section != lastSection) {
                  lastSection = q.section;
                  items.add(_sectionLabel(lastSection, s));
                }
                items.add(i);
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  if (item is String) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 4),
                      child: Text(
                        item,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    );
                  }
                  final i = item as int;
                  final q = rows[i];
                  return BanglaSecondRowTile(
                    q: q,
                    onTap: () => openSearchFlowGuideAnswer(
                      context,
                      isPremium: loaded.isPremium,
                      index: i,
                      q: q,
                      subjectId: 'bangla',
                      chapterNumber: 0,
                      schoolClass: BanglaSecondFetch.schoolClass,
                      returnTo: _selfUrl,
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
