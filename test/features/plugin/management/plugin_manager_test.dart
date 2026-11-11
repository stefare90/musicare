import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/services/preferences_service.dart';
import 'package:music_are/features/plugin/management/data/services/plugin_manager.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/plugin/shared/data/services/plugin_storage.dart';
import 'package:music_are/features/plugin/shared/data/services/plugin_catalog.dart';
import 'package:music_are/features/plugin/shared/data/capabilities/plugin_auth.dart';
import 'package:music_are/features/plugin/shared/data/capabilities/plugin_lifecycle.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_entry.dart';
import 'package:music_are/features/plugin/shared/data/services/plugin_registry.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/plugin_archive.dart';

class MockPluginLifecycle extends Mock implements PluginLifecycle {}

class MockPluginAuth extends Mock implements PluginAuth {}

class MockPluginCatalog extends Mock implements PluginCatalog {}

class MockPluginStorage extends Mock implements PluginStorage {}

class MockPreferencesService extends Mock implements PreferencesService {}

PluginManifest manifest({String id = 'old.plugin', String version = '1.0.0'}) {
  return PluginManifest(
    id: id,
    packageId: '${id}_package',
    type: 'metadata',
    name: id,
    version: version,
    pluginSdkVersion: '6.0.0',
    author: 'Tester',
    description: 'Test plugin',
  );
}

void main() {
  late MockPluginLifecycle runtime;
  late MockPluginAuth auth;
  late MockPluginCatalog catalog;
  late MockPluginStorage storage;
  late MockPreferencesService preferences;
  late PluginManager manager;

  final installed = manifest();
  final remote = manifest(version: '2.0.0');
  final target = manifest(id: 'new.plugin');

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(manifest());
    registerFallbackValue(PluginType.metadata);
  });

  setUp(() {
    runtime = MockPluginLifecycle();
    auth = MockPluginAuth();
    catalog = MockPluginCatalog();
    storage = MockPluginStorage();
    preferences = MockPreferencesService();

    when(() => runtime.type).thenReturn(PluginType.metadata);
    when(() => runtime.hostSdkVersion).thenReturn('6.0.0');
    when(() => runtime.isCompatible(any())).thenReturn(true);
    when(
      () => runtime.state,
    ).thenReturn(const PluginLifecycleState.notConfigured());
    when(() => runtime.changes).thenAnswer((_) => const Stream.empty());
    when(() => auth.logout()).thenAnswer((_) async {});
    when(() => auth.refresh()).thenAnswer((_) async {});
    when(() => runtime.load(any(), any())).thenAnswer((_) async => null);
    when(
      () => preferences.activePluginId(PluginType.metadata),
    ).thenReturn(installed.id);
    when(
      () => preferences.activePluginVersionDir(PluginType.metadata),
    ).thenReturn(installed.version);
    when(
      () => preferences.setActivePluginId(any(), any()),
    ).thenAnswer((_) async => true);
    when(
      () => preferences.setActivePluginVersionDir(any(), any()),
    ).thenAnswer((_) async => true);
    when(
      () => preferences.removePluginScopedKeys(any()),
    ).thenAnswer((_) async {});
    when(
      () => storage.installed(
        PluginType.metadata,
        installed.id,
        installed.version,
      ),
    ).thenAnswer((_) async => installed);
    when(
      () => storage.codeDir(any(), any(), any()),
    ).thenAnswer((_) async => '/tmp/plugin');
    when(
      () => catalog.latest(PluginType.metadata),
    ).thenAnswer(
      (_) async => {
        installed.id: installed,
        remote.id: remote,
        target.id: target,
      },
    );

    manager = PluginManager(
      registry: PluginRegistry([PluginEntry(lifecycle: runtime, auth: auth)]),
      catalog: catalog,
      storage: storage,
      preferences: preferences,
    );
  });

  test('every PluginType has a runtime', () {
    final audio = MockPluginLifecycle();
    when(() => audio.type).thenReturn(PluginType.audioSource);
    when(
      () => audio.state,
    ).thenReturn(const PluginLifecycleState.notConfigured());
    final full = PluginManager(
      registry: PluginRegistry([
        PluginEntry(lifecycle: runtime, auth: auth),
        PluginEntry(lifecycle: audio),
      ]),
      catalog: catalog,
      storage: storage,
      preferences: preferences,
    );

    for (final type in PluginType.values) {
      expect(() => full.pluginState(type), returnsNormally);
    }
  });

  test('initialize loads the active plugin by id and version', () async {
    await manager.initialize();

    verify(
      () => runtime.load(installed.id, '/tmp/plugin'),
    ).called(1);
    verify(
      () => storage.codeDir(
        PluginType.metadata,
        installed.id,
        installed.version,
      ),
    ).called(1);
  });

  test('initialize skips a plugin without a version pointer', () async {
    when(
      () => preferences.activePluginVersionDir(PluginType.metadata),
    ).thenReturn(null);

    await manager.initialize();

    verifyNever(() => runtime.load(any(), any()));
  });

  test(
    'snapshot reports the available update only when newer and compatible',
    () async {
      final snapshot = await manager.snapshot(PluginType.metadata);

      expect(snapshot.installed, installed);
      expect(snapshot.remote, remote);
      expect(snapshot.updateAvailable, isTrue);
    },
  );

  test('reloadCatalog reloads the catalog once', () async {
    when(() => catalog.reload()).thenAnswer((_) async {});

    await manager.reloadCatalog();

    verify(() => catalog.reload()).called(1);
    verifyNever(() => catalog.latest(any()));
  });

  test(
    'snapshot never marks an older or incompatible remote as an update',
    () async {
      when(
        () => catalog.latest(PluginType.metadata),
      ).thenAnswer((_) async => {installed.id: manifest(version: '0.9.0')});

      var snapshot = await manager.snapshot(PluginType.metadata);
      expect(snapshot.updateAvailable, isFalse);

      when(() => runtime.isCompatible(any())).thenReturn(false);
      snapshot = await manager.snapshot(PluginType.metadata);
      expect(snapshot.updateAvailable, isFalse);
    },
  );

  test('apply on the same id updates without purging the account', () async {
    final events = <String>[];
    final bytes = Uint8List.fromList([1, 2, 3]);
    final sameId = manifest(version: '3.0.0');
    when(
      () => preferences.activePluginId(PluginType.metadata),
    ).thenReturn(sameId.id);
    when(() => catalog.download(sameId)).thenAnswer((_) async {
      events.add('download');
      return bytes;
    });
    when(
      () => storage.install(
        PluginType.metadata,
        bytes,
        validate: any(named: 'validate'),
      ),
    ).thenAnswer((_) async {
      events.add('install');
      return (manifest: sameId, versionDir: '3.0.0');
    });
    when(() => runtime.load(sameId.id, any())).thenAnswer((_) async {
      events.add('load');
      return null;
    });

    final result = await manager.apply(PluginType.metadata, sameId);

    expect(result, sameId);
    expect(events, ['download', 'install', 'load']);
    verifyNever(() => auth.logout());
    verifyNever(() => preferences.removePluginScopedKeys(any()));
    verify(
      () => preferences.setActivePluginId(PluginType.metadata, sameId.id),
    ).called(1);
    verify(
      () => preferences.setActivePluginVersionDir(PluginType.metadata, '3.0.0'),
    ).called(1);
  });

  test(
    'apply on a different id logs out the old plugin and switches the pointer',
    () async {
      final events = <String>[];
      final bytes = Uint8List.fromList([1, 2, 3]);
      when(() => catalog.download(target)).thenAnswer((_) async => bytes);
      when(
        () => storage.install(
          PluginType.metadata,
          bytes,
          validate: any(named: 'validate'),
        ),
      ).thenAnswer((_) async {
        events.add('install');
        return (manifest: target, versionDir: '1.0.0');
      });
      when(() => auth.logout()).thenAnswer((_) async {
        events.add('logout');
      });
      when(() => runtime.load(target.id, any())).thenAnswer((_) async {
        events.add('load');
        return null;
      });

      await manager.apply(PluginType.metadata, target);

      expect(events, ['install', 'logout', 'load']);
      verify(
        () => preferences.setActivePluginId(PluginType.metadata, target.id),
      ).called(1);
      verify(
        () => preferences.setActivePluginVersionDir(PluginType.metadata, '1.0.0'),
      ).called(1);
      verify(() => preferences.removePluginScopedKeys(installed.id)).called(1);
    },
  );

  test('a failed activation keeps the active plugin and its pointer', () async {
    final bytes = Uint8List.fromList([1, 2, 3]);
    when(() => catalog.download(target)).thenAnswer((_) async => bytes);
    when(
      () => storage.install(
        PluginType.metadata,
        bytes,
        validate: any(named: 'validate'),
      ),
    ).thenAnswer((_) async => (manifest: target, versionDir: '1.0.0'));
    final error = Exception('activation failed');
    when(() => runtime.load(target.id, any())).thenAnswer((_) async => error);

    await expectLater(
      manager.apply(PluginType.metadata, target),
      throwsA(isA<PluginActivationException>()),
    );

    verifyNever(() => preferences.setActivePluginId(any(), any()));
    verifyNever(() => preferences.setActivePluginVersionDir(any(), any()));
    verifyNever(() => preferences.removePluginScopedKeys(any()));
  });

  test('an incompatible target is rejected before downloading', () async {
    when(() => runtime.isCompatible(target)).thenReturn(false);

    await expectLater(
      manager.apply(PluginType.metadata, target),
      throwsA(isA<IncompatibleSdkVersionException>()),
    );

    verifyNever(() => catalog.download(any()));
    verifyNever(
      () => storage.install(any(), any(), validate: any(named: 'validate')),
    );
    // The installed plugin must survive a refused target untouched: no active
    // id or account key changed.
    verifyNever(() => preferences.setActivePluginId(any(), any()));
    verifyNever(() => preferences.setActivePluginVersionDir(any(), any()));
    verifyNever(() => preferences.clearActivePluginId(any()));
    verifyNever(() => preferences.removePluginScopedKeys(any()));
    verifyNever(() => runtime.unload());
  });

  test('alternatives exclude the active and incompatible plugins', () async {
    final alternative = manifest(id: 'other.plugin');
    when(() => catalog.latest(PluginType.metadata)).thenAnswer(
      (_) async => {
        installed.id: installed,
        alternative.id: alternative,
        target.id: target,
      },
    );
    when(() => runtime.isCompatible(installed)).thenReturn(true);
    when(() => runtime.isCompatible(alternative)).thenReturn(true);
    when(() => runtime.isCompatible(target)).thenReturn(false);

    final result = await manager.alternatives(PluginType.metadata);

    expect(result, [alternative]);
  });

  group('with a real plugin store', () {
    late Directory tempDir;
    late PluginStorage realStorage;
    late PreferencesService realPreferences;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('plugin_manager_store_');
      realStorage = PluginStorage(appDir: () async => tempDir);
      await realStorage.install(
        PluginType.metadata,
        pluginZip(id: installed.id, version: '1.0.0'),
        validate: (_) {},
      );
      SharedPreferences.setMockInitialValues({
        'metadata_active_plugin_id': installed.id,
        'metadata_active_plugin_version_dir': '1.0.0',
      });
      realPreferences = PreferencesService(
        await SharedPreferences.getInstance(),
      );
      manager = PluginManager(
        registry: PluginRegistry([
          PluginEntry(lifecycle: runtime, auth: auth),
        ]),
        catalog: catalog,
        storage: realStorage,
        preferences: realPreferences,
      );
      File(
        '${tempDir.path}/plugins/metadata/${installed.id}/auth.json',
      ).writeAsStringSync('{"token":"keep-me"}');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    String versionDir(String id, String versionDir) =>
        '${tempDir.path}/plugins/metadata/$id/$versionDir';

    test(
      'switching plugin leaves every code dir and the old data untouched',
      () async {
        final oldManifest = File('${versionDir(installed.id, '1.0.0')}/plugin.json');
        final oldBytes = oldManifest.readAsStringSync();
        final bytes = pluginZip(id: target.id, version: '1.0.0');
        when(() => catalog.download(target)).thenAnswer((_) async => bytes);

        await manager.apply(PluginType.metadata, target);

        expect(oldManifest.existsSync(), isTrue);
        expect(oldManifest.readAsStringSync(), oldBytes);
        expect(
          File('${versionDir(target.id, '1.0.0')}/plugin.json').existsSync(),
          isTrue,
        );
        expect(
          File('${tempDir.path}/plugins/metadata/${installed.id}/auth.json')
              .existsSync(),
          isTrue,
        );
        expect(realPreferences.activePluginId(PluginType.metadata), target.id);
        expect(
          realPreferences.activePluginVersionDir(PluginType.metadata),
          '1.0.0',
        );
      },
    );

    test('reinstalling the same version writes a new path', () async {
      final oldManifest = File('${versionDir(installed.id, '1.0.0')}/plugin.json');
      final oldBytes = oldManifest.readAsStringSync();
      final bytes = pluginZip(id: installed.id, version: '1.0.0');
      when(
        () => catalog.download(any()),
      ).thenAnswer((_) async => bytes);

      await manager.apply(PluginType.metadata, installed);

      expect(oldManifest.readAsStringSync(), oldBytes);
      expect(
        File('${versionDir(installed.id, '1.0.0-2')}/plugin.json').existsSync(),
        isTrue,
      );
      expect(
        realPreferences.activePluginVersionDir(PluginType.metadata),
        '1.0.0-2',
      );
    });

    test('a failed activation leaves the active version in place', () async {
      final bytes = pluginZip(id: target.id, version: '1.0.0');
      when(() => catalog.download(target)).thenAnswer((_) async => bytes);
      when(
        () => runtime.load(target.id, any()),
      ).thenAnswer((_) async => Exception('activation failed'));

      await expectLater(
        manager.apply(PluginType.metadata, target),
        throwsA(isA<PluginActivationException>()),
      );

      expect(
        File('${versionDir(installed.id, '1.0.0')}/plugin.json').existsSync(),
        isTrue,
      );
      expect(realPreferences.activePluginId(PluginType.metadata), installed.id);
      expect(
        realPreferences.activePluginVersionDir(PluginType.metadata),
        '1.0.0',
      );
    });
  });
}
