import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/features/library/presentation/utils/share_actions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Artist artist({String id = 'a1', String name = 'The Beatles'}) =>
      Artist(id: id, name: name, externalUri: '');

  Album album({String uri = '', List<Artist>? artists}) => Album(
    id: 'al1',
    name: 'Abbey Road',
    artists: artists ?? [artist()],
    releaseDate: '1969',
    externalUri: uri,
    totalTracks: 17,
    albumType: AlbumType.album,
  );

  group('ShareActions text', () {
    test('album with link appends the external uri', () {
      expect(
        ShareActions.albumText(
          album(uri: 'https://musicbrainz.org/release-group/mbid'),
        ),
        'Abbey Road - The Beatles\nhttps://musicbrainz.org/release-group/mbid',
      );
    });

    test('album without link shares title and artist only', () {
      expect(ShareActions.albumText(album()), 'Abbey Road - The Beatles');
    });

    test('album without artists shares the title only', () {
      expect(
        ShareActions.albumText(album(artists: [])),
        'Abbey Road',
      );
    });

    test('artist with link appends the external uri', () {
      final a = Artist(
        id: 'a1',
        name: 'The Beatles',
        externalUri: 'https://musicbrainz.org/artist/mbid',
      );
      expect(
        ShareActions.artistText(a),
        'The Beatles\nhttps://musicbrainz.org/artist/mbid',
      );
    });

    test('artist without link shares the name only', () {
      expect(ShareActions.artistText(artist()), 'The Beatles');
    });

    test('playlist with link appends the external uri', () {
      final playlist = Playlist(
        id: 'pl1',
        name: 'Chill Vibes',
        description: '',
        externalUri: 'https://listenbrainz.org/playlist/mbid',
        owner: User(id: 'u1', name: 'me', externalUri: ''),
      );
      expect(
        ShareActions.playlistText(playlist),
        'Chill Vibes\nhttps://listenbrainz.org/playlist/mbid',
      );
    });

    test('playlist without link shares the name only', () {
      final playlist = Playlist(
        id: 'pl1',
        name: 'Chill Vibes',
        description: '',
        externalUri: '',
        owner: User(id: 'u1', name: 'me', externalUri: ''),
      );
      expect(ShareActions.playlistText(playlist), 'Chill Vibes');
    });

    test('track joins several artists and appends the link', () {
      final track = Track(
        id: 't1',
        name: 'Song 1',
        externalUri: 'https://musicbrainz.org/recording/mbid',
        artists: [
          artist(),
          artist(id: 'a2', name: 'Various'),
        ],
        album: album(),
        durationMs: 120000,
      );
      expect(
        ShareActions.trackText(track),
        'Song 1 - The Beatles, Various\nhttps://musicbrainz.org/recording/mbid',
      );
    });

    test('track without link shares title and artist only', () {
      final track = Track(
        id: 't1',
        name: 'Song 1',
        externalUri: '',
        artists: [artist()],
        album: album(),
        durationMs: 120000,
      );
      expect(ShareActions.trackText(track), 'Song 1 - The Beatles');
    });
  });

  group('ShareActions platform channel', () {
    const channel = MethodChannel('dev.fluttercommunity.plus/share');
    final calls = <MethodCall>[];

    setUp(() {
      calls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return 'dev.fluttercommunity.plus/share/unavailable';
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('shareAlbum sends the composed text', () async {
      await ShareActions.shareAlbum(
        album(uri: 'https://musicbrainz.org/release-group/mbid'),
      );
      expect(calls, hasLength(1));
      expect(calls.single.method, 'share');
      expect(
        calls.single.arguments['text'],
        'Abbey Road - The Beatles\nhttps://musicbrainz.org/release-group/mbid',
      );
    });

    test('shareTrack without link sends text only, never empty', () async {
      final track = Track(
        id: 't1',
        name: 'Song 1',
        externalUri: '',
        artists: [artist()],
        album: album(),
        durationMs: 120000,
      );
      await ShareActions.shareTrack(track);
      expect(calls, hasLength(1));
      expect(calls.single.arguments['text'], 'Song 1 - The Beatles');
    });

    test('shareArtist and sharePlaylist send their text', () async {
      await ShareActions.shareArtist(artist());
      await ShareActions.sharePlaylist(
        Playlist(
          id: 'pl1',
          name: 'Chill Vibes',
          description: '',
          externalUri: '',
          owner: User(id: 'u1', name: 'me', externalUri: ''),
        ),
      );
      expect(calls, hasLength(2));
      expect(calls[0].arguments['text'], 'The Beatles');
      expect(calls[1].arguments['text'], 'Chill Vibes');
    });
  });
}
