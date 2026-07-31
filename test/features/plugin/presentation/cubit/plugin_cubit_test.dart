import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gyawun_metadata_sdk/metadata/interfaces/iauth.dart';
import 'package:gyawun_metadata_sdk/metadata/interfaces/imetadata_plugin.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/services/preferences_service.dart';
import 'package:music_are/features/plugin/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/data/services/plugin_discovery_service.dart';
import 'package:music_are/features/plugin/data/services/plugin_engine.dart';
import 'package:music_are/features/plugin/presentation/cubit/plugin_cubit.dart';
import 'package:music_are/features/plugin/presentation/cubit/plugin_state.dart';

class MockPluginEngine extends Mock implements PluginEngine {}

class MockPreferencesService extends Mock implements PreferencesService {}

class MockPluginDiscoveryService extends Mock
    implements PluginDiscoveryService {}

class MockMetadataPlugin extends Mock implements IMetadataPlugin {}

class MockAuth extends Mock implements IAuth {}

class FakePluginManifest extends Fake implements PluginManifest {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(FakePluginManifest());
  });

  group('PluginCubit Unit Tests', () {
    late MockPluginEngine mockPluginEngine;
    late MockPreferencesService mockPreferences;
    late MockPluginDiscoveryService mockDiscoveryService;
    late MockMetadataPlugin mockMetadataPlugin;
    late MockAuth mockAuth;
    late PluginCubit cubit;

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
      mockPluginEngine = MockPluginEngine();
      mockPreferences = MockPreferencesService();
      mockDiscoveryService = MockPluginDiscoveryService();
      mockMetadataPlugin = MockMetadataPlugin();
      mockAuth = MockAuth();

      cubit = PluginCubit(
        mockPluginEngine,
        mockPreferences,
        mockDiscoveryService,
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is PluginInitialState', () {
      expect(cubit.state, isA<PluginInitialState>());
    });

    test(
      'initialize loads plugin from disk when saved plugin id exists',
      () async {
        when(
          () => mockPreferences.getActivePluginId(),
        ).thenReturn('org.gyawun.musicbrainz');
        when(
          () => mockPluginEngine.isPluginInstalledOnDisk(
            'org.gyawun.musicbrainz',
          ),
        ).thenAnswer((_) async => true);
        when(
          () => mockPluginEngine.loadFromDisk('org.gyawun.musicbrainz'),
        ).thenAnswer((_) async {});
        when(() => mockPluginEngine.metadata).thenReturn(mockMetadataPlugin);
        when(() => mockMetadataPlugin.auth).thenReturn(mockAuth);
        when(() => mockAuth.isAuthenticated()).thenAnswer((_) async => true);
        when(() => mockPluginEngine.metadataManifest).thenReturn(testManifest);

        expectLater(
          cubit.stream,
          emitsInOrder([
            isA<PluginLoadingState>(),
            isA<PluginLoadedState>()
                .having((s) => s.manifest.id, 'id', 'org.gyawun.musicbrainz')
                .having((s) => s.isAuthenticated, 'isAuthenticated', isTrue),
          ]),
        );

        await cubit.initialize();
      },
    );

    test(
      'initialize emits PluginNotConfiguredState when no saved plugin id exists',
      () async {
        when(() => mockPreferences.getActivePluginId()).thenReturn(null);

        expectLater(
          cubit.stream,
          emitsInOrder([
            isA<PluginLoadingState>(),
            isA<PluginNotConfiguredState>(),
          ]),
        );

        await cubit.initialize();
      },
    );

    test(
      'installDiscoveredPlugin retrieves zip bytes from discovery service and loads plugin',
      () async {
        final dummyZipBytes = Uint8List.fromList([1, 2, 3, 4]);

        when(
          () => mockDiscoveryService.getZipBytesForPlugin(any()),
        ).thenReturn(dummyZipBytes);
        when(
          () => mockPluginEngine.loadFromZipBytes(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockPreferences.setActivePluginId(any()),
        ).thenAnswer((_) async => true);
        when(() => mockPluginEngine.metadata).thenReturn(mockMetadataPlugin);
        when(() => mockMetadataPlugin.auth).thenReturn(mockAuth);
        when(() => mockAuth.isAuthenticated()).thenAnswer((_) async => false);
        when(() => mockPluginEngine.metadataManifest).thenReturn(testManifest);

        expectLater(
          cubit.stream,
          emitsInOrder([
            isA<PluginLoadingState>(),
            isA<PluginLoadedState>()
                .having((s) => s.manifest.id, 'id', 'org.gyawun.musicbrainz')
                .having((s) => s.isAuthenticated, 'isAuthenticated', isFalse),
          ]),
        );

        await cubit.installDiscoveredPlugin(testManifest);

        verify(
          () => mockPreferences.setActivePluginId('org.gyawun.musicbrainz'),
        ).called(1);
      },
    );

    test(
      'authenticate triggers auth on metadata plugin and updates isAuthenticated state',
      () async {
        when(() => mockPluginEngine.metadata).thenReturn(mockMetadataPlugin);
        when(() => mockMetadataPlugin.auth).thenReturn(mockAuth);
        when(() => mockAuth.authenticate()).thenAnswer((_) async {});
        when(() => mockAuth.isAuthenticated()).thenAnswer((_) async => true);

        // Seed Cubit with PluginLoadedState(isAuthenticated: false)
        cubit.emit(
          PluginLoadedState(manifest: testManifest, isAuthenticated: false),
        );

        await cubit.authenticate();

        expect(cubit.state, isA<PluginLoadedState>());
        final state = cubit.state as PluginLoadedState;
        expect(state.isAuthenticated, isTrue);

        verify(() => mockAuth.authenticate()).called(1);
      },
    );

    test(
      'unload unloads metadata, removes saved plugin id, and emits PluginNotConfiguredState',
      () async {
        when(() => mockPluginEngine.unloadMetadata()).thenAnswer((_) {});
        when(
          () => mockPreferences.removeActivePluginId(),
        ).thenAnswer((_) async => true);

        await cubit.unload();

        expect(cubit.state, isA<PluginNotConfiguredState>());

        verify(() => mockPluginEngine.unloadMetadata()).called(1);
        verify(() => mockPreferences.removeActivePluginId()).called(1);
      },
    );
  });
}
