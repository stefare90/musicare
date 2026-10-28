import 'dart:typed_data';

import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';

abstract interface class PluginCatalog {
  Future<Map<String, PluginManifest>> latest(
    PluginType type, {
    bool forceRefresh = false,
  });

  Future<Uint8List> download(PluginManifest manifest);
}
