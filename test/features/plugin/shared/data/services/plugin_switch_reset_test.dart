import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_lifecycle_state.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/services/plugin_switch_reset.dart';

PluginManifest manifest(String id) => PluginManifest(
  id: id,
  packageId: '${id}_package',
  type: 'metadata',
  name: id,
  version: '1.0.0',
  pluginSdkVersion: '7.0.0',
  author: 'Tester',
  description: 'Test plugin',
);

void main() {
  late StreamController<PluginLifecycleState> lifecycle;
  late int resets;
  late PluginSwitchReset reset;

  setUp(() {
    lifecycle = StreamController<PluginLifecycleState>.broadcast();
    resets = 0;
    reset = PluginSwitchReset(
      lifecycle: lifecycle.stream,
      onPluginChanged: () async => resets++,
    )..start();
  });

  tearDown(() async {
    await reset.dispose();
    await lifecycle.close();
  });

  Future<void> emit(PluginLifecycleState state) async {
    lifecycle.add(state);
    await pumpEventQueue();
  }

  test('the first manifest is the current plugin, not a switch', () async {
    await emit(const PluginLifecycleState.loading());
    await emit(PluginLifecycleState.loaded(manifest('first')));

    expect(resets, 0);
  });

  test('reloading the same plugin does not reset anything', () async {
    await emit(PluginLifecycleState.loaded(manifest('first')));
    await emit(const PluginLifecycleState.loading());
    await emit(PluginLifecycleState.loaded(manifest('first')));

    expect(resets, 0);
  });

  test('a different manifest resets once', () async {
    await emit(PluginLifecycleState.loaded(manifest('first')));
    await emit(PluginLifecycleState.loaded(manifest('second')));

    expect(resets, 1);
  });

  test('states without a manifest are ignored', () async {
    await emit(PluginLifecycleState.loaded(manifest('first')));
    await emit(const PluginLifecycleState.notConfigured());
    await emit(const PluginLifecycleState.loading());
    await emit(PluginLifecycleState.failure(Exception('boom')));

    expect(resets, 0);
  });

  test('an incompatible manifest still counts as a switch', () async {
    await emit(PluginLifecycleState.loaded(manifest('first')));
    await emit(PluginLifecycleState.incompatible(manifest('second')));

    expect(resets, 1);
  });

  test('starting twice does not subscribe twice', () async {
    reset.start();

    await emit(PluginLifecycleState.loaded(manifest('first')));
    await emit(PluginLifecycleState.loaded(manifest('second')));

    expect(resets, 1);
  });
}
