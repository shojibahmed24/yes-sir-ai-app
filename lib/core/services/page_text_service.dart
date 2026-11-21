// Real book-page text for the reader: the OCR chunks imported in
// migration 007 (book_chunks) are server-only, so the app asks the
// guide-bank Edge Function for one printed page. No OCR runs here and
// nothing is invented: null = the page text is not available (or the
// call failed), and the reader says so honestly.
import 'app_config.dart';
import 'edge_post.dart';

Future<String?> fetchPageText({
  required String bookId,
  required int page,
}) async {
  if (AppConfig.guideBankEndpoint.isEmpty || bookId.isEmpty) return null;
  final res = await edgePost({
    'action': 'pageText',
    'bookId': bookId,
    'page': page,
  }, endpoint: AppConfig.guideBankEndpoint);
  if (res == null || res['found'] != true) return null;
  final text = res['text'];
  if (text is! String) return null;
  final trimmed = text.trim();
  return trimmed.isEmpty ? null : trimmed;
}
