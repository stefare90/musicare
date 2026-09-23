import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/features/player/presentation/widgets/player_track_info.dart';

void main() {
  group('PlayerTrackInfo Widget Tests', () {
    final artist1 = Artist(id: 'a1', name: 'The Beatles', externalUri: '');
    final artist2 = Artist(id: 'a2', name: 'John Lennon', externalUri: '');

    Track createTrack(List<Artist> artists) {
      return Track(
        id: 't1',
        name: 'Come Together',
        externalUri: '',
        artists: artists,
        album: Album(
          id: 'al1',
          name: 'Abbey Road',
          artists: artists,
          releaseDate: '1969',
          externalUri: '',
          totalTracks: 1,
          albumType: AlbumType.album,
        ),
        durationMs: 200000,
      );
    }

    Widget buildTestableWidget(Track track, {VoidCallback? onCollapse}) {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => Scaffold(
              body: PlayerTrackInfo(track: track, onCollapse: onCollapse),
            ),
          ),
          GoRoute(
            path: '/artist',
            builder: (_, __) => const Scaffold(body: Text('Artist Detail Page')),
          ),
        ],
      );
      return MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      );
    }

    testWidgets('renders track title and artist name', (tester) async {
      final track = createTrack([artist1]);
      await tester.pumpWidget(buildTestableWidget(track));
      await tester.pumpAndSettle();

      expect(find.text('Come Together'), findsOneWidget);
      expect(find.text('The Beatles'), findsOneWidget);
    });

    testWidgets('calls onCollapse on single artist tap', (tester) async {
      bool collapsed = false;
      final track = createTrack([artist1]);
      await tester.pumpWidget(
        buildTestableWidget(track, onCollapse: () => collapsed = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('The Beatles'));
      await tester.pumpAndSettle();

      expect(collapsed, isTrue);
    });
  });
}
