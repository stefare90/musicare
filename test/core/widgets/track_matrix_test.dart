import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyawun_metadata_sdk/metadata/models/album.dart';
import 'package:gyawun_metadata_sdk/metadata/models/artist.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/widgets/media/track_matrix.dart';
import 'package:music_are/core/widgets/skeletons/skeleton_track_matrix.dart';

void main() {
  final testArtist = Artist(id: 'a1', name: 'The Beatles', externalUri: '');
  final testAlbum = Album(
    id: 'al1',
    name: 'Help!',
    artists: [testArtist],
    releaseDate: '1965',
    externalUri: '',
    totalTracks: 14,
    albumType: AlbumType.album,
  );

  Track createTrack(String id, String name) {
    return Track(
      id: id,
      name: name,
      externalUri: '',
      artists: [testArtist],
      album: testAlbum,
      durationMs: 140000,
    );
  }

  Widget buildTestableWidget({required Widget child}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  group('TrackMatrix Widget Tests', () {
    testWidgets('renders title, description and track tiles', (tester) async {
      final tracks = [
        createTrack('t1', 'Track 1'),
        createTrack('t2', 'Track 2'),
        createTrack('t3', 'Track 3'),
        createTrack('t4', 'Track 4'),
      ];

      await tester.pumpWidget(
        buildTestableWidget(
          child: TrackMatrix(
            title: 'Popular Tracks',
            description: 'Top songs by artist',
            tracks: tracks,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Popular Tracks'), findsOneWidget);
      expect(find.text('Top songs by artist'), findsOneWidget);
      expect(find.text('Track 1'), findsOneWidget);
      expect(find.text('Track 2'), findsOneWidget);
      expect(find.text('Track 3'), findsOneWidget);
      expect(find.text('Track 4'), findsOneWidget);
    });

    testWidgets(
      'renders SkeletonTrackMatrix when isLoading is true and tracks empty',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            child: const TrackMatrix(
              title: 'Popular Tracks',
              tracks: [],
              isLoading: true,
            ),
          ),
        );

        expect(find.byType(SkeletonTrackMatrix), findsOneWidget);
      },
    );

    testWidgets('triggers onTrackTap when a track is tapped', (tester) async {
      Track? tappedTrack;
      final tracks = [createTrack('t1', 'Track 1')];

      await tester.pumpWidget(
        buildTestableWidget(
          child: TrackMatrix(
            title: 'Popular Tracks',
            tracks: tracks,
            onTrackTap: (track) => tappedTrack = track,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Track 1'));
      await tester.pumpAndSettle();

      expect(tappedTrack?.name, equals('Track 1'));
    });
  });
}
