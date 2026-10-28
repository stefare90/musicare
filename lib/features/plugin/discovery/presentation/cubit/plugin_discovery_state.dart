import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';

abstract class PluginDiscoveryState {}

class PluginDiscoveryInitialState extends PluginDiscoveryState {}

class PluginDiscoveryLoadingState extends PluginDiscoveryState {}

class PluginDiscoveryLoadedState extends PluginDiscoveryState {
  final Map<String, PluginManifest> plugins;
  PluginDiscoveryLoadedState(this.plugins);
}

class PluginDiscoveryErrorState extends PluginDiscoveryState {
  final Object error;
  PluginDiscoveryErrorState(this.error);
}
