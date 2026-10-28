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
      () => preferences.setActivePluginId(any(), any()),
    ).thenAnswer((_) async => true);
    when(
      () => preferences.removePluginScopedKeys(any()),
    ).thenAnswer((_) async {});
    when(
      () => storage.installed(PluginType.metadata, installed.id),
    ).thenAnswer((_) async => installed);
    when(
      () => storage.codeDir(any(), any()),
    ).thenAnswer((_) async => '/tmp/plugin');
    when(() => storage.commit(any(), any())).thenAnswer((_) async {});
    when(() => storage.rollback(any(), any())).thenAnswer((_) async {});
    when(() => storage.removeCodeDir(any(), any())).thenAnswer((_) async {});
    when(() => catalog.latest(PluginType.metadata)).thenAnswer(
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

  test('initialize loads the active plugin from disk', () async {
    await manager.initialize();

    verify(() => runtime.load(installed.id, '/tmp/plugin')).called(1);
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

  test(
    'apply on the same id updates without purging or removing code',
    () async {
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
        return sameId;
      });
      when(() => runtime.load(sameId.id, any())).thenAnswer((_) async {
        events.add('load');
        return null;
      });
      when(() => storage.commit(PluginType.metadata, sameId.id)).thenAnswer((
        _,
      ) async {
        events.add('commit');
      });

      final result = await manager.apply(PluginType.metadata, sameId);

      expect(result, sameId);
      expect(events, ['download', 'install', 'load', 'commit']);
      verifyNever(() => auth.logout());
      verifyNever(() => storage.removeCodeDir(any(), any()));
      expect(preferences.activePluginId(PluginType.metadata), sameId.id);
    },
  );

  test(
    'apply on a different id logs out the old plugin and removes its code',
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
        return target;
      });
      when(() => auth.logout()).thenAnswer((_) async {
        events.add('logout');
      });
      when(() => runtime.load(target.id, any())).thenAnswer((_) async {
        events.add('load');
        return null;
      });
      when(
        () => storage.removeCodeDir(PluginType.metadata, installed.id),
      ).thenAnswer((_) async {
        events.add('remove');
      });

      await manager.apply(PluginType.metadata, target);

      expect(events, ['install', 'logout', 'load', 'remove']);
      verify(
        () => preferences.setActivePluginId(PluginType.metadata, target.id),
      ).called(1);
      verify(() => preferences.removePluginScopedKeys(installed.id)).called(1);
      verify(() => storage.commit(PluginType.metadata, target.id)).called(1);
    },
  );

  test('a failed activation rolls the new code back', () async {
    final bytes = Uint8List.fromList([1, 2, 3]);
    when(() => catalog.download(target)).thenAnswer((_) async => bytes);
    when(
      () => storage.install(
        PluginType.metadata,
        bytes,
        validate: any(named: 'validate'),
      ),
    ).thenAnswer((_) async => target);
    final error = Exception('activation failed');
    when(() => runtime.load(target.id, any())).thenAnswer((_) async => error);

    await expectLater(
      manager.apply(PluginType.metadata, target),
      throwsA(isA<PluginActivationException>()),
    );

    verify(() => storage.rollback(PluginType.metadata, target.id)).called(1);
    verifyNever(() => preferences.setActivePluginId(any(), any()));
    verifyNever(() => storage.commit(any(), any()));
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
}
