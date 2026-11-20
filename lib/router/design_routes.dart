// Developer-preview route for the Phase-1 component library.
// Debug-only: it is never registered in release builds, so the
// preview cannot ship to Play. Kept in its own file so app_router
// stays small.
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../features/design_system/design_system_screen.dart';

final List<RouteBase> designRoutes = [
  if (kDebugMode)
    GoRoute(
      path: '/design-system',
      builder: (context, state) => const DesignSystemScreen(),
    ),
];
