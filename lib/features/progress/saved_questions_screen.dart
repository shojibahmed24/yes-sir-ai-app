// Route: /saved. Lists REAL saved ids via LocalStore's
// 'saved_questions' key. Tap opens the solution dialog
// for known questions; Unsave removes the id for real via
// PracticeStore. Empty state is honest — no mock questions shown.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yes_sir_ai/core/services/local_store.dart';
import 'package:yes_sir_ai/core/services/supabase_client.dart';
import 'package:yes_sir_ai/core/services/practice_service.dart';
import 'package:yes_sir_ai/features/learn/widgets/solution_blocks.dart';
import 'package:yes_sir_ai/features/practice/practice_store.dart';
import 'package:yes_sir_ai/features/practice/widgets/practice_widgets.dart';
import 'package:yes_sir_ai/l10n/language_provider.dart';
import 'package:yes_sir_ai/l10n/pages/saved_questions_strings.dart';
import 'package:yes_sir_ai/theme/themed_scaffold.dart';

class SavedQuestionsScreen extends StatefulWidget {
  const SavedQuestionsScreen({super.key});
  @override
  State<SavedQuestionsScreen> createState() => _SavedQuestionsScreenState();
}

class _SavedQuestionsScreenState extends State<SavedQuestionsScreen> {
  List<String> _ids = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final ids = await LocalStore.savedQuestions();
    if (mounted)
      setState(() {
        _ids = ids;
        _loading = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final s = locale.languageCode == 'bn'
            ? savedQuestionsStringsBn
            : savedQuestionsStringsEn;
        final bangla = locale.languageCode == 'bn';
        if (_loading) {
          return ThemedScaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/profile'),
              ),
              title: Text(s['title']!),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (_ids.isEmpty) {
          return ThemedScaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/profile'),
              ),
              title: Text(s['title']!),
            ),
            body: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(context).padding.bottom,
              ),
              children: [
                Text(
                  s['empty']!,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(s['emptySub']!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go('/practice'),
                  child: Text(s['startPractice']!),
                ),
              ],
            ),
          );
        }
        return ThemedScaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/profile'),
            ),
            title: Text(s['title']!),
          ),
          body: ListView.builder(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MediaQuery.of(context).padding.bottom,
            ),
            // Header (count + sync note) is row 0, then one lazy row
            // per saved id: a long saved list never builds every card.
            itemCount: _ids.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_ids.length} ${s['savedSuffix']!}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    // Cloud sync only with a signed-in user; otherwise
                    // saves live on this device only (honest label).
                    Text(
                      backendReady ? s['syncedNote']! : s['deviceOnly']!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SavedCard(
                  id: _ids[i - 1],
                  bangla: bangla,
                  s: s,
                  onRemoved: _reload,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _SavedCard extends StatelessWidget {
  const _SavedCard({
    required this.id,
    required this.bangla,
    required this.s,
    required this.onRemoved,
  });
  final String id;
  final bool bangla;
  final Map<String, String> s;
  final VoidCallback onRemoved;

  @override
  Widget build(BuildContext context) {
    final q = practiceService.findQuestion(id);
    final title = q == null ? id : (bangla ? q.questionBn : q.questionEn);
    final meta = q == null
        ? s['unknownMeta']!
        : practiceService.chapterOf(id, bangla);
    return PracticeCard(
      title: title,
      subtitle: meta,
      icon: Icons.bookmark,
      onTap: q == null
          ? null
          : () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(s['solution']!),
                // Audit-fix B3: whole dialog body via shared SolutionBlocks
                // + scroll, never one raw Text. Fence lines stripped first
                // (SolutionBlocks consumes ** and | but not ``` fences).
                content: SingleChildScrollView(
                  child: SolutionBlocks(
                    text:
                        ('${bangla ? q.questionBn : q.questionEn}\n\n${s['solution']!}: ${q.acceptedOptionTexts.join(' / ')}\n${practiceService.explanation(id, bangla)}')
                            .split('\n')
                            .where((line) => !line.trim().startsWith('```'))
                            .join('\n'),
                    fontSize: 16,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(s['close']!),
                  ),
                ],
              ),
            ),
      // H4: a Row of two buttons cannot shrink under PracticeCard's
      // 150px trailing cap (it would overflow sideways), so stack the
      // two actions vertically; the widest button fits inside the cap.
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (q != null)
            TextButton(
              onPressed: () {
                // Phase 17 (L4): bank-derived subject, never a bare
                // prefix guess. Unknown subject fails honestly with a
                // dialog instead of silently routing to a maths quiz.
                final subject = practiceService.subjectOf(id);
                if (subject == null) {
                  showDialog<void>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(s['unknownSubjectTitle']!),
                      content: Text(s['unknownSubjectBody']!),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(s['close']!),
                        ),
                      ],
                    ),
                  );
                  return;
                }
                PracticeSession.selectedSubject = subject;
                PracticeSession.quizItems = practiceService.quizFor(subject);
                context.go('/quiz');
              },
              child: Text(s['practice']!),
            ),
          TextButton(
            onPressed: () async {
              await PracticeStore.unsaveQuestion(id);
              if (context.mounted)
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(s['unsavedMsg']!)));
              onRemoved();
            },
            child: Text(s['unsave']!),
          ),
        ],
      ),
    );
  }
}
