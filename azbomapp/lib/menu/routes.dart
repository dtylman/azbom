import 'package:azbomapp/pages/deps_page.dart';
import 'package:azbomapp/pages/home_page.dart';
import 'package:azbomapp/pages/sbom_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Routes {
  static const String sbom = '/sbom';
  static const String deps = '/deps';
}

// Define the routes for the app
final appRouter = GoRouter(
  initialLocation: Routes.sbom,
  debugLogDiagnostics: true,
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return HomePage(child: child);
      },
      routes: [
        GoRoute(
          path: Routes.sbom,
          builder: (context, state) => const SbomPage(),
        ),
        GoRoute(
          path: Routes.deps,
          builder: (context, state) => const DepsPage(),
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
    MenuItem('SBOM', Icons.archive_outlined, Icons.archive, Routes.sbom),
    MenuItem(
        'Dependencies', Icons.explore_outlined, Icons.explore, Routes.deps),
  ];
}
