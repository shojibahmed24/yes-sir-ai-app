// Board year/board facets (round 4).
//
// The Edge action 'boardFacets' returns the real (board, year) pairs
// of a subject's flagged board rows with their counts, so the board
// screen can offer honest chips instead of a guessed year list.
import 'app_config.dart';
import 'edge_post.dart';

class BoardFacet {
  const BoardFacet({
    required this.board,
    required this.year,
    required this.mcq,
    required this.creative,
  });
  final String board;
  final int year;
  final int mcq;
  final int creative;
  int get total => mcq + creative;
}

/// Null = unreachable/unknown (never an empty chip list presented as
/// "no board questions").
Future<List<BoardFacet>?> fetchBoardFacets({
  required String subject,
  required int schoolClass,
}) async {
  if (AppConfig.guideBankEndpoint.isEmpty) return null;
  final res = await edgePost({
    'action': 'boardFacets',
    'classId': schoolClass,
    'subject': subject,
  }, endpoint: AppConfig.guideBankEndpoint).catchError((_) => null);
  if (res == null || res['found'] != true) return null;
  final list = res['facets'];
  if (list is! List) return null;
  final out = <BoardFacet>[];
  for (final f in list) {
    if (f is! Map) continue;
    final board = f['board'];
    final year = f['year'];
    if (board is! String || year is! num) continue;
    out.add(
      BoardFacet(
        board: board,
        year: year.toInt(),
        mcq: (f['mcq'] as num?)?.toInt() ?? 0,
        creative: (f['creative'] as num?)?.toInt() ?? 0,
      ),
    );
  }
  return out;
}
