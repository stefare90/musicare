import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyawun_metadata_sdk/metadata/models/album.dart';
import 'package:gyawun_metadata_sdk/metadata/models/artist.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:music_are/core/theme/app_theme.dart';
import 'package:music_are/core/widgets/media_cover_image.dart';
import 'package:music_are/core/widgets/track_list_tile.dart';

void main() {
  Widget buildTestableWidget({required TrackListTile child}) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('TrackListTile Widget Tests', () {
    final testTrack = Track(
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
        totalTracks: 1,
        albumType: AlbumType.album,
      ),
      durationMs: 259000, // 4:19
    );

    testWidgets('renders track title, artist, index and formatted duration', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(child: TrackListTile(track: testTrack, index: 1)),
      );

      expect(find.text('Come Together'), findsOneWidget);
      expect(find.text('The Beatles'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('4:19'), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('renders MediaCoverImage when index is null', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: TrackListTile(track: testTrack, index: null),
        ),
      );

      expect(find.byType(MediaCoverImage), findsOneWidget);
    });

    testWidgets('applies playing styles when isPlaying is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: TrackListTile(track: testTrack, index: 1, isPlaying: true),
        ),
      );

      expect(find.text('Come Together'), findsOneWidget);
      final Text titleWidget = tester.widget<Text>(find.text('Come Together'));
      expect(
        titleWidget.style?.color,
        equals(AppTheme.darkTheme.colorScheme.primary),
      );
      expect(titleWidget.style?.fontWeight, equals(FontWeight.bold));
    });

    testWidgets('triggers onTap and onOptionsTap callbacks', (tester) async {
      bool tapped = false;
      bool optionsTapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          child: TrackListTile(
            track: testTrack,
            onTap: () => tapped = true,
            onOptionsTap: () => optionsTapped = true,
          ),
        ),
      );

      await tester.tap(find.text('Come Together'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      expect(optionsTapped, isTrue);
    });
  });
}
