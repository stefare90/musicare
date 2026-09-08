import 'package:flutter_test/flutter_test.dart';
import 'package:gyawun_metadata_sdk/metadata/models/album.dart';
import 'package:gyawun_metadata_sdk/metadata/models/artist.dart';
import 'package:gyawun_metadata_sdk/metadata/models/image.dart' as sdk;
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/features/player/data/services/audio_stream_resolver.dart';
import 'package:music_are/features/plugin/audio_source/data/services/audio_source_plugin_engine.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:musicare_dart_host_sdk/musicare_dart_host_sdk.dart';

class MockAudioSourcePluginEngine extends Mock
    implements AudioSourcePluginEngine {}

void main() {
  group('AudioStreamResolver Tests', () {
    late MockAudioSourcePluginEngine mockEngine;
    late AudioStreamResolver resolver;

    final testTrack = Track(
      id: 't1',
      name: 'Come Together',
      externalUri: '',
      artists: [Artist(id: 'a1', name: 'The Beatles', externalUri: '')],
      album: Album(
        id: 'al1',
        name: 'Abbey Road',
        artists: [],
        images: [sdk.Image(url: 'https://example.com/cover.jpg')],
        releaseDate: '1969',
        externalUri: '',
        totalTracks: 17,
        albumType: AlbumType.album,
      ),
      durationMs: 259000,
    );

    const candidate1 = AudioStreamResponse(
      url: 'https://cdn1.example.com/stream1.m4a',
      quality: AudioQuality.high,
      bitrate: 160000,
    );

    setUp(() {
      mockEngine = MockAudioSourcePluginEngine();
      resolver = AudioStreamResolver(mockEngine);
    });

    test(
      'resolveTrack delegates to engine and propagates PluginNotLoadedException',
      () async {
        when(
          () => mockEngine.resolveStream(testTrack, quality: AudioQuality.high),
        ).thenThrow(PluginNotLoadedException());

        expect(
          () async => await resolver.resolveTrack(testTrack),
          throwsA(isA<PluginNotLoadedException>()),
        );
      },
    );

    test(
      'resolveTrack throws StreamResolutionException if candidates list is empty',
      () async {
        when(
          () => mockEngine.resolveStream(testTrack, quality: AudioQuality.high),
        ).thenAnswer((_) async => []);

        expect(
          () async => await resolver.resolveTrack(testTrack),
          throwsA(isA<StreamResolutionException>()),
        );
      },
    );

    test(
      'resolveTrack returns ResolvedPlaybackTrack with ordered candidates',
      () async {
        when(
          () => mockEngine.resolveStream(testTrack, quality: AudioQuality.high),
        ).thenAnswer((_) async => [candidate1]);

        final resolved = await resolver.resolveTrack(testTrack);

        expect(resolved.track.name, equals('Come Together'));
        expect(resolved.candidates.length, equals(1));
        expect(resolved.currentStream.url, equals(candidate1.url));
      },
    );
  });
}
