import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';

abstract class MetadataPluginState {}

class MetadataPluginInitialState extends MetadataPluginState {}

class MetadataPluginLoadingState extends MetadataPluginState {}

class MetadataPluginNotConfiguredState extends MetadataPluginState {}

class MetadataPluginIncompatibleState extends MetadataPluginState {
  final PluginManifest obsoleteManifest;
  MetadataPluginIncompatibleState(this.obsoleteManifest);
}

class MetadataPluginLoadedState extends MetadataPluginState {
  final PluginManifest manifest;
  final bool isAuthenticated;

  MetadataPluginLoadedState({
    required this.manifest,
    required this.isAuthenticated,
  });

  MetadataPluginLoadedState copyWith({
    PluginManifest? manifest,
    bool? isAuthenticated,
  }) {
    return MetadataPluginLoadedState(
      manifest: manifest ?? this.manifest,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class MetadataPluginErrorState extends MetadataPluginState {
  final Object error;
  MetadataPluginErrorState(this.error);
}
