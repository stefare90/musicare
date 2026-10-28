import 'dart:async';

import 'package:music_are/features/plugin/audio_source/data/services/audio_source_plugin_engine.dart';
import 'package:music_are/features/plugin/shared/data/capabilities/plugin_lifecycle.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:musicare_audio_host_sdk/musicare_audio_host_sdk.dart';

class AudioSourcePluginLifecycle implements PluginLifecycle {
  AudioSourcePluginLifecycle(this._engine);

  final AudioSourcePluginEngine _engine;
  final StreamController<PluginLifecycleState> _changes =
      StreamController<PluginLifecycleState>.broadcast();
  PluginLifecycleState _state = const PluginLifecycleState.notConfigured();

  @override
  PluginType get type => PluginType.audioSource;

  @override
  PluginLifecycleState get state => _state;

  @override
  Stream<PluginLifecycleState> get changes => _changes.stream;

  @override
  String get hostSdkVersion => packageVersion;

  @override
  bool isCompatible(PluginManifest manifest) => _engine.isCompatible(manifest);

  @override
  void validate(PluginManifest manifest) => _engine.checkManifest(manifest);

  @override
  Future<Object?> load(String pluginId, String pluginDir) async {
    _emit(const PluginLifecycleState.loading());
    try {
      await _engine.loadFromDisk(pluginDir);
      _emit(
        PluginLifecycleState.loaded(
          _engine.activeManifest!,
          port: _engine.activePort,
        ),
      );
      return null;
    } on IncompatibleSdkVersionException catch (error) {
      _emit(PluginLifecycleState.incompatible(error.manifest));
      return error;
    } catch (error) {
      _emit(PluginLifecycleState.failure(error));
      return error;
    }
  }

  @override
  Future<void> unload() async {
    await _engine.terminate();
    _emit(const PluginLifecycleState.notConfigured());
  }

  void _emit(PluginLifecycleState state) {
    _state = state;
    if (!_changes.isClosed) _changes.add(state);
  }
}
