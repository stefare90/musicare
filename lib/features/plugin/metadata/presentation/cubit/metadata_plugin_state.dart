import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';

abstract class MetadataPluginState {
  bool get isAuthenticated => false;
}

class MetadataPluginInitialState extends MetadataPluginState {}

class MetadataPluginLoadingState extends MetadataPluginState {}

class MetadataPluginNotConfiguredState extends MetadataPluginState {}

class MetadataPluginIncompatibleState extends MetadataPluginState {
  final PluginManifest obsoleteManifest;
  MetadataPluginIncompatibleState(this.obsoleteManifest);
}

class MetadataPluginLoadedState extends MetadataPluginState {
  final PluginManifest manifest;

  @override
  final bool isAuthenticated;

  /// Identity reported by the plugin (`IUser.me()['user_id']`); null while
  /// signed out or when the provider does not expose one.
  final String? userName;

  MetadataPluginLoadedState({
    required this.manifest,
    required this.isAuthenticated,
    this.userName,
  });
}

class MetadataPluginErrorState extends MetadataPluginState {
  final Object error;
  MetadataPluginErrorState(this.error);
}
