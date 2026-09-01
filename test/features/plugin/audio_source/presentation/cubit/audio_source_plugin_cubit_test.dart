import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/services/preferences_service.dart';
import 'package:music_are/features/plugin/audio_source/data/services/audio_source_plugin_engine.dart';
import 'package:music_are/features/plugin/audio_source/presentation/cubit/audio_source_plugin_cubit.dart';
import 'package:music_are/features/plugin/audio_source/presentation/cubit/audio_source_plugin_state.dart';
import 'package:music_are/features/plugin/discovery/data/services/plugin_discovery_service.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';

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

      // Stub default per la terminazione del demone
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
  });
}
