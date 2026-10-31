// Guide answer header (2026-11-01): chapter, question type,
// printed marks, and model-test set — ONLY from row metadata.
// Board/year/question numbers are absent from row metadata, so
// they are never shown (nothing is invented here).
import 'package:flutter/material.dart';

import '../../../core/models/guide_bank_model.dart';

class GuideQuestionHeader extends StatelessWidget {
  const GuideQuestionHeader({
    super.key,
    required this.question,
    required this.chapterNumber,
    required this.fontSize,
    required this.s,
    required this.color,
  });
  final GuideBankQuestion question;
  final int chapterNumber;
  final double fontSize;
  final Map<String, String> s;
  final Color color;

  String? _typeLabel(String t) {
    switch (t) {
      case 'mcq':
        return s['filterMcq'];
      case 'short':
        return s['filterShort'];
      case 'creative':
        return s['filterCreative'];
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final parts = <String>['${s['chapterWord']!} $chapterNumber'];
    final type = _typeLabel(question.questionType);
    if (type != null) parts.add(type);
    if (question.marks != null) {
      parts.add('${question.marks} ${s['marksWord']!}');
    }
    final setId = question.setId;
    if (setId != null && setId.isNotEmpty) {
      parts.add(setId.startsWith('model-test-')
          ? '${s['modelTestWord']!} ${setId.substring('model-test-'.length)}'
          : setId);
    }
    return Text(
      parts.join(' · '),
      style: TextStyle(
        fontSize: fontSize - 1,
        fontFamily: 'HindSiliguri',
        color: color,
      ),
    );
  }
}
