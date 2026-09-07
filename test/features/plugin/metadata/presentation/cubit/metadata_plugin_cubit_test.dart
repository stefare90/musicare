import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gyawun_metadata_sdk/metadata/interfaces/iauth.dart';
import 'package:gyawun_metadata_sdk/metadata/interfaces/imetadata_plugin.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/services/preferences_service.dart';
import 'package:music_are/features/plugin/discovery/data/services/plugin_discovery_service.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_state.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';

class MockMetadataPluginEngine extends Mock implements MetadataPluginEngine {}

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

  group('MetadataPluginCubit Unit Tests', () {
    late MockMetadataPluginEngine mockPluginEngine;
    late MockPreferencesService mockPreferences;
    late MockPluginDiscoveryService mockDiscoveryService;
    late MockMetadataPlugin mockMetadataPlugin;
    late MockAuth mockAuth;
    late MetadataPluginCubit cubit;

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
      mockPluginEngine = MockMetadataPluginEngine();
      mockPreferences = MockPreferencesService();
      mockDiscoveryService = MockPluginDiscoveryService();
      mockMetadataPlugin = MockMetadataPlugin();
      mockAuth = MockAuth();

      cubit = MetadataPluginCubit(
        mockPluginEngine,
        mockPreferences,
        mockDiscoveryService,
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is MetadataPluginInitialState', () {
      expect(cubit.state, isA<MetadataPluginInitialState>());
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
            isA<MetadataPluginLoadingState>(),
            isA<MetadataPluginLoadedState>()
                .having((s) => s.manifest.id, 'id', 'org.gyawun.musicbrainz')
                .having((s) => s.isAuthenticated, 'isAuthenticated', isTrue),
          ]),
        );

        await cubit.initialize();
      },
    );

    test(
      'unload unloads metadata and emits MetadataPluginNotConfiguredState',
      () async {
        when(() => mockPluginEngine.unloadMetadata()).thenAnswer((_) {});
        when(
          () => mockPreferences.removeActivePluginId(),
        ).thenAnswer((_) async => true);

        await cubit.unload();

        expect(cubit.state, isA<MetadataPluginNotConfiguredState>());
      },
    );

    test(
      'initialize emits MetadataPluginIncompatibleState when SDK is incompatible',
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
        ).thenThrow(
          IncompatibleSdkVersionException(
            manifest: testManifest,
            hostVersion: '2.0.3',
          ),
        );

        expectLater(
          cubit.stream,
          emitsInOrder([
            isA<MetadataPluginLoadingState>(),
            isA<MetadataPluginIncompatibleState>().having(
              (s) => s.obsoleteManifest.id,
              'id',
              'org.gyawun.musicbrainz',
            ),
          ]),
        );

        await cubit.initialize();
      },
    );

    test(
      'authenticate updates isAuthenticated to true in loaded state',
      () async {
        cubit.emit(
          MetadataPluginLoadedState(
            manifest: testManifest,
            isAuthenticated: false,
          ),
        );

        when(() => mockPluginEngine.metadata).thenReturn(mockMetadataPlugin);
        when(() => mockMetadataPlugin.auth).thenReturn(mockAuth);
        when(() => mockAuth.authenticate()).thenAnswer((_) async {});
        when(() => mockAuth.isAuthenticated()).thenAnswer((_) async => true);

        await cubit.authenticate();

        expect(
          (cubit.state as MetadataPluginLoadedState).isAuthenticated,
          isTrue,
        );
        verify(() => mockAuth.authenticate()).called(1);
      },
    );

    test('logout updates isAuthenticated to false in loaded state', () async {
      cubit.emit(
        MetadataPluginLoadedState(
          manifest: testManifest,
          isAuthenticated: true,
        ),
      );

      when(() => mockPluginEngine.metadata).thenReturn(mockMetadataPlugin);
      when(() => mockMetadataPlugin.auth).thenReturn(mockAuth);
      when(() => mockAuth.logout()).thenAnswer((_) async {});
      when(() => mockAuth.isAuthenticated()).thenAnswer((_) async => false);

      await cubit.logout();

      expect(
        (cubit.state as MetadataPluginLoadedState).isAuthenticated,
        isFalse,
      );
      verify(() => mockAuth.logout()).called(1);
    });
  });
}
