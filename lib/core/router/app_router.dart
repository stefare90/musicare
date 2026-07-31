import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:music_are/features/home/presentation/pages/home_page.dart';
import 'package:music_are/features/library/presentation/pages/library_page.dart';
import 'package:music_are/features/plugin/presentation/pages/plugin_selection_page.dart';
import 'package:music_are/features/search/presentation/pages/search_page.dart';
import 'package:music_are/features/shell/presentation/pages/shell_page.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

GoRouter createRouter({required String initialLocation}) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/select-plugin',
        builder: (context, state) => const PluginSelectionPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ShellPage(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/', builder: (context, state) => const HomePage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) => const SearchPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/library',
                builder: (context, state) => const LibraryPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
