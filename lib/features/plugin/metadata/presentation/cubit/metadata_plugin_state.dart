import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';

/// Lifecycle state; the account identity lives in `UserCubit`, not here.
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

  MetadataPluginLoadedState({required this.manifest});
}

class MetadataPluginErrorState extends MetadataPluginState {
  final Object error;
  MetadataPluginErrorState(this.error);
}
