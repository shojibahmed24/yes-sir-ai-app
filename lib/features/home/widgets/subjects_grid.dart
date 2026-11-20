// Subject cards for SubjectsScreen, split out to keep the screen
// under the 250-line cap. One card style app-wide: the subject's
// own colour/glyph, an honest source badge (book / guide / both)
// from server flags, and the guide card underneath when the
// subject really has guide content.
import 'package:flutter/material.dart';
import '../../../core/models/backend_models.dart';
import '../../../l10n/pages/guide_bank_strings.dart';
import '../../../l10n/pages/home_strings.dart';
import '../../../l10n/pages/subjects_strings.dart';
import '../../learn/learn_store.dart';
import '../../learn/widgets/subject_guide_card.dart';
import 'home_empty_state.dart';
import 'subject_card.dart';

/// Case-insensitive name/id match for the subject search field.
bool subjectMatches(SubjectInfo s, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return s.nameBn.toLowerCase().contains(q) ||
      s.nameEn.toLowerCase().contains(q) ||
      s.id.toLowerCase().contains(q);
}

class SubjectsGrid extends StatelessWidget {
  const SubjectsGrid({
    super.key,
    required this.subjects,
    required this.opened,
    required this.bn,
    required this.schoolClass,
    required this.onRetry,
    this.emptyMessage,
  });
  final List<SubjectInfo> subjects;
  final List<String> opened;
  final bool bn;
  final int schoolClass;
  final VoidCallback onRetry;

  /// Search misses need their own message: "no subjects" would claim
  /// the class has none, which is a different (false) statement.
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    final s = bn ? subjectsStringsBn : subjectsStringsEn;
    final gs = bn ? guideBankStringsBn : guideBankStringsEn;
    final nav = bn ? homeStringsBn : homeStringsEn;
    if (subjects.isEmpty) {
      return HomeEmptyState(
        message: emptyMessage ?? nav['noSubjects']!,
        actionLabel: nav['subjectsRetry']!,
        onAction: onRetry,
      );
    }
    return Column(
      children: [
        if (subjects.every((x) => x.locked && !x.hasGuide))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              s['emptyClassNote']!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ...subjects.map((subj) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: SubjectCard(
                  name: subj.name(bn),
                  chapters: subj.chapterCount,
                  done: LearnStore.openedChapterCount(
                    opened,
                    schoolClass,
                    subj.id,
                  ),
                  locked: subj.locked,
                  guideOnly: subj.locked && subj.hasGuide,
                  guideLabel: s['guideAvailable']!,
                  hasGuide: subj.hasGuide,
                  badgeBook: s['badgeBook']!,
                  badgeGuide: s['badgeGuide']!,
                  badgeBoth: s['badgeBoth']!,
                  subjectId: subj.id,
                  chaptersLabel: s['chapters']!,
                  lockedLabel: '${s['locked']!} — ${s['lockedHint']!}',
                ),
              ),
              // Renders nothing for guide-less subjects.
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SubjectGuideCard(subjectId: subj.id, bn: bn, s: gs),
              ),
            ],
          );
        }),
      ],
    );
  }
}
