// Developer preview of the Phase-1 component library. Shows every
// reusable widget in both themes so the owner can eyeball the design
// system without opening the whole app. Not linked from production
// navigation — reachable via /design-system for now.
import 'package:flutter/material.dart';

import '../../l10n/language_provider.dart';
import '../../l10n/pages/design_system_strings.dart';
import '../../theme/app_tokens.dart';
import '../../theme/themed_scaffold.dart';
import '../../theme/widgets/app_chip.dart';
import '../../theme/widgets/app_state_view.dart';
import '../../theme/widgets/marks_badge.dart';
import '../../theme/widgets/mcq_option_card.dart';
import '../../theme/widgets/section_header.dart';

class DesignSystemScreen extends StatelessWidget {
  const DesignSystemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? designSystemStringsBn : designSystemStringsEn;
        return ThemedScaffold(
          appBar: AppBar(title: Text(s['title']!)),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(Sp.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s['subtitle']!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: Sp.lg),
                _group(
                  context,
                  s['sections']!,
                  SectionHeader(
                    title: s['sectionTitle']!,
                    actionLabel: s['sectionAction']!,
                    onAction: () {},
                  ),
                ),
                _group(
                  context,
                  s['chips']!,
                  Wrap(
                    spacing: Sp.sm,
                    runSpacing: Sp.sm,
                    children: [
                      AppChip(label: s['chipAll']!),
                      AppChip(
                        label: s['chipMcq']!,
                        selected: true,
                        onTap: () {},
                      ),
                      AppChip(
                        label: s['chipCreative']!,
                        icon: Icons.edit_note_rounded,
                      ),
                    ],
                  ),
                ),
                _group(
                  context,
                  s['marks']!,
                  Wrap(
                    spacing: Sp.sm,
                    runSpacing: Sp.sm,
                    children: const [
                      MarksBadge(label: '১'),
                      MarksBadge(label: '২'),
                      MarksBadge(label: '৩'),
                      MarksBadge(label: '৪', important: true),
                    ],
                  ),
                ),
                _group(
                  context,
                  s['options']!,
                  Column(
                    children: [
                      McqOptionCard(label: 'ক', text: s['optionA']!),
                      const SizedBox(height: Sp.sm),
                      McqOptionCard(
                        label: 'খ',
                        text: s['optionB']!,
                        state: McqOptionState.selected,
                        onTap: () {},
                      ),
                      const SizedBox(height: Sp.sm),
                      McqOptionCard(
                        label: 'গ',
                        text: s['optionC']!,
                        state: McqOptionState.correct,
                      ),
                      const SizedBox(height: Sp.sm),
                      McqOptionCard(
                        label: 'ঘ',
                        text: s['optionD']!,
                        state: McqOptionState.wrong,
                      ),
                    ],
                  ),
                ),
                _group(
                  context,
                  s['states']!,
                  Column(
                    children: [
                      SizedBox(
                        height: 160,
                        child: AppStateView(
                          kind: AppStateKind.empty,
                          title: s['emptyTitle']!,
                          message: s['emptyBody']!,
                        ),
                      ),
                      const SizedBox(height: Sp.sm),
                      SizedBox(
                        height: 160,
                        child: AppStateView(
                          kind: AppStateKind.error,
                          title: s['errorTitle']!,
                          message: s['errorBody']!,
                          actionLabel: s['retry']!,
                          onAction: () {},
                        ),
                      ),
                      const SizedBox(height: Sp.sm),
                      SizedBox(
                        height: 120,
                        child: AppStateView(
                          kind: AppStateKind.loading,
                          title: s['chipAll']!,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _group(BuildContext context, String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: Sp.sm),
          child,
        ],
      ),
    );
  }
}
