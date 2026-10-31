// Books + subjects + chapters. Supabase when configured, DEMO
// fallback otherwise. Real schema (supabase/migrations/002_books.sql):
//   books_public VIEW: id, class_id, subject_id, language, title,
//     supplied, created_at. Clients query the VIEW, never the books
//     table: the table holds server-only source_link and deliberately
//     has no client RLS policy, so direct reads stay blocked.
//   subjects table: id, name_bn, name_en.
//   chapters table: id, book_id, number, title_bn, title_en.
// book_questions is NEVER queried from the app: migration 002 gives
// it no client read policy on purpose (server / Edge Function only).
// That is why question-level resolution lives in LearnService as a
// DB chapter check + no-match gate, not a question lookup (see C2).
// Async methods fall back to the local DEMO lists on any query
// failure instead of crashing. A query that SUCCEEDS with zero rows
// is returned as-is: an empty class really has no books. Locked
// rule preserved: a subject with no supplied book is locked — the
// UI shows Locked and offers no lesson/practice/AI for it. The
// dropped minority-language book is not listed anywhere.
import '../models/backend_models.dart';
import 'books_fallback.dart';
import 'guide_subject_flags.dart';
import 'supabase_client.dart';

/// Tiny in-memory TTL cache: one entry per key, dropped after
/// [ttl]. Only successful DB reads are cached — failures and
/// DEMO fallbacks are never cached, so recovery is never hidden
/// behind a stale entry.
class _TtlCache<T> {
  static const ttl = Duration(minutes: 5);
  final _entries = <String, ({T value, DateTime at})>{};
  T? get(String key) {
    final e = _entries[key];
    if (e == null) return null;
    if (DateTime.now().difference(e.at) > ttl) {
      _entries.remove(key);
      return null;
    }
    return e.value;
  }

  void set(String key, T value) =>
      _entries[key] = (value: value, at: DateTime.now());

  void remove(String key) => _entries.remove(key);
}

class BooksService {
  final _booksCache = _TtlCache<List<BookInfo>>();
  final _subjectsCache = _TtlCache<List<SubjectInfo>>();
  final _chaptersCache = _TtlCache<List<ChapterInfo>>();
  // DEMO fallbacks live in books_fallback.dart; the async methods
  // below are the real Supabase reads.
  List<BookInfo> classBooks(int schoolClass, bool bangla) =>
      fallbackClassBooks(schoolClass, bangla);

  List<BookInfo> lockedBooks(bool bangla) => fallbackLockedBooks(bangla);

  List<String> chaptersFor(String subject) => fallbackChapters();

  List<SubjectInfo> _fallbackSubjects(int schoolClass) =>
      fallbackSubjectsForClass(schoolClass);

  List<Map<String, dynamic>> _rows(dynamic res) {
    if (res is List) return res.whereType<Map<String, dynamic>>().toList();
    return const [];
  }

  void _sortSubjects(List<SubjectInfo> list) {
    list.sort((a, b) {
      final ia = coreSubjectOrder.indexOf(a.id);
      final ib = coreSubjectOrder.indexOf(b.id);
      if (ia >= 0 && ib >= 0) return ia.compareTo(ib);
      if (ia >= 0) return -1;
      if (ib >= 0) return 1;
      return a.id.compareTo(b.id);
    });
  }

  /// Drops one cached subjects entry, so the next call
  /// revalidates against the server (home grid refresh).
  void invalidateSubjectsCache(int schoolClass, bool bangla) {
    _subjectsCache.remove('$schoolClass:$bangla');
  }
  /// The view has one title column, so titleBn == titleEn == the
  /// row's title (Bangla for 'bn' rows, English for 'en' rows).
  Future<List<BookInfo>> classBooksAsync(int schoolClass, bool bangla) async {
    final client = supabaseOrNull;
    if (client == null) return classBooks(schoolClass, bangla);
    final key = '$schoolClass:$bangla';
    final hit = _booksCache.get(key);
    if (hit != null) return hit;
    try {
      final res = await client
          .from('books_public')
          .select('id, class_id, subject_id, language, title, supplied')
          .eq('class_id', schoolClass)
          .eq('language', bangla ? 'bn' : 'en')
          .order('subject_id')
          .order('title');
      final out = _rows(res)
          .map(
            (r) => BookInfo(
              id: '${r['id']}',
              titleBn: '${r['title']}',
              titleEn: '${r['title']}',
              subject: '${r['subject_id']}',
              schoolClass: schoolClass,
              supplied: r['supplied'] == true,
            ),
          )
          .toList();
      _booksCache.set(key, out);
      return out;
    } catch (_) {
      return classBooks(schoolClass, bangla);
    }
  }

  /// All subjects with locked state + real chapter counts for one
  /// class + UI language. Subjects come from the subjects table;
  /// locked = no supplied book row for this class + language;
  /// chapter counts come from the chapters table via that class's
  /// book ids. Any failure returns the DEMO fallback list.
  /// Guide sourcing (all classes): a LOCKED subject is enriched
  /// with server guide-bank chapters (Edge guideChapters, the
  /// same action the guide screens use — class 10 falls back to
  /// the class-9 book server-side). hasGuide = at least one guide
  /// chapter; guideChapterCount = that chapter count. Checks run
  /// in parallel, one per locked subject, each capped at 8s, and
  /// any failure leaves hasGuide false — never a guessed true.
  /// The enriched list is cached like the plain list (5-min TTL),
  /// so the checks run at most once per cache window.
  Future<List<SubjectInfo>> subjectsAsync(int schoolClass, bool bangla) async {
    final client = supabaseOrNull;
    if (client == null) return _fallbackSubjects(schoolClass);
    final key = '$schoolClass:$bangla';
    final hit = _subjectsCache.get(key);
    if (hit != null) return hit;
    try {
      final lang = bangla ? 'bn' : 'en';
      final subjRes = await client
          .from('subjects')
          .select('id, name_bn, name_en');
      final bookRes = await client
          .from('books_public')
          .select('id, subject_id, title, supplied')
          .eq('class_id', schoolClass)
          .eq('language', lang);
      final books = _rows(bookRes);
      final bookSubject = <String, String>{};
      final suppliedSubjects = <String>{};
      for (final b in books) {
        bookSubject['${b['id']}'] = '${b['subject_id']}';
        if (b['supplied'] == true) suppliedSubjects.add('${b['subject_id']}');
      }
      final counts = <String, int>{};
      if (books.isNotEmpty) {
        final chapRes = await client
            .from('chapters')
            .select('book_id')
            .inFilter('book_id', books.map((b) => '${b['id']}').toList());
        for (final c in _rows(chapRes)) {
          final s = bookSubject['${c['book_id']}'];
          if (s != null) counts[s] = (counts[s] ?? 0) + 1;
        }
      }
      final out = _rows(subjRes).map((r) {
        final id = '${r['id']}';
        return SubjectInfo(
          id: id,
          nameBn: '${r['name_bn']}',
          nameEn: '${r['name_en']}',
          locked: !suppliedSubjects.contains(id),
          chapterCount: counts[id] ?? 0,
        );
      }).toList();
      _sortSubjects(out);
      final enriched = await withGuideFlags(out, schoolClass);
      // Server-wins (Step 4): an INCOMPLETE enrichment is served
      // but NEVER cached — a partial snapshot must not shadow
      // the real server count for 5 minutes.
      if (enriched.complete) _subjectsCache.set(key, enriched.subjects);
      return enriched.subjects;
    } catch (_) {
      return _fallbackSubjects(schoolClass);
    }
  }

  /// Chapters of one subject's book(s) in one UI language, ordered
  /// by book then chapter number. Returns null when unconfigured or
  /// when a query fails (caller uses the DEMO fallback), and an
  /// empty list when the subject genuinely has no book / chapters.
  Future<List<ChapterInfo>?> chaptersForSubjectAsync(
    int schoolClass,
    String subject,
    bool bangla,
  ) async {
    final client = supabaseOrNull;
    if (client == null) return null;
    final key = '$schoolClass:$subject:$bangla';
    final hit = _chaptersCache.get(key);
    if (hit != null) return hit;
    try {
      final lang = bangla ? 'bn' : 'en';
      final bookRes = await client
          .from('books_public')
          .select('id, subject_id, title, supplied')
          .eq('class_id', schoolClass)
          .eq('subject_id', subject)
          .eq('language', lang)
          .order('title');
      final books = _rows(bookRes);
      if (books.isEmpty) {
        _chaptersCache.set(key, const []);
        return const [];
      }
      final titles = {for (final b in books) '${b['id']}': '${b['title']}'};
      final bookOrder = books.map((b) => '${b['id']}').toList();
      final chapRes = await client
          .from('chapters')
          .select('id, book_id, number, title_bn, title_en')
          .inFilter('book_id', bookOrder)
          .order('number');
      final chapters = _rows(chapRes)
          .map(
            (r) => ChapterInfo(
              id: '${r['id']}',
              bookId: '${r['book_id']}',
              bookTitle: titles['${r['book_id']}'] ?? '',
              number: (r['number'] as num?)?.toInt() ?? 0,
              titleBn: '${r['title_bn']}',
              titleEn: '${r['title_en']}',
            ),
          )
          .toList();
      chapters.sort((a, b) {
        final ia = bookOrder.indexOf(a.bookId);
        final ib = bookOrder.indexOf(b.bookId);
        if (ia != ib) return ia.compareTo(ib);
        return a.number.compareTo(b.number);
      });
      _chaptersCache.set(key, chapters);
      return chapters;
    } catch (_) {
      return null;
    }
  }
}

final booksService = BooksService();
