import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';

enum PluginSlotPhase { idle, busy }

const Object _unset = Object();

class PluginSlotState {
  final PluginManifest? installed;
  final PluginManifest? remote;
  final bool updateAvailable;
  final bool incompatible;
  final PluginSlotPhase phase;
  final Object? error;

  const PluginSlotState({
    this.installed,
    this.remote,
    this.updateAvailable = false,
    this.incompatible = false,
    this.phase = PluginSlotPhase.idle,
    this.error,
  });

  PluginSlotState copyWith({
    Object? installed = _unset,
    Object? remote = _unset,
    bool? updateAvailable,
    bool? incompatible,
    PluginSlotPhase? phase,
    Object? error = _unset,
  }) {
    return PluginSlotState(
      installed: identical(installed, _unset)
          ? this.installed
          : installed as PluginManifest?,
      remote: identical(remote, _unset)
          ? this.remote
          : remote as PluginManifest?,
      updateAvailable: updateAvailable ?? this.updateAvailable,
      incompatible: incompatible ?? this.incompatible,
      phase: phase ?? this.phase,
      error: identical(error, _unset) ? this.error : error,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PluginSlotState &&
        other.installed == installed &&
        other.remote == remote &&
        other.updateAvailable == updateAvailable &&
        other.incompatible == incompatible &&
        other.phase == phase &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(
    installed,
    remote,
    updateAvailable,
    incompatible,
    phase,
    error,
  );
}

class PluginManagerState {
  final Map<PluginType, PluginSlotState> slots;

  const PluginManagerState(this.slots);

  PluginSlotState slot(PluginType type) =>
      slots[type] ?? const PluginSlotState();
}
