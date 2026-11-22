// Structured "last studied" record (C10).
//
// The old four-part key (subject|chapter|page|problem) could not
// describe a guide question, so Home showed "অধ্যায় ৯৭ · পৃষ্ঠা ০ ·
// প্রশ্ন ০". This record carries the real fields, and only the ones
// that exist are rendered.
import 'dart:convert';

class LastStudy {
  const LastStudy({
    required this.subject,
    required this.chapter,
    this.chapterTitleBn = '',
    this.chapterTitleEn = '',
    this.lesson,
    this.questionId,
    this.questionSnippet = '',
    this.schoolClass,
  });

  final String subject;
  final int chapter;
  final String chapterTitleBn;
  final String chapterTitleEn;
  final String? lesson;
  final String? questionId;
  final String questionSnippet;
  final int? schoolClass;

  String chapterTitle(bool bn) {
    final t = bn ? chapterTitleBn : chapterTitleEn;
    return t.isEmpty ? (bn ? 'অধ্যায় $chapter' : 'Chapter $chapter') : t;
  }

  Map<String, dynamic> toJson() => {
    'subject': subject,
    'chapter': chapter,
    'chapterTitleBn': chapterTitleBn,
    'chapterTitleEn': chapterTitleEn,
    if (lesson != null) 'lesson': lesson,
    if (questionId != null) 'questionId': questionId,
    if (questionSnippet.isNotEmpty) 'snippet': questionSnippet,
    if (schoolClass != null) 'schoolClass': schoolClass,
  };

  static LastStudy? fromJson(Map<String, dynamic> j) {
    final subject = j['subject'];
    final chapter = j['chapter'];
    if (subject is! String || subject.isEmpty || chapter is! num) return null;
    return LastStudy(
      subject: subject,
      chapter: chapter.toInt(),
      chapterTitleBn: '${j['chapterTitleBn'] ?? ''}',
      chapterTitleEn: '${j['chapterTitleEn'] ?? ''}',
      lesson: j['lesson'] is String ? j['lesson'] as String : null,
      questionId: j['questionId'] is String ? j['questionId'] as String : null,
      questionSnippet: '${j['snippet'] ?? ''}',
      schoolClass: (j['schoolClass'] as num?)?.toInt(),
    );
  }

  static LastStudy? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final j = jsonDecode(raw);
      return j is Map<String, dynamic> ? fromJson(j) : null;
    } catch (_) {
      return null;
    }
  }
}
