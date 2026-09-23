import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pub_semver/pub_semver.dart';

/// App-level metadata plugin service: installs and keeps the current plugin on disk and
/// exposes it as an [IMetadataPlugin] backed by the wire protocol.
///
/// The Python interpreter lifecycle belongs to `musicare_runtime_host`; this class only
/// owns the plugin directory, the manifest and the SDK adapter built on [MetadataClient].
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

  Future<bool> isPluginInstalledOnDisk(String pluginId) async {
    final pluginDir = await _pluginDirPath(pluginId);
    return File(p.join(pluginDir, 'plugin.json')).existsSync() &&
        File(p.join(pluginDir, 'src', 'main.py')).existsSync();
  }

  Future<void> loadFromDisk(String pluginId) async {
    final pluginDir = await _pluginDirPath(pluginId);
    final jsonFile = File(p.join(pluginDir, 'plugin.json'));

    if (!jsonFile.existsSync()) {
      throw PluginFileNotFoundException(pluginId);
    }

    final manifest = PluginManifest.fromJson(
      jsonDecode(jsonFile.readAsStringSync()) as Map<String, dynamic>,
    );
    _checkVersion(manifest);
    await _loadPluginDir(manifest);
  }

  Future<void> loadFromZipBytes(Uint8List zipBytes) async {
    final manifest = _manifestFromZip(zipBytes);
    _checkVersion(manifest);
    await _extractToDisk(manifest, zipBytes);
    await _loadPluginDir(manifest);
  }

  void unloadMetadata() {
    _metadataPlugin = null;
    _metadataManifest = null;
  }

  PluginManifest _manifestFromZip(Uint8List zipBytes) {
    final archive = ZipDecoder().decodeBytes(zipBytes);
    for (final file in archive) {
      if (file.name == 'plugin.json') {
        return PluginManifest.fromJson(
          jsonDecode(utf8.decode(file.content as List<int>))
              as Map<String, dynamic>,
        );
      }
    }
    throw InvalidPluginArchiveException();
  }

  /// The host and the plugin SDK share one version number; a major mismatch rejects the
  /// plugin before it is loaded, so the user sees the update page instead of a crash.
  void _checkVersion(PluginManifest manifest) {
    final hostVersion = Version.parse(packageVersion);
    final pluginVersion = Version.parse(manifest.pluginSdkVersion);
    if (!VersionConstraint.compatibleWith(pluginVersion).allows(hostVersion)) {
      throw IncompatibleSdkVersionException(
        manifest: manifest,
        hostVersion: packageVersion,
      );
    }
  }

  Future<void> _loadPluginDir(PluginManifest manifest) async {
    final pluginDir = await _pluginDirPath(manifest.id);
    await _client.loadPlugin(pluginDir: pluginDir);
    _metadataPlugin = MetadataPluginAdapter(
      caller: _client,
      authPresenter: _authPresenter,
    );
    _metadataManifest = manifest;
  }

  Future<void> _extractToDisk(
    PluginManifest manifest,
    Uint8List zipBytes,
  ) async {
    final pluginDirPath = await _pluginDirPath(manifest.id);
    final pluginDir = Directory(pluginDirPath);
    if (pluginDir.existsSync()) {
      pluginDir.deleteSync(recursive: true);
    }
    pluginDir.createSync(recursive: true);

    final archive = ZipDecoder().decodeBytes(zipBytes);
    for (final file in archive) {
      final filename = p.join(pluginDir.path, file.name);
      if (file.isFile) {
        File(filename)
          ..createSync(recursive: true)
          ..writeAsBytesSync(file.content as List<int>);
      } else {
        Directory(filename).createSync(recursive: true);
      }
    }
  }

  Future<String> _pluginDirPath(String pluginId) async {
    final appDir = await getApplicationSupportDirectory();
    return p.join(appDir.path, 'plugins', 'metadata', pluginId);
  }
}
