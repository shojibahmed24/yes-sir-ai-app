// Developer-preview route for the Phase-1 component library.
// Not linked from production navigation; remove before Play release
// if it should not ship. Kept in its own file so app_router stays
// small and the preview can be dropped cleanly.
import 'package:go_router/go_router.dart';

import '../features/design_system/design_system_screen.dart';

final List<RouteBase> designRoutes = [
  GoRoute(
    path: '/design-system',
    builder: (context, state) => const DesignSystemScreen(),
  ),
];
