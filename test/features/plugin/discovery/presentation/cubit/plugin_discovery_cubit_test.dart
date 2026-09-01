import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/features/plugin/discovery/data/services/plugin_discovery_service.dart';
import 'package:music_are/features/plugin/discovery/presentation/cubit/plugin_discovery_cubit.dart';
import 'package:music_are/features/plugin/discovery/presentation/cubit/plugin_discovery_state.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';

class MockPluginDiscoveryService extends Mock
    implements PluginDiscoveryService {}

class FakePluginManifest extends Fake implements PluginManifest {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakePluginManifest());
    registerFallbackValue(PluginType.metadata);
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
      'fetchCommunityPlugins emits Loading and Loaded states with type filtering',
      () async {
        when(
          () => mockDiscoveryService.fetchCommunityPlugins(
            type: any(named: 'type'),
          ),
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

        await cubit.fetchCommunityPlugins(type: PluginType.metadata);
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
