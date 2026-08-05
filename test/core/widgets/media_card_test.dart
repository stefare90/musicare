import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyawun_metadata_sdk/metadata/models/album.dart';
import 'package:gyawun_metadata_sdk/metadata/models/artist.dart';
import 'package:gyawun_metadata_sdk/metadata/models/playlist.dart';
import 'package:gyawun_metadata_sdk/metadata/models/user.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/widgets/media/media_card.dart';

void main() {
  Widget buildTestableWidget({required MediaCard child}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('MediaCard Widget Tests', () {
    testWidgets('renders Album with title and type • artist subtitle', (
      tester,
    ) async {
      final album = Album(
        id: '123',
        name: 'Help!',
        artists: [Artist(id: '456', name: 'The Beatles', externalUri: '')],
        releaseDate: '1965',
        externalUri: '',
        totalTracks: 14,
        albumType: AlbumType.album,
      );

      await tester.pumpWidget(
        buildTestableWidget(child: MediaCard(item: album)),
      );

      expect(find.text('Help!'), findsOneWidget);
      expect(find.text('Album • The Beatles'), findsOneWidget);
    });

    testWidgets('renders Playlist with title and Playlist • owner subtitle', (
      tester,
    ) async {
      final playlist = Playlist(
        id: 'pl1',
        name: 'Chill Vibes',
        description: 'Relaxing music',
        externalUri: '',
        owner: User(id: 'u1', name: 'Dan', externalUri: ''),
      );

      await tester.pumpWidget(
        buildTestableWidget(child: MediaCard(item: playlist)),
      );

      expect(find.text('Chill Vibes'), findsOneWidget);
      expect(find.text('Playlist • Dan'), findsOneWidget);
    });
  });
}
