import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun_metadata_sdk/metadata/models/album.dart';
import 'package:gyawun_metadata_sdk/metadata/models/artist.dart';
import 'package:gyawun_metadata_sdk/metadata/models/playlist.dart';
import 'package:music_are/core/router/app_routes.dart';
import 'package:music_are/features/details/album/presentation/pages/album_page.dart';
import 'package:music_are/features/details/artist/presentation/pages/artist_page.dart';
import 'package:music_are/features/details/playlist/presentation/pages/playlist_page.dart';
import 'package:music_are/features/home/presentation/pages/home_page.dart';
import 'package:music_are/features/library/presentation/pages/library_page.dart';
import 'package:music_are/features/onboarding/presentation/pages/welcome_page.dart';
import 'package:music_are/features/plugin/presentation/pages/plugin_update_page.dart';
import 'package:music_are/features/search/presentation/pages/search_page.dart';
import 'package:music_are/features/shell/presentation/pages/shell_page.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final List<RouteBase> _sharedDetailRoutes = [
  GoRoute(
    path: 'playlist',
    builder: (context, state) {
      final playlist = state.extra as Playlist;
      return PlaylistPage(playlist: playlist);
    },
  ),
  GoRoute(
    path: 'album',
    builder: (context, state) {
      final album = state.extra as Album;
      return AlbumPage(album: album);
    },
  ),
  GoRoute(
    path: 'artist',
    builder: (context, state) {
      final artist = state.extra as Artist;
      return ArtistPage(artist: artist);
    },
  ),
];

GoRouter createRouter({required String initialLocation}) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: AppRoutes.pluginUpdate,
        builder: (context, state) => const PluginUpdatePage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ShellPage(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomePage(),
                routes: _sharedDetailRoutes,
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.search,
                builder: (context, state) => const SearchPage(),
                routes: _sharedDetailRoutes,
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.library,
                builder: (context, state) => const LibraryPage(),
                routes: _sharedDetailRoutes,
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
