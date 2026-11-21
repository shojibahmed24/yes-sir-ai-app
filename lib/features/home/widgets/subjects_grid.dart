// Subject cards for SubjectsScreen, split out to keep the screen
// under the 250-line cap. Subjects are grouped by what the class
// actually has (book + guide / guide only / book only / none yet),
// so a student sees the usable ones first instead of one long list.
// One card style app-wide: subject colour/glyph, an honest source
// badge from server flags, and the guide card underneath when the
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

/// One display group: a heading plus the subjects under it.
class SubjectGroup {
  const SubjectGroup({required this.title, required this.subjects});
  final String title;
  final List<SubjectInfo> subjects;
}

/// Pure grouping, in the order a student needs it: everything they
/// can use right now first, not-yet-available subjects last. Empty
/// groups are dropped, so no heading ever sits over nothing.
List<SubjectGroup> groupSubjects(List<SubjectInfo> all, Map<String, String> s) {
  final both = <SubjectInfo>[];
  final guide = <SubjectInfo>[];
  final book = <SubjectInfo>[];
  final locked = <SubjectInfo>[];
  for (final x in all) {
    if (x.locked && x.hasGuide) {
      guide.add(x);
    } else if (x.locked) {
      locked.add(x);
    } else if (x.hasGuide) {
      both.add(x);
    } else {
      book.add(x);
    }
  }
  return [
    if (both.isNotEmpty) SubjectGroup(title: s['groupBoth']!, subjects: both),
    if (guide.isNotEmpty)
      SubjectGroup(title: s['groupGuide']!, subjects: guide),
    if (book.isNotEmpty) SubjectGroup(title: s['groupBook']!, subjects: book),
    if (locked.isNotEmpty)
      SubjectGroup(title: s['groupLocked']!, subjects: locked),
  ];
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
    // Classes 1–5 have no books or guides yet: say so instead of
    // listing every subject as "not added" (owner decision).
    if (schoolClass <= 5) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s['classComingSoon']!,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s['classComingSoonBody']!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    if (subjects.isEmpty) {
      return HomeEmptyState(
        message: emptyMessage ?? nav['noSubjects']!,
        actionLabel: nav['subjectsRetry']!,
        onAction: onRetry,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (subjects.every((x) => x.locked && !x.hasGuide))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              s['emptyClassNote']!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        for (final group in groupSubjects(subjects, s)) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: Text(
              '${group.title} · ${group.subjects.length}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final subj in group.subjects) _card(context, subj, s, gs),
        ],
      ],
    );
  }

  Widget _card(
    BuildContext context,
    SubjectInfo subj,
    Map<String, String> s,
    Map<String, String> gs,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: SubjectCard(
            name: subj.name(bn),
            chapters: subj.chapterCount,
            done: LearnStore.openedChapterCount(opened, schoolClass, subj.id),
            locked: subj.locked,
            guideOnly: subj.locked && subj.hasGuide,
            guideLabel: s['guideAvailable']!,
            hasGuide: subj.hasGuide,
            badgeBook: s['badgeBook']!,
            badgeGuide: s['badgeGuide']!,
            badgeBoth: s['badgeBoth']!,
            sharedClass: schoolClass == 10 ? s['sharedBook'] : null,
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
  }
}
