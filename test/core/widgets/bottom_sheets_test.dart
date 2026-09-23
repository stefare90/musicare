import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/widgets/bottom_sheets/bottom_sheets.dart';

void main() {
  Widget buildTestableWidget({required Widget body}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: body),
    );
  }

  group('BottomSheets Widget Tests', () {
    final testPlaylist = Playlist(
      id: 'pl1',
      name: 'Chill Vibes',
      description: '',
      externalUri: '',
      owner: User(id: 'u1', name: 'User', externalUri: ''),
    );

    final testTrack = Track(
      id: 't1',
      name: 'Song 1',
      externalUri: '',
      artists: [Artist(id: 'a1', name: 'Artist 1', externalUri: '')],
      album: Album(
        id: 'al1',
        name: 'Album 1',
        artists: [],
        releaseDate: '',
        externalUri: '',
        totalTracks: 1,
        albumType: AlbumType.album,
      ),
      durationMs: 120000,
    );

    testWidgets(
      'PlaylistOptionsBottomSheet opens modal and triggers callback',
      (tester) async {
        bool saveTapped = false;

        await tester.pumpWidget(
          buildTestableWidget(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  PlaylistOptionsBottomSheet.show(
                    context,
                    testPlaylist,
                    onToggleSave: () => saveTapped = true,
                  );
                },
                child: const Text('Show Sheet'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Sheet'));
        await tester.pumpAndSettle();

        expect(find.text('Chill Vibes'), findsOneWidget);
        expect(find.text('Save Playlist'), findsOneWidget);

        await tester.tap(find.text('Save Playlist'));
        await tester.pumpAndSettle();

        expect(saveTapped, isTrue);
      },
    );

    testWidgets('TrackOptionsBottomSheet renders queue and favorite options', (
      tester,
    ) async {
      bool queueTapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                TrackOptionsBottomSheet.show(
                  context,
                  testTrack,
                  onAddToQueue: () => queueTapped = true,
                );
              },
              child: const Text('Show Track Options'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Track Options'));
      await tester.pumpAndSettle();

      expect(find.text('Song 1'), findsOneWidget);
      expect(find.text('Add to Queue'), findsOneWidget);

      await tester.tap(find.text('Add to Queue'));
      await tester.pumpAndSettle();

      expect(queueTapped, isTrue);
    });
    testWidgets('AlbumOptionsBottomSheet renders save and share options', (
      tester,
    ) async {
      bool saveTapped = false;
      bool shareTapped = false;

      final testAlbum = Album(
        id: 'al1',
        name: 'Abbey Road',
        artists: [Artist(id: 'a1', name: 'The Beatles', externalUri: '')],
        releaseDate: '1969',
        externalUri: '',
        totalTracks: 17,
        albumType: AlbumType.album,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                AlbumOptionsBottomSheet.show(
                  context,
                  testAlbum,
                  onToggleSave: () => saveTapped = true,
                  onShare: () => shareTapped = true,
                );
              },
              child: const Text('Show Album Options'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Album Options'));
      await tester.pumpAndSettle();

      expect(find.text('Abbey Road'), findsOneWidget);
      expect(find.text('Save Album'), findsOneWidget);
      expect(find.text('Share Album'), findsOneWidget);
      expect(find.text('Go to Artist'), findsOneWidget);

      await tester.tap(find.text('Save Album'));
      await tester.pumpAndSettle();
      expect(saveTapped, isTrue);
    });
  });
}
