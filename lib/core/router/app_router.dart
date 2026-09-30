import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/router/app_routes.dart';
import 'package:music_are/features/details/album/presentation/pages/album_page.dart';
import 'package:music_are/features/details/artist/presentation/pages/artist_page.dart';
import 'package:music_are/features/details/playlist/presentation/pages/playlist_page.dart';
import 'package:music_are/features/home/presentation/pages/home_page.dart';
import 'package:music_are/features/library/presentation/pages/downloads_page.dart';
import 'package:music_are/features/library/presentation/pages/library_page.dart';
import 'package:music_are/features/library/presentation/pages/liked_tracks_page.dart';
import 'package:music_are/features/onboarding/presentation/pages/welcome_page.dart';
import 'package:music_are/features/plugin/metadata/presentation/pages/metadata_plugin_update_page.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/search/presentation/pages/search_page.dart';
import 'package:music_are/features/settings/presentation/pages/plugin_detail_page.dart';
import 'package:music_are/features/settings/presentation/pages/settings_page.dart';
import 'package:music_are/features/shell/presentation/pages/shell_page.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final List<RouteBase> _sharedDetailRoutes = [
  GoRoute(
    path: AppRoutes.playlistSegment,
    builder: (context, state) {
      final playlist = state.extra as Playlist;
      return PlaylistPage(playlist: playlist);
    },
  ),
  GoRoute(
    path: AppRoutes.albumSegment,
    builder: (context, state) {
      final album = state.extra as Album;
      return AlbumPage(album: album);
    },
  ),
  GoRoute(
    path: AppRoutes.artistSegment,
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
        builder: (context, state) => const MetadataPluginUpdatePage(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsPage(),
        routes: [
          GoRoute(
            path: AppRoutes.settingsPluginSegment,
            builder: (context, state) {
              final type = PluginType.fromString(
                state.pathParameters[AppRoutes.pluginTypeParam] ?? '',
              );
              return type == null
                  ? const SettingsPage()
                  : PluginDetailPage(type: type);
            },
          ),
        ],
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
                routes: [
                  ..._sharedDetailRoutes,
                  GoRoute(
                    path: AppRoutes.likedSegment,
                    builder: (context, state) => const LikedTracksPage(),
                  ),
                  GoRoute(
                    path: AppRoutes.downloadsSegment,
                    builder: (context, state) => const DownloadsPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
