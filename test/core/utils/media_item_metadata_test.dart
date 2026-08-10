import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyawun_metadata_sdk/metadata/models/album.dart';
import 'package:gyawun_metadata_sdk/metadata/models/artist.dart';
import 'package:gyawun_metadata_sdk/metadata/models/image.dart' as sdk;
import 'package:gyawun_metadata_sdk/metadata/models/playlist.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:gyawun_metadata_sdk/metadata/models/user.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/models/media_item_metadata.dart';
import 'package:music_are/core/models/media_type.dart';

void main() {
  group('MediaItemMetadata Pure Dart Parsing Tests', () {
    test('parses Album correctly without BuildContext', () {
      final album = Album(
        id: '1',
        name: 'Abbey Road',
        artists: [Artist(id: 'a1', name: 'The Beatles', externalUri: '')],
        images: [sdk.Image(url: 'https://example.com/cover.jpg')],
        releaseDate: '1969',
        externalUri: '',
        totalTracks: 17,
        albumType: AlbumType.album,
      );

      final meta = MediaItemMetadata.from(album);

      expect(meta.title, equals('Abbey Road'));
      expect(meta.mediaType, equals(MediaType.album));
      expect(meta.subtitle, equals('The Beatles'));
    });

    test('parses Single album correctly', () {
      final album = Album(
        id: '2',
        name: 'Bohemian Rhapsody',
        artists: [Artist(id: 'a2', name: 'Queen', externalUri: '')],
        releaseDate: '1975',
        externalUri: '',
        totalTracks: 1,
        albumType: AlbumType.single,
      );

      final meta = MediaItemMetadata.from(album);

      expect(meta.mediaType, equals(MediaType.single));
    });

    test('parses Playlist correctly without BuildContext', () {
      final playlist = Playlist(
        id: 'p1',
        name: 'My Playlist',
        description: 'Desc',
        externalUri: '',
        owner: User(id: 'u1', name: 'Dan', externalUri: ''),
      );

      final meta = MediaItemMetadata.from(playlist);

      expect(meta.title, equals('My Playlist'));
      expect(meta.mediaType, equals(MediaType.playlist));
      expect(meta.subtitle, equals('Dan'));
    });

    test('parses Track correctly without BuildContext', () {
      final track = Track(
        id: 't1',
        name: 'Come Together',
        externalUri: '',
        artists: [Artist(id: 'a1', name: 'The Beatles', externalUri: '')],
        album: Album(
          id: '1',
          name: 'Abbey Road',
          artists: [],
          releaseDate: '',
          externalUri: '',
          totalTracks: 1,
          albumType: AlbumType.album,
        ),
        durationMs: 200000,
      );

      final meta = MediaItemMetadata.from(track);

      expect(meta.title, equals('Come Together'));
      expect(meta.mediaType, equals(MediaType.track));
      expect(meta.subtitle, equals('The Beatles'));
    });

    test('parses Artist correctly without BuildContext', () {
      final artist = Artist(
        id: 'a1',
        name: 'The Beatles',
        externalUri: '',
        genres: ['Rock', 'Pop'],
      );

      final meta = MediaItemMetadata.from(artist);

      expect(meta.title, equals('The Beatles'));
      expect(meta.mediaType, equals(MediaType.artist));
      expect(meta.subtitle, equals('Rock'));
    });

    test('returns MediaType.unknown for unrecognized objects', () {
      final meta = MediaItemMetadata.from('unknown_object');

      expect(meta.title, equals(''));
      expect(meta.mediaType, equals(MediaType.unknown));
      expect(meta.subtitle, isEmpty);
    });
  });

  group('MediaItemMetadata Localized Subtitle Tests', () {
    Widget buildTestableWidget(void Function(BuildContext context) callback) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            callback(context);
            return const SizedBox.shrink();
          },
        ),
      );
    }

    testWidgets('formats subtitle with localized media type and artist', (
      tester,
    ) async {
      late String subtitle;
      final album = Album(
        id: '1',
        name: 'Abbey Road',
        artists: [Artist(id: 'a1', name: 'The Beatles', externalUri: '')],
        releaseDate: '1969',
        externalUri: '',
        totalTracks: 17,
        albumType: AlbumType.album,
      );

      await tester.pumpWidget(
        buildTestableWidget((context) {
          final meta = MediaItemMetadata.from(album);
          subtitle = meta.getFormattedSubtitle(context);
        }),
      );

      expect(subtitle, equals('Album • The Beatles'));
    });

    testWidgets('formats subtitle for Playlist correctly', (tester) async {
      late String subtitle;
      final playlist = Playlist(
        id: 'p1',
        name: 'Chill',
        description: '',
        externalUri: '',
        owner: User(id: 'u1', name: 'Dan', externalUri: ''),
      );

      await tester.pumpWidget(
        buildTestableWidget((context) {
          final meta = MediaItemMetadata.from(playlist);
          subtitle = meta.getFormattedSubtitle(context);
        }),
      );

      expect(subtitle, equals('Playlist • Dan'));
    });
  });
}
