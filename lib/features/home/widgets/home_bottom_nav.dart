import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Bottom nav shared by Home + Learn screens. Practice / Progress /
/// Profile are other groups' routes; integration wires them in.
class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({super.key, required this.current, required this.labels});
  final int current;
  final List<String> labels; // home, search, practice, progress, profile

  void _go(BuildContext context, int index) {
    // Phase 2 IA: the second tab is the learning hub (subjects),
    // not a bare search page — search lives in the Home field and
    // the hub's app-bar icon. Never points at a deleted route.
    const routes = [
      '/home',
      '/home/subjects',
      '/practice',
      '/progress',
      '/profile',
    ];
    context.go(routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    const icons = [
      Icons.home_outlined,
      Icons.menu_book_outlined,
      Icons.edit_note_outlined,
      Icons.trending_up_outlined,
      Icons.account_circle_outlined,
    ];
    return BottomNavigationBar(
      currentIndex: current,
      type: BottomNavigationBarType.fixed,
      onTap: (i) => _go(context, i),
      items: List.generate(5, (i) {
        return BottomNavigationBarItem(icon: Icon(icons[i]), label: labels[i]);
      }),
    );
  }
}
