import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/features/plugin/discovery/presentation/cubit/plugin_discovery_cubit.dart';
import 'package:music_are/features/plugin/discovery/presentation/cubit/plugin_discovery_state.dart';
import 'package:music_are/features/plugin/shared/data/services/plugin_catalog.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';

class MockPluginCatalog extends Mock implements PluginCatalog {}

void main() {
  setUpAll(() {
    registerFallbackValue(PluginType.metadata);
  });

  group('PluginDiscoveryCubit Unit Tests', () {
    late MockPluginCatalog catalog;
    late PluginDiscoveryCubit cubit;

    final manifest = PluginManifest(
      id: 'org.musicare.metadata.test',
      packageId: 'test_plugin',
      type: 'metadata',
      name: 'Test Plugin',
      version: '1.0.0',
      pluginSdkVersion: '1.0.0',
      author: 'Tester',
      description: 'Test plugin',
    );

    setUp(() {
      catalog = MockPluginCatalog();
      cubit = PluginDiscoveryCubit(catalog);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is PluginDiscoveryInitialState', () {
      expect(cubit.state, isA<PluginDiscoveryInitialState>());
    });

    test('fetchPlugins emits Loading and Loaded with a map by id', () async {
      when(
        () => catalog.latest(
          PluginType.metadata,
          forceRefresh: false,
        ),
      ).thenAnswer((_) async => {manifest.id: manifest});

      expectLater(
        cubit.stream,
        emitsInOrder([
          isA<PluginDiscoveryLoadingState>(),
          isA<PluginDiscoveryLoadedState>()
              .having((s) => s.plugins.length, 'length', 1)
              .having((s) => s.plugins[manifest.id]?.name, 'name', 'Test Plugin'),
        ]),
      );

      await cubit.fetchPlugins(type: PluginType.metadata);
    });

    test('a network error becomes PluginDiscoveryErrorState', () async {
      when(
        () => catalog.latest(any(), forceRefresh: any(named: 'forceRefresh')),
      ).thenThrow(Exception('offline'));

      await cubit.fetchPlugins(type: PluginType.metadata);

      expect(cubit.state, isA<PluginDiscoveryErrorState>());
    });

  });
}
