// Home design tokens + paper-aware display names (dashboard
// redesign, Phase 1 + 3). One spacing scale and one card radius
// for the whole Home screen: section gaps used to drift between
// 12/16/20 with no rule. Colours stay in AppTheme; these are
// layout only. Paper names are DISPLAY ONLY: server ids never
// change, routes never change.
import 'package:flutter/material.dart';

class HomeDesign {
  static const double screenPadding = 20;
  static const double sectionGap = 20;
  static const double blockGap = 16;
  static const double tightGap = 12;
  static const double cardGap = 12;
  static const double cardRadius = 24;
}

/// Per-subject glyph for tiles/cards. Unknown ids share ONE neutral
/// fallback: a subject gets a specific icon only when the id is one
/// the app actually knows, never a guessed one.
IconData subjectIconFor(String id) => switch (id) {
  'math' => Icons.calculate_outlined,
  'higher-math' => Icons.functions,
  'science' => Icons.science_outlined,
  'physics' => Icons.bolt_outlined,
  'chemistry' => Icons.biotech_outlined,
  'biology' => Icons.eco_outlined,
  'bangla' => Icons.menu_book_outlined,
  'english' => Icons.translate,
  'english-2nd' => Icons.spellcheck,
  'bgs' => Icons.public_outlined,
  'civics' => Icons.gavel_outlined,
  'economics' => Icons.trending_up,
  'accounting' => Icons.account_balance_outlined,
  'business-entrepreneurship' => Icons.storefront_outlined,
  'ict' => Icons.computer_outlined,
  'religion' => Icons.mosque_outlined,
  _ => Icons.menu_book_outlined,
};

/// Paper-aware tile name. The class-10 Bangla guide book shares
/// subject_id 'bangla' with 1st paper, so a plain server name
/// would just say "বাংলা" for both papers. The profile class
/// decides the paper label; any other class or subject falls
/// back to the server name untouched.
String paperSubjectName(String id, String fallback, bool bn, int? schoolClass) {
  if (id == 'bangla' || id == 'bangla-1st') {
    if (id == 'bangla-1st') return bn ? 'বাংলা ১ম পত্র' : 'Bangla 1st Paper';
    if (schoolClass == 10) {
      return bn ? 'বাংলা ২য় পত্র' : 'Bangla 2nd Paper';
    }
    if (schoolClass == 9) {
      return bn ? 'বাংলা ১ম পত্র' : 'Bangla 1st Paper';
    }
    return fallback;
  }
  if (id == 'bangla-2nd') {
    return bn ? 'বাংলা ২য় পত্র' : 'Bangla 2nd Paper';
  }
  if (id == 'english') {
    if (schoolClass == 9 || schoolClass == 10) {
      return bn ? 'ইংরেজি ১ম পত্র' : 'English 1st Paper';
    }
    return fallback;
  }
  if (id == 'english-2nd') {
    return bn ? 'ইংরেজি ২য় পত্র' : 'English 2nd Paper';
  }
  return fallback;
}
