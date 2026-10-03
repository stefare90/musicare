import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/models/media_type.dart';
import 'package:music_are/core/widgets/media/sliver_track_list.dart';
import 'package:music_are/core/widgets/skeletons/skeleton_track_list.dart';

class _DismissHarness extends StatefulWidget {
  final Track track;
  final Future<bool> Function(Track track)? confirmTrackDismiss;
  final void Function(Track track)? onTrackDismissed;

  const _DismissHarness({
    required this.track,
    this.confirmTrackDismiss,
    this.onTrackDismissed,
  });

  @override
  State<_DismissHarness> createState() => _DismissHarnessState();
}

class _DismissHarnessState extends State<_DismissHarness> {
  late final List<Track> _tracks = [widget.track];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverTrackList(
            tracks: _tracks,
            listType: MediaType.playlist,
            confirmTrackDismiss: widget.confirmTrackDismiss,
            onTrackDismissed: (track) {
              widget.onTrackDismissed?.call(track);
              setState(() => _tracks.removeWhere((t) => t.id == track.id));
            },
          ),
        ],
      ),
    );
  }
}

void main() {
  Widget buildTestableWidget({required SliverTrackList child}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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
          child: SliverTrackList(
            tracks: [testTrack1, testTrack2],
            listType: MediaType.album,
          ),
        ),
      );

      expect(find.text('Come Together'), findsOneWidget);
      expect(find.text('Something'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets(
      'renders SkeletonTrackList indicator and calls onLoadMore when hasMore is true',
      (tester) async {
        bool loadMoreCalled = false;

        await tester.pumpWidget(
          buildTestableWidget(
            child: SliverTrackList(
              tracks: [testTrack1],
              hasMore: true,
              onLoadMore: () => loadMoreCalled = true,
              listType: MediaType.playlist,
            ),
          ),
        );

        expect(find.byType(SkeletonTrackList), findsOneWidget);
        expect(loadMoreCalled, isTrue);
      },
    );

    testWidgets('triggers onTrackTap when a track is tapped', (tester) async {
      Track? tappedTrack;

      await tester.pumpWidget(
        buildTestableWidget(
          child: SliverTrackList(
            tracks: [testTrack1],
            listType: MediaType.album,
            onTrackTap: (track) => tappedTrack = track,
          ),
        ),
      );

      await tester.tap(find.text('Come Together'));
      await tester.pumpAndSettle();

      expect(tappedTrack, equals(testTrack1));
    });

    testWidgets('swipe confirms and then dismisses the track', (tester) async {
      var confirmCalls = 0;
      Track? dismissed;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _DismissHarness(
            track: testTrack1,
            confirmTrackDismiss: (_) async {
              confirmCalls++;
              return true;
            },
            onTrackDismissed: (track) => dismissed = track,
          ),
        ),
      );

      await tester.drag(find.text('Come Together'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(confirmCalls, 1);
      expect(dismissed, equals(testTrack1));
      expect(find.text('Come Together'), findsNothing);
    });

    testWidgets('cancelling the confirmation keeps the track', (tester) async {
      var dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _DismissHarness(
            track: testTrack1,
            confirmTrackDismiss: (_) async => false,
            onTrackDismissed: (_) => dismissed = true,
          ),
        ),
      );

      await tester.drag(find.text('Come Together'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(dismissed, isFalse);
      expect(find.text('Come Together'), findsOneWidget);
    });

    testWidgets('without dismissal handlers the row is not dismissible', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: SliverTrackList(
            tracks: [testTrack1],
            listType: MediaType.playlist,
          ),
        ),
      );

      expect(find.byType(Dismissible), findsNothing);

      await tester.drag(find.text('Come Together'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Come Together'), findsOneWidget);
    });
  });
}
