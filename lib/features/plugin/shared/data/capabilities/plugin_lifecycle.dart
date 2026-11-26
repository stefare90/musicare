import 'dart:async';

import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_lifecycle_state.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';

export 'package:music_are/features/plugin/shared/data/models/plugin_lifecycle_state.dart';

abstract interface class PluginLifecycle {
  PluginType get type;

  PluginLifecycleState get state;

  Stream<PluginLifecycleState> get changes;

  /// Loads the plugin whose immutable code lives in [codeDir]. Returns null on
  /// success, otherwise the cause of the failure.
  Future<Object?> load(String pluginId, String codeDir);

  Future<void> unload();

  bool isCompatible(PluginManifest manifest);

  void validate(PluginManifest manifest);

  String get hostSdkVersion;
}
