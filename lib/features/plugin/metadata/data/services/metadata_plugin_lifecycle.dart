import 'dart:async';

import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';
import 'package:music_are/features/plugin/shared/data/capabilities/plugin_lifecycle.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/plugin/shared/data/services/plugin_storage.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';

class MetadataPluginLifecycle implements PluginLifecycle {
  MetadataPluginLifecycle(this._engine, this._storage);

  final MetadataPluginEngine _engine;
  final PluginStorage _storage;
  final StreamController<PluginLifecycleState> _changes =
      StreamController<PluginLifecycleState>.broadcast();
  PluginLifecycleState _state = const PluginLifecycleState.notConfigured();

  @override
  PluginType get type => PluginType.metadata;

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
  Future<Object?> load(String pluginId, String codeDir) async {
    _emit(const PluginLifecycleState.loading());
    try {
      await _engine.loadFromDisk(
        codeDir: codeDir,
        dataDir: (await _storage.dataDir(PluginType.metadata, pluginId)).path,
      );
      _emit(PluginLifecycleState.loaded(_engine.metadataManifest!));
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
    _engine.unloadMetadata();
    _emit(const PluginLifecycleState.notConfigured());
  }

  void _emit(PluginLifecycleState state) {
    _state = state;
    if (!_changes.isClosed) _changes.add(state);
  }
}
