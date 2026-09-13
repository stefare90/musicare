import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gyawun_metadata_sdk/metadata/models/album.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/services/preferences_service.dart';
import 'package:music_are/features/plugin/audio_source/data/services/audio_source_plugin_engine.dart';
import 'package:music_are/features/plugin/audio_source/presentation/cubit/audio_source_plugin_cubit.dart';
import 'package:music_are/features/plugin/audio_source/presentation/cubit/audio_source_plugin_state.dart';
import 'package:music_are/features/plugin/discovery/data/services/plugin_discovery_service.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:musicare_dart_host_sdk/musicare_dart_host_sdk.dart';

class MockAudioSourcePluginEngine extends Mock
    implements AudioSourcePluginEngine {}

class MockPreferencesService extends Mock implements PreferencesService {}

class MockPluginDiscoveryService extends Mock
    implements PluginDiscoveryService {}

void main() {
  group('AudioSourcePluginCubit Unit Tests', () {
    late MockAudioSourcePluginEngine mockEngine;
    late MockPreferencesService mockPreferences;
    late MockPluginDiscoveryService mockDiscovery;
    late AudioSourcePluginCubit cubit;

    final testManifest = PluginManifest(
      id: 'org.musicare.audiosource.youtube',
      packageId: 'musicare_audiosource_youtube_plugin',
      type: 'audioSource',
      name: 'YouTube Audio Source',
      version: '1.0.0',
      pluginSdkVersion: '1.0.0',
      author: 'MusicAre Team',
      description: 'Test YouTube Source',
    );

    setUp(() {
      mockEngine = MockAudioSourcePluginEngine();
      mockPreferences = MockPreferencesService();
      mockDiscovery = MockPluginDiscoveryService();

      when(() => mockEngine.terminate()).thenAnswer((_) async {});

      cubit = AudioSourcePluginCubit(
        mockEngine,
        mockPreferences,
        mockDiscovery,
      );
    });

    tearDown(() async {
      await cubit.close();
    });

    test('initial state is AudioSourcePluginInitialState', () {
      expect(cubit.state, isA<AudioSourcePluginInitialState>());
    });

    test(
      'initialize loads saved audio source from disk when present',
      () async {
        when(
          () => mockPreferences.getActiveAudioSourcePluginId(),
        ).thenReturn('org.musicare.audiosource.youtube');
        when(
          () => mockEngine.isPluginInstalledOnDisk(
            'org.musicare.audiosource.youtube',
          ),
        ).thenAnswer((_) async => true);
        when(
          () => mockEngine.loadFromDisk('org.musicare.audiosource.youtube'),
        ).thenAnswer((_) async {});
        when(() => mockEngine.activeManifest).thenReturn(testManifest);
        when(() => mockEngine.activePort).thenReturn(8765);

        expectLater(
          cubit.stream,
          emitsInOrder([
            isA<AudioSourcePluginLoadingState>(),
            isA<AudioSourcePluginLoadedState>()
                .having(
                  (s) => s.manifest.id,
                  'id',
                  'org.musicare.audiosource.youtube',
                )
                .having((s) => s.port, 'port', 8765),
          ]),
        );

        await cubit.initialize();
      },
    );

    test('unload terminates engine and emits NotConfiguredState', () async {
      when(
        () => mockPreferences.removeActiveAudioSourcePluginId(),
      ).thenAnswer((_) async => true);

      await cubit.unload();

      expect(cubit.state, isA<AudioSourcePluginNotConfiguredState>());
      verify(() => mockEngine.terminate()).called(1);
    });

    test(
      'initialize emits AudioSourcePluginNotConfiguredState when no plugin is saved',
      () async {
        when(
          () => mockPreferences.getActiveAudioSourcePluginId(),
        ).thenReturn(null);

        expectLater(
          cubit.stream,
          emitsInOrder([
            isA<AudioSourcePluginLoadingState>(),
            isA<AudioSourcePluginNotConfiguredState>(),
          ]),
        );

        await cubit.initialize();
      },
    );

    test(
      'initialize emits AudioSourcePluginErrorState when disk load throws',
      () async {
        when(
          () => mockPreferences.getActiveAudioSourcePluginId(),
        ).thenReturn('org.musicare.audiosource.youtube');
        when(
          () => mockEngine.isPluginInstalledOnDisk(
            'org.musicare.audiosource.youtube',
          ),
        ).thenAnswer((_) async => true);
        when(
          () => mockEngine.loadFromDisk('org.musicare.audiosource.youtube'),
        ).thenThrow(Exception('Disk read failed'));

        expectLater(
          cubit.stream,
          emitsInOrder([
            isA<AudioSourcePluginLoadingState>(),
            isA<AudioSourcePluginErrorState>(),
          ]),
        );

        await cubit.initialize();
      },
    );

    test(
      'installDiscoveredPlugin gets zip bytes and loads successfully',
      () async {
        final zipBytes = Uint8List.fromList([1, 2, 3]);
        when(
          () => mockDiscovery.getZipBytesForPlugin(testManifest),
        ).thenReturn(zipBytes);
        when(
          () => mockEngine.loadFromZipBytes(zipBytes),
        ).thenAnswer((_) async {});
        when(() => mockEngine.activeManifest).thenReturn(testManifest);
        when(() => mockEngine.activePort).thenReturn(8765);
        when(
          () => mockPreferences.setActiveAudioSourcePluginId(
            'org.musicare.audiosource.youtube',
          ),
        ).thenAnswer((_) async => true);

        expectLater(
          cubit.stream,
          emitsInOrder([
            isA<AudioSourcePluginLoadingState>(),
            isA<AudioSourcePluginLoadedState>()
                .having(
                  (s) => s.manifest.id,
                  'id',
                  'org.musicare.audiosource.youtube',
                )
                .having((s) => s.port, 'port', 8765),
          ]),
        );

        await cubit.installDiscoveredPlugin(testManifest);
      },
    );

    test('resolveTrack forwards call to engine', () async {
      final track = Track(
        id: 't1',
        name: 'Track',
        externalUri: '',
        artists: [],
        album: Album(
          id: 'al1',
          name: 'Alb',
          artists: [],
          releaseDate: '',
          externalUri: '',
          totalTracks: 1,
          albumType: AlbumType.single,
        ),
        durationMs: 100,
      );

      const playback = ResolvedTrackPlayback(
        stream: AudioStreamResponse(
          url: 'https://cdn.example.com/audio.m4a',
          quality: AudioQuality.high,
        ),
        candidates: [CandidateTrack(id: 'c1', title: 'Track')],
        activeCandidateId: 'c1',
      );

      when(
        () => mockEngine.resolveTrack(track, quality: AudioQuality.high),
      ).thenAnswer((_) async => playback);

      final result = await cubit.resolveTrack(
        track,
        quality: AudioQuality.high,
      );
      expect(result.activeCandidateId, equals('c1'));
      verify(
        () => mockEngine.resolveTrack(track, quality: AudioQuality.high),
      ).called(1);
    });

    test('resolveStream forwards call to engine', () async {
      const stream = AudioStreamResponse(
        url: 'https://cdn.example.com/audio.m4a',
        quality: AudioQuality.high,
      );

      when(
        () => mockEngine.resolveStream('c1', quality: AudioQuality.high),
      ).thenAnswer((_) async => stream);

      final result = await cubit.resolveStream('c1', quality: AudioQuality.high);
      expect(result.url, equals(stream.url));
      verify(
        () => mockEngine.resolveStream('c1', quality: AudioQuality.high),
      ).called(1);
    });
  });
}
