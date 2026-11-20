// Memoized textbook-chapter filter (2026-11-20 quick-load).
// Filtering a whole chapter on every build meant re-scanning hundreds
// of rows on every keystroke. This cache keeps the last result keyed
// by the inputs that actually change it; the filter itself stays in
// textbook_filter.dart (pure, unchanged).
import '../../core/services/textbook_chapter_service.dart';
import 'widgets/textbook_filter.dart';

class ChapterFilterCache {
  List<TextbookChapterQuestion>? _cache;
  String _key = '';

  List<TextbookChapterQuestion> filter({
    required List<TextbookChapterQuestion> all,
    required String type,
    required String query,
    required String pageText,
    required int epoch,
  }) {
    final key = '${all.length}|$type|$query|$pageText|$epoch';
    if (_cache != null && key == _key) return _cache!;
    final out = filterTextbookQuestions(
      all: all,
      type: type,
      query: query,
      page: int.tryParse(pageText.trim()),
    );
    _key = key;
    _cache = out;
    return out;
  }
}
