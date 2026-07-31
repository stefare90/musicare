import 'package:music_are/features/plugin/data/models/plugin_manifest.dart';

abstract class PluginDiscoveryState {}

class PluginDiscoveryInitialState extends PluginDiscoveryState {}

class PluginDiscoveryLoadingState extends PluginDiscoveryState {}

class PluginDiscoveryLoadedState extends PluginDiscoveryState {
  final List<PluginManifest> plugins;
  PluginDiscoveryLoadedState(this.plugins);
}

class PluginDiscoveryErrorState extends PluginDiscoveryState {
  final String message;
  PluginDiscoveryErrorState(this.message);
}
