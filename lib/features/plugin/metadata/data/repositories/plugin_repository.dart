import 'dart:typed_data';

import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';

class PluginRepository {
  PluginRepository(this._engine);

  final MetadataPluginEngine _engine;

  PluginManifest? get manifest => _engine.metadataManifest;

  Future<bool> isInstalledOnDisk(String pluginId) =>
      _engine.isPluginInstalledOnDisk(pluginId);

  Future<void> loadFromDisk(String pluginId) => _engine.loadFromDisk(pluginId);

  Future<void> loadFromZipBytes(Uint8List bytes) =>
      _engine.loadFromZipBytes(bytes);

  void unload() => _engine.unloadMetadata();
}
