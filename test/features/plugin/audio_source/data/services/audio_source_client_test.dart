import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyawun_metadata_sdk/metadata/models/album.dart';
import 'package:gyawun_metadata_sdk/metadata/models/artist.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:music_are/features/plugin/audio_source/data/models/audio_quality.dart';
import 'package:music_are/features/plugin/audio_source/data/services/audio_source_client.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri.parse('http://127.0.0.1:8000'));
  });

  group('AudioSourceClient Unit Tests', () {
    late MockHttpClient mockHttpClient;
    late AudioSourceClient client;

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
      durationMs: 259000,
    );

    setUp(() {
      mockHttpClient = MockHttpClient();
      client = AudioSourceClient(httpClient: mockHttpClient, port: 8765);
    });

    test('ping returns true on 200 OK and false on failure', () async {
      when(
        () => mockHttpClient.get(Uri.parse('http://127.0.0.1:8765/ping')),
      ).thenAnswer((_) async => http.Response('{"status": "ready"}', 200));

      final resultSuccess = await client.ping();
      expect(resultSuccess, isTrue);

      when(
        () => mockHttpClient.get(Uri.parse('http://127.0.0.1:8765/ping')),
      ).thenThrow(Exception('Connection refused'));

      final resultFailure = await client.ping();
      expect(resultFailure, isFalse);
    });

    test(
      'getStream posts track metadata and returns parsed candidate streams',
      () async {
        final responseBody = jsonEncode([
          {
            'url': 'https://stream1.googlevideo.com',
            'quality': 'high',
            'bitrate': 160000,
            'codec': 'm4a',
          },
          {
            'url': 'https://stream2.googlevideo.com',
            'quality': 'high',
            'bitrate': 128000,
            'codec': 'opus',
          },
        ]);

        when(
          () => mockHttpClient.post(
            Uri.parse('http://127.0.0.1:8765/get_stream'),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => http.Response(responseBody, 200));

        final streams = await client.getStream(
          track: testTrack,
          quality: AudioQuality.high,
        );

        expect(streams.length, equals(2));
        expect(streams[0].url, equals('https://stream1.googlevideo.com'));
        expect(streams[0].bitrate, equals(160000));
        expect(streams[1].url, equals('https://stream2.googlevideo.com'));
      },
    );
  });
}
