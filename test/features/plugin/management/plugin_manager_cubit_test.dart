import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/features/plugin/management/data/models/plugin_slot_data.dart';
import 'package:music_are/features/plugin/management/data/services/plugin_manager.dart';
import 'package:music_are/features/plugin/management/presentation/cubit/plugin_manager_cubit.dart';
import 'package:music_are/features/plugin/management/presentation/cubit/plugin_manager_state.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';

import '../../../helpers/metadata_plugin_test_helpers.dart';

class MockPluginManager extends Mock implements PluginManager {}

void main() {
  setUpAll(() {
    registerFallbackValue(testPluginManifest());
    registerFallbackValue(PluginType.metadata);
  });

  late MockPluginManager manager;
  late NoticeBus notices;
  late PluginManagerCubit cubit;

  final installed = testPluginManifest();
  final remote = PluginManifest(
    id: installed.id,
    packageId: installed.packageId,
    type: installed.type,
    name: installed.name,
    version: '2.0.0',
    pluginSdkVersion: installed.pluginSdkVersion,
    author: installed.author,
    description: installed.description,
  );

  setUp(() {
    manager = MockPluginManager();
    notices = NoticeBus();
    cubit = PluginManagerCubit(manager, notices);
  });

  tearDown(() async {
    await notices.close();
    await cubit.close();
  });

  test('refresh fills the slot from the manager snapshot', () async {
    when(
      () => manager.snapshot(
        PluginType.metadata,
        fetchCatalog: any(named: 'fetchCatalog'),
      ),
    ).thenAnswer(
      (_) async => PluginSlotData(
        installed: installed,
        remote: remote,
        updateAvailable: true,
      ),
    );
    when(
      () => manager.snapshot(
        PluginType.audioSource,
        fetchCatalog: any(named: 'fetchCatalog'),
      ),
    ).thenAnswer((_) async => const PluginSlotData());

    await cubit.refresh(fetchCatalog: false);

    final slot = cubit.state.slot(PluginType.metadata);
    expect(slot.installed, installed);
    expect(slot.remote, remote);
    expect(slot.updateAvailable, isTrue);
  });

  test('update applies the remote manifest', () async {
    when(
      () => manager.snapshot(
        PluginType.metadata,
        fetchCatalog: any(named: 'fetchCatalog'),
      ),
    ).thenAnswer((_) async => PluginSlotData(installed: installed, remote: remote));
    when(
      () => manager.snapshot(
        PluginType.audioSource,
        fetchCatalog: any(named: 'fetchCatalog'),
      ),
    ).thenAnswer((_) async => const PluginSlotData());
    when(() => manager.apply(PluginType.metadata, remote)).thenAnswer((_) async => remote);

    await cubit.refresh(fetchCatalog: false);
    await cubit.update(PluginType.metadata);

    final slot = cubit.state.slot(PluginType.metadata);
    expect(slot.installed, remote);
    expect(slot.phase, PluginSlotPhase.idle);
    verify(() => manager.apply(PluginType.metadata, remote)).called(1);
  });

  test('reinstall fetches the catalog when the slot has no remote', () async {
    when(
      () => manager.snapshot(PluginType.metadata, fetchCatalog: true),
    ).thenAnswer(
      (_) async => PluginSlotData(installed: installed, remote: remote),
    );
    when(
      () => manager.apply(PluginType.metadata, remote),
    ).thenAnswer((_) async => remote);

    await cubit.reinstall(PluginType.metadata);

    verify(
      () => manager.snapshot(PluginType.metadata, fetchCatalog: true),
    ).called(1);
    verify(() => manager.apply(PluginType.metadata, remote)).called(1);
    expect(cubit.state.slot(PluginType.metadata).installed, remote);
  });

  test('reinstall falls back to the installed manifest when the catalog is empty', () async {
    when(
      () => manager.snapshot(PluginType.metadata, fetchCatalog: true),
    ).thenAnswer((_) async => PluginSlotData(installed: installed));
    when(
      () => manager.apply(PluginType.metadata, installed),
    ).thenAnswer((_) async => installed);

    await cubit.reinstall(PluginType.metadata);

    verify(() => manager.apply(PluginType.metadata, installed)).called(1);
  });

  test('change applies the chosen manifest', () async {
    when(() => manager.apply(PluginType.metadata, remote)).thenAnswer((_) async => remote);

    await cubit.change(PluginType.metadata, remote);

    expect(cubit.state.slot(PluginType.metadata).installed, remote);
  });

  test('an apply failure returns to idle and emits a notice', () async {
    final emitted = <Notice>[];
    notices.notices.listen(emitted.add);
    final error = Exception('install failed');
    when(() => manager.apply(PluginType.metadata, remote)).thenThrow(error);

    await cubit.change(PluginType.metadata, remote);
    await Future<void>.delayed(Duration.zero);

    final slot = cubit.state.slot(PluginType.metadata);
    expect(slot.phase, PluginSlotPhase.idle);
    expect(slot.error, error);
    expect(emitted.single, isA<ErrorNotice>());
  });

  test('update without a remote manifest reports a download error', () async {
    final emitted = <Notice>[];
    notices.notices.listen(emitted.add);

    await cubit.update(PluginType.metadata);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.slot(PluginType.metadata).error, isNotNull);
    expect(emitted, isNotEmpty);
  });

  test('alternatives delegate to the manager', () async {
    when(() => manager.alternatives(PluginType.metadata)).thenAnswer((_) async => [remote]);

    expect(await cubit.alternatives(PluginType.metadata), [remote]);
    verify(() => manager.alternatives(PluginType.metadata)).called(1);
  });
}
