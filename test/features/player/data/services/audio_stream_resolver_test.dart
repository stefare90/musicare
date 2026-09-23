import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:musicare_metadata_host_sdk/metadata/models/image.dart' as sdk;
import 'package:mocktail/mocktail.dart';
import 'package:music_are/features/player/data/services/audio_stream_resolver.dart';
import 'package:music_are/features/plugin/audio_source/data/services/audio_source_plugin_engine.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:musicare_audio_host_sdk/musicare_audio_host_sdk.dart';

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

    const candidate1 = CandidateTrack(
      id: 'c1',
      title: 'Come Together (Official)',
    );

    const stream1 = AudioStreamResponse(
      url: 'https://cdn1.example.com/stream1.m4a',
      quality: AudioQuality.high,
      bitrate: 160000,
    );

    setUp(() {
      mockEngine = MockAudioSourcePluginEngine();
      resolver = AudioStreamResolver(mockEngine);
    });

    void stubCandidates(List<CandidateTrack> candidates) {
      when(
        () => mockEngine.searchCandidates(
          title: any(named: 'title'),
          artists: any(named: 'artists'),
          durationMs: any(named: 'durationMs'),
        ),
      ).thenAnswer((_) async => candidates);
    }

    test(
      'resolveTrack propagates PluginNotLoadedException from the engine',
      () async {
        when(
          () => mockEngine.searchCandidates(
            title: any(named: 'title'),
            artists: any(named: 'artists'),
            durationMs: any(named: 'durationMs'),
          ),
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
        stubCandidates(const []);

        expect(
          () async => await resolver.resolveTrack(testTrack),
          throwsA(isA<StreamResolutionException>()),
        );
      },
    );

    test(
      'resolveTrack marks the first candidate active and leaves the stream to the player',
      () async {
        stubCandidates(const [candidate1]);

        final resolved = await resolver.resolveTrack(testTrack);

        expect(resolved.candidates.length, equals(1));
        expect(resolved.activeCandidateId, equals('c1'));
        expect(resolved.activeStream, isNull);
        expect(resolved.needsStreamResolution, isTrue);
        expect(resolved.isFallback, isFalse);
      },
    );

    test('resolveTrack maps the track onto the candidate search parameters', () async {
      stubCandidates(const [candidate1]);

      await resolver.resolveTrack(testTrack);

      final captured = verify(
        () => mockEngine.searchCandidates(
          title: captureAny(named: 'title'),
          artists: captureAny(named: 'artists'),
          durationMs: captureAny(named: 'durationMs'),
        ),
      ).captured;

      expect(captured[0], equals('Come Together'));
      expect(captured[1], equals(['The Beatles']));
      expect(captured[2], equals(259000));
    });

    test('resolveCandidateStream delegates directly to engine', () async {
      when(
        () => mockEngine.resolveStream('c1', quality: AudioQuality.high),
      ).thenAnswer((_) async => stream1);

      final stream = await resolver.resolveCandidateStream('c1');

      expect(stream.url, equals(stream1.url));
      verify(() => mockEngine.resolveStream('c1', quality: AudioQuality.high)).called(1);
    });
  });
}
