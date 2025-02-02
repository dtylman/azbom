import 'package:azbomapp/pages/home_page.dart';
import 'package:azbomapp/pages/scrreen_a.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Define the routes for the app
final appRouter = GoRouter(
  initialLocation: '/explorer',
  debugLogDiagnostics: true,
  routes: [
    ShellRoute(
      builder: (context, state, child) {return HomePage(child: child);},
      routes: [
        GoRoute(
          path: '/explorer',
          builder: (context, state) => const ScreenA("Home"),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const ScreenA("Search"),
        ),
      ],
    ),
  ],
);

/// The main menu items for the app
class MenuItem {
  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final String route;

  MenuItem(this.title, this.icon, this.selectedIcon, this.route);

  static List<MenuItem> mainMenu = [
    MenuItem('Explorer', Icons.folder, Icons.folder_open, '/explorer'),
    MenuItem('Search', Icons.search, Icons.search, '/search'),
    MenuItem('Source Control', Icons.source, Icons.source, '/source'),
    MenuItem('Run & Debug', Icons.bug_report, Icons.bug_report, '/run'),
    MenuItem('Extensions', Icons.extension, Icons.extension, '/extensions'),
  ];
}
