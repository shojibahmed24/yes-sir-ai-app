// One place that builds the lesson-hub route, so the picker and any
// future caller produce the same, properly encoded URL.
String lessonHubRoute({
  required String subject,
  required int schoolClass,
  required int chapter,
  String? lesson,
  required String title,
}) => Uri(
  path: '/lesson-hub',
  queryParameters: {
    'subject': subject,
    'class': '$schoolClass',
    'chapter': '$chapter',
    if (lesson != null) 'lesson': lesson,
    'title': title,
  },
).toString();
