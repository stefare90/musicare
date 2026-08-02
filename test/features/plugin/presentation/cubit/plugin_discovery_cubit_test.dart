import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/features/plugin/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/data/services/plugin_discovery_service.dart';
import 'package:music_are/features/plugin/presentation/cubit/plugin_discovery_cubit.dart';
import 'package:music_are/features/plugin/presentation/cubit/plugin_discovery_state.dart';

class MockPluginDiscoveryService extends Mock
    implements PluginDiscoveryService {}

class FakePluginManifest extends Fake implements PluginManifest {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakePluginManifest());
  });

  group('PluginDiscoveryCubit Unit Tests', () {
    late MockPluginDiscoveryService mockDiscoveryService;
    late PluginDiscoveryCubit cubit;

    final testManifest = PluginManifest(
      id: 'org.gyawun.musicbrainz',
      packageId: 'gyawun_metadata_plugin',
      type: 'metadata',
      name: 'MusicBrainz & ListenBrainz',
      version: '1.0.0',
      pluginSdkVersion: '1.0.0',
      author: 'MusicAre Team',
      description: 'Test description',
    );

    setUp(() {
      mockDiscoveryService = MockPluginDiscoveryService();
      cubit = PluginDiscoveryCubit(mockDiscoveryService);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is PluginDiscoveryInitialState', () {
      expect(cubit.state, isA<PluginDiscoveryInitialState>());
    });

    test(
      'fetchCommunityPlugins emits Loading and Loaded states on success',
      () async {
        when(
          () => mockDiscoveryService.fetchCommunityPlugins(),
        ).thenAnswer((_) async => [testManifest]);

        expectLater(
          cubit.stream,
          emitsInOrder([
            isA<PluginDiscoveryLoadingState>(),
            isA<PluginDiscoveryLoadedState>()
                .having((s) => s.plugins.length, 'length', 1)
                .having(
                  (s) => s.plugins.first.id,
                  'id',
                  'org.gyawun.musicbrainz',
                ),
          ]),
        );

        await cubit.fetchCommunityPlugins();
      },
    );

    test(
      'fetchCommunityPlugins emits Loading and Error states on failure',
      () async {
        final exception = Exception('Network error');
        when(
          () => mockDiscoveryService.fetchCommunityPlugins(),
        ).thenThrow(exception);

        expectLater(
          cubit.stream,
          emitsInOrder([
            isA<PluginDiscoveryLoadingState>(),
            isA<PluginDiscoveryErrorState>().having(
              (s) => s.error,
              'error',
              equals(exception),
            ),
          ]),
        );

        await cubit.fetchCommunityPlugins();
      },
    );

    test('getZipBytesForPlugin delegates call to PluginDiscoveryService', () {
      final expectedBytes = Uint8List.fromList([1, 2, 3]);
      when(
        () => mockDiscoveryService.getZipBytesForPlugin(testManifest),
      ).thenReturn(expectedBytes);

      final result = cubit.getZipBytesForPlugin(testManifest);

      expect(result, equals(expectedBytes));
      verify(
        () => mockDiscoveryService.getZipBytesForPlugin(testManifest),
      ).called(1);
    });
  });
}
