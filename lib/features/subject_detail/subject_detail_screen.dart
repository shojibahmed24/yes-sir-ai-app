// Route: /home/subjects/:subjectId — subject overview. Loads the
// real subject row (name + chapter count) for the profile class and
// the student's opened chapters, then renders SubjectDetailBody.
// A subject that is not in the profile class shows the honest
// not-found state; nothing is invented.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/backend_models.dart';
import '../../core/services/books_service.dart';
import '../../core/services/resolve_school_class.dart';
import '../../l10n/language_provider.dart';
import '../../theme/themed_scaffold.dart';
import '../../theme/widgets/app_state_view.dart';
import '../learn/learn_store.dart';
import 'subject_detail_body.dart';
import 'subject_detail_strings.dart';

class SubjectDetailScreen extends StatefulWidget {
  const SubjectDetailScreen({super.key, required this.subjectId});
  final String subjectId;

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  Future<SubjectDetailInfo?>? _future;
  bool? _futureBn;

  Future<SubjectDetailInfo?> _load(bool bn) async {
    final cls = await resolveSchoolClass();
    final opened = await LearnStore.chaptersList();
    final subjects = await booksService.subjectsAsync(cls, bn);
    final match = subjects.where((s) => s.id == widget.subjectId);
    if (match.isEmpty) return null;
    final SubjectInfo subj = match.first;
    final openedHere = opened.where((c) => c.startsWith('${subj.id}|')).length;
    return SubjectDetailInfo(
      subjectId: subj.id,
      name: subj.name(bn),
      schoolClass: cls,
      chapters: subj.chapterCount,
      opened: openedHere,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? subjectDetailStringsBn : subjectDetailStringsEn;
        if (_future == null || _futureBn != bn) {
          _future = _load(bn);
          _futureBn = bn;
        }
        return ThemedScaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/home/subjects'),
            ),
            title: Text(s['title'] ?? ''),
          ),
          body: FutureBuilder<SubjectDetailInfo?>(
            future: _future,
            builder: (context, snap) {
              if (!snap.hasData) {
                if (snap.hasError) {
                  return AppStateView(
                    kind: AppStateKind.error,
                    title: s['notFound']!,
                    message: s['notFoundSub']!,
                    actionLabel: s['retry']!,
                    onAction: () => setState(() => _future = null),
                  );
                }
                return AppStateView(
                  kind: AppStateKind.loading,
                  title: s['loading']!,
                );
              }
              final info = snap.data;
              if (info == null) {
                return AppStateView(
                  kind: AppStateKind.empty,
                  title: s['notFound']!,
                  message: s['notFoundSub']!,
                );
              }
              return SubjectDetailBody(info: info, bn: bn);
            },
          ),
        );
      },
    );
  }
}
