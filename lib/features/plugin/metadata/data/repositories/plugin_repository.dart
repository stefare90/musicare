import 'dart:typed_data';

import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';

/// Data access for the plugin lifecycle (install, load, unload, manifest).
///
/// Limited scope on purpose: it exposes only the lifecycle methods, never the
/// loaded `IMetadataPlugin` — that is the job of the other repositories.
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
