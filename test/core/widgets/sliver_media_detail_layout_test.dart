import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyawun_metadata_sdk/metadata/models/album.dart';
import 'package:gyawun_metadata_sdk/metadata/models/artist.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/models/media_item_metadata.dart';
import 'package:music_are/core/models/media_type.dart';
import 'package:music_are/core/widgets/media/sliver_media_scaffold.dart';
import 'package:music_are/core/widgets/media/sliver_track_list.dart';

void main() {
  final testAlbum = Album(
    id: 'al1',
    name: 'Abbey Road',
    artists: [Artist(id: 'a1', name: 'The Beatles', externalUri: '')],
    releaseDate: '1969',
    externalUri: '',
    totalTracks: 17,
    albumType: AlbumType.album,
  );

  final testTrack = Track(
    id: 't1',
    name: 'Come Together',
    externalUri: '',
    artists: testAlbum.artists,
    album: testAlbum,
    durationMs: 259000,
  );

  Widget buildTestableWidget({required Widget child}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }

  group('SliverMediaScaffold Widget Tests', () {
    testWidgets('renders header, track list and handles save callback', (
      tester,
    ) async {
      bool saveTapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          child: SliverMediaScaffold(
            metadata: MediaItemMetadata.from(testAlbum),
            onSaveTap: () => saveTapped = true,
            slivers: [
              SliverTrackList(tracks: [testTrack], listType: MediaType.album),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Abbey Road'), findsNWidgets(2)); // Header + AppBar
      expect(
        find.text('The Beatles'),
        findsNWidgets(2),
      ); // Subtitle Header + Subtitle Track
      expect(find.text('Come Together'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      await tester.pumpAndSettle();

      expect(saveTapped, isTrue);
    });

    testWidgets('renders ErrorCard when error is provided', (tester) async {
      bool retryTapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          child: SliverMediaScaffold(
            metadata: MediaItemMetadata.from(testAlbum),
            error: Exception('Network error'),
            onRetry: () => retryTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('An unexpected error occurred: Network error'),
        findsOneWidget,
      );
      expect(find.widgetWithText(ElevatedButton, 'Retry'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Retry'));
      await tester.pumpAndSettle();

      expect(retryTapped, isTrue);
    });

    testWidgets('renders skeleton loading list when isLoading is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: SliverMediaScaffold(
            metadata: MediaItemMetadata.from(testAlbum),
            isLoading: true,
          ),
        ),
      );

      expect(find.byType(CustomScrollView), findsOneWidget);
    });
  });
}
