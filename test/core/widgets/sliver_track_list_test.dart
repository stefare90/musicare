import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyawun_metadata_sdk/metadata/models/album.dart';
import 'package:gyawun_metadata_sdk/metadata/models/artist.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:music_are/core/widgets/media/sliver_track_list.dart';

void main() {
  Widget buildTestableWidget({required SliverTrackList child}) {
    return MaterialApp(
      home: Scaffold(body: CustomScrollView(slivers: [child])),
    );
  }

  group('SliverTrackList Widget Tests', () {
    final testTrack1 = Track(
      id: 't1',
      name: 'Come Together',
      externalUri: '',
      artists: [Artist(id: 'a1', name: 'The Beatles', externalUri: '')],
      album: Album(
        id: 'al1',
        name: 'Abbey Road',
        artists: [],
        releaseDate: '1969',
        externalUri: '',
        totalTracks: 2,
        albumType: AlbumType.album,
      ),
      durationMs: 259000,
    );

    final testTrack2 = Track(
      id: 't2',
      name: 'Something',
      externalUri: '',
      artists: [Artist(id: 'a1', name: 'The Beatles', externalUri: '')],
      album: Album(
        id: 'al1',
        name: 'Abbey Road',
        artists: [],
        releaseDate: '1969',
        externalUri: '',
        totalTracks: 2,
        albumType: AlbumType.album,
      ),
      durationMs: 183000,
    );

    testWidgets('renders list of tracks using TrackListTile', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: SliverTrackList(tracks: [testTrack1, testTrack2]),
        ),
      );

      expect(find.text('Come Together'), findsOneWidget);
      expect(find.text('Something'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets(
      'renders progress indicator and calls onLoadMore when hasMore is true',
      (tester) async {
        bool loadMoreCalled = false;

        await tester.pumpWidget(
          buildTestableWidget(
            child: SliverTrackList(
              tracks: [testTrack1],
              hasMore: true,
              onLoadMore: () => loadMoreCalled = true,
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(loadMoreCalled, isTrue);
      },
    );

    testWidgets('triggers onTrackTap when a track is tapped', (tester) async {
      Track? tappedTrack;

      await tester.pumpWidget(
        buildTestableWidget(
          child: SliverTrackList(
            tracks: [testTrack1],
            onTrackTap: (track) => tappedTrack = track,
          ),
        ),
      );

      await tester.tap(find.text('Come Together'));
      await tester.pumpAndSettle();

      expect(tappedTrack, equals(testTrack1));
    });
  });
}
