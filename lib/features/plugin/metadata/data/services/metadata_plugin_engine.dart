import 'dart:convert';
import 'dart:io';

import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

class MetadataPluginEngine {
  final MetadataClient _client;
  final MetadataAuthPresenter? _authPresenter;
  IMetadataPlugin? _metadataPlugin;
  PluginManifest? _metadataManifest;

  MetadataPluginEngine({required this._client, this._authPresenter});

  IMetadataPlugin get metadata {
    final plugin = _metadataPlugin;
    if (plugin == null) {
      throw PluginNotLoadedException();
    }
    return plugin;
  }

  bool get hasMetadata => _metadataPlugin != null;
  PluginManifest? get metadataManifest => _metadataManifest;

  bool isCompatible(PluginManifest manifest) {
    try {
      checkManifest(manifest);
      return true;
    } on PluginException {
      return false;
    }
  }

  Future<void> loadFromDisk(String pluginDir) async {
    final jsonFile = File(p.join(pluginDir, 'plugin.json'));
    if (!jsonFile.existsSync()) {
      throw PluginFileNotFoundException(pluginDir);
    }

    final manifest = PluginManifest.fromJson(
      jsonDecode(jsonFile.readAsStringSync()) as Map<String, dynamic>,
    );
    checkManifest(manifest);
    await _loadPluginDir(manifest, pluginDir);
  }

  void unloadMetadata() {
    _metadataPlugin = null;
    _metadataManifest = null;
  }

  void checkManifest(PluginManifest manifest) {
    if (manifest.pluginType != PluginType.metadata) {
      throw InvalidPluginTypeException(
        expectedType: PluginType.metadata.name,
        actualType: manifest.type,
      );
    }

    final hostVersion = Version.parse(packageVersion);
    final pluginVersion = Version.parse(manifest.pluginSdkVersion);
    if (!VersionConstraint.compatibleWith(pluginVersion).allows(hostVersion)) {
      throw IncompatibleSdkVersionException(
        manifest: manifest,
        hostVersion: packageVersion,
      );
    }
  }

  Future<void> _loadPluginDir(
    PluginManifest manifest,
    String pluginDir,
  ) async {
    await _client.loadPlugin(pluginDir: pluginDir);
    _metadataPlugin = MetadataPluginAdapter(
      caller: _client,
      authPresenter: _authPresenter,
    );
    _metadataManifest = manifest;
  }
}
