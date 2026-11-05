import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/features/plugin/management/presentation/cubit/plugin_manager_state.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';

import '../../../../../helpers/metadata_plugin_test_helpers.dart';

PluginManifest _versioned(String version) {
  final base = testPluginManifest();
  return PluginManifest(
    id: base.id,
    packageId: base.packageId,
    type: base.type,
    name: base.name,
    version: version,
    pluginSdkVersion: base.pluginSdkVersion,
    author: base.author,
    description: base.description,
  );
}

void main() {
  final installed = _versioned('1.0.0');
  final remote = _versioned('2.0.0');

  PluginManagerState stateWith({
    PluginSlotState? metadata,
    PluginSlotState? audioSource,
  }) => PluginManagerState({
    PluginType.metadata: metadata ?? const PluginSlotState(),
    PluginType.audioSource: audioSource ?? const PluginSlotState(),
  });

  test('no update pending yields no type', () {
    expect(stateWith().updatableTypes, isEmpty);
    expect(
      stateWith(
        metadata: PluginSlotState(installed: installed, remote: installed),
      ).updatableTypes,
      isEmpty,
    );
  });

  test('one updatable slot yields its type', () {
    final state = stateWith(
      metadata: PluginSlotState(
        installed: installed,
        remote: remote,
        updateAvailable: true,
      ),
    );

    expect(state.updatableTypes, [PluginType.metadata]);
  });

  test('both slots updatable are listed in type order', () {
    final state = stateWith(
      metadata: PluginSlotState(
        installed: installed,
        remote: remote,
        updateAvailable: true,
      ),
      audioSource: PluginSlotState(
        installed: installed,
        remote: remote,
        updateAvailable: true,
      ),
    );

    expect(state.updatableTypes, PluginType.values);
  });

  test('an update without a remote manifest is not offered', () {
    final state = stateWith(
      metadata: PluginSlotState(installed: installed, updateAvailable: true),
    );

    expect(state.updatableTypes, isEmpty);
  });

  test('an incompatible plugin is left to the setup page', () {
    final state = stateWith(
      metadata: PluginSlotState(
        installed: installed,
        remote: remote,
        updateAvailable: true,
        incompatible: true,
      ),
    );

    expect(state.updatableTypes, isEmpty);
  });
}
