import 'package:music_are/features/plugin/data/models/plugin_manifest.dart';

abstract class PluginState {}

class PluginInitialState extends PluginState {}

class PluginLoadingState extends PluginState {}

class PluginNotConfiguredState extends PluginState {}

class PluginIncompatibleState extends PluginState {
  final PluginManifest obsoleteManifest;
  PluginIncompatibleState(this.obsoleteManifest);
}

class PluginLoadedState extends PluginState {
  final PluginManifest manifest;
  final bool isAuthenticated;

  PluginLoadedState({required this.manifest, required this.isAuthenticated});

  PluginLoadedState copyWith({
    PluginManifest? manifest,
    bool? isAuthenticated,
  }) {
    return PluginLoadedState(
      manifest: manifest ?? this.manifest,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class PluginErrorState extends PluginState {
  final Object error;
  PluginErrorState(this.error);
}
