import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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

    testWidgets(
      'TrackOptionsBottomSheet shows remove + add to playlist when saved',
      (tester) async {
        var addToPlaylistTapped = false;

        await tester.pumpWidget(
          buildTestableWidget(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  TrackOptionsBottomSheet.show(
                    context,
                    testTrack,
                    isSaved: true,
                    onAddToPlaylist: () => addToPlaylistTapped = true,
                  );
                },
                child: const Text('Show Options'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Options'));
        await tester.pumpAndSettle();

        expect(find.text('Remove from Favorites'), findsOneWidget);
        expect(find.text('Add to Playlist'), findsOneWidget);

        await tester.tap(find.text('Add to Playlist'));
        await tester.pumpAndSettle();

        expect(addToPlaylistTapped, isTrue);
      },
    );

    testWidgets('Album options show remove when saved', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AlbumOptionsBottomSheet.show(
                context,
                testTrack.album,
                isSaved: true,
              ),
              child: const Text('Show Album'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Show Album'));
      await tester.pumpAndSettle();
      expect(find.text('Remove Album'), findsOneWidget);
    });

    testWidgets('Playlist options show remove when saved', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => PlaylistOptionsBottomSheet.show(
                context,
                testPlaylist,
                isSaved: true,
                onToggleSave: () {},
              ),
              child: const Text('Show Playlist'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Show Playlist'));
      await tester.pumpAndSettle();
      expect(find.text('Remove Playlist'), findsOneWidget);
    });

    testWidgets('Playlist options show delete only when a delete handler is given', (
      tester,
    ) async {
      var deleteTapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => PlaylistOptionsBottomSheet.show(
                context,
                testPlaylist,
                onDelete: () => deleteTapped = true,
              ),
              child: const Text('Show Playlist'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Playlist'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Playlist'), findsOneWidget);
      expect(find.text('Save Playlist'), findsNothing);

      await tester.tap(find.text('Delete Playlist'));
      await tester.pumpAndSettle();

      expect(deleteTapped, isTrue);
    });

    testWidgets(
      'TrackOptionsBottomSheet runs onBeforeNavigate before opening the album',
      (tester) async {
        var beforeNavigate = false;
        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => TrackOptionsBottomSheet.show(
                      context,
                      testTrack,
                      onBeforeNavigate: () => beforeNavigate = true,
                    ),
                    child: const Text('Show Track Options'),
                  ),
                ),
              ),
            ),
            GoRoute(
              path: '/album',
              builder: (context, state) =>
                  const Scaffold(body: Text('Album Page')),
            ),
            GoRoute(
              path: '/artist',
              builder: (context, state) =>
                  const Scaffold(body: Text('Artist Page')),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        );

        await tester.tap(find.text('Show Track Options'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Go to Album'));
        await tester.pumpAndSettle();

        expect(beforeNavigate, isTrue);
        expect(find.text('Album Page'), findsOneWidget);
      },
    );

    testWidgets(
      'TrackOptionsBottomSheet asks which artist when the track has several',
      (tester) async {
        var beforeNavigate = false;
        final multiArtistTrack = Track(
          id: 't2',
          name: 'Song 2',
          externalUri: '',
          artists: [
            Artist(id: 'a1', name: 'Artist One', externalUri: ''),
            Artist(id: 'a2', name: 'Artist Two', externalUri: ''),
          ],
          album: testTrack.album,
          durationMs: 120000,
        );
        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => TrackOptionsBottomSheet.show(
                      context,
                      multiArtistTrack,
                      onBeforeNavigate: () => beforeNavigate = true,
                    ),
                    child: const Text('Show Track Options'),
                  ),
                ),
              ),
            ),
            GoRoute(
              path: '/artist',
              builder: (context, state) =>
                  const Scaffold(body: Text('Artist Page')),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        );

        await tester.tap(find.text('Show Track Options'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Go to Artist'));
        await tester.pumpAndSettle();

        expect(find.text('Select Artist'), findsOneWidget);
        expect(find.text('Artist One'), findsOneWidget);
        expect(find.text('Artist Two'), findsOneWidget);
        expect(beforeNavigate, isFalse);

        await tester.tap(find.text('Artist Two'));
        await tester.pumpAndSettle();

        expect(beforeNavigate, isTrue);
        expect(find.text('Artist Page'), findsOneWidget);
      },
    );
    testWidgets('AlbumOptionsBottomSheet renders save and share options', (
      tester,
    ) async {
      bool saveTapped = false;

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
