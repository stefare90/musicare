import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';

abstract class AudioSourcePluginState {}

class AudioSourcePluginInitialState extends AudioSourcePluginState {}

class AudioSourcePluginLoadingState extends AudioSourcePluginState {}

class AudioSourcePluginNotConfiguredState extends AudioSourcePluginState {}

class AudioSourcePluginLoadedState extends AudioSourcePluginState {
  final PluginManifest manifest;
  final int port;

  AudioSourcePluginLoadedState({required this.manifest, required this.port});
}

class AudioSourcePluginErrorState extends AudioSourcePluginState {
  final Object error;
  AudioSourcePluginErrorState(this.error);
}
