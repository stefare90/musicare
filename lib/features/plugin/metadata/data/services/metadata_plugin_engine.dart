import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:get_it/get_it.dart';
import 'package:gyawun_metadata_sdk/eval/eval_loader.dart';
import 'package:gyawun_metadata_sdk/eval/eval_plugin.dart';
import 'package:gyawun_metadata_sdk/metadata/host_env.dart';
import 'package:gyawun_metadata_sdk/metadata/interfaces/imetadata_plugin.dart';
import 'package:gyawun_metadata_sdk/metadata/interfaces/inetwork_service.dart';
import 'package:gyawun_metadata_sdk/metadata/interfaces/istorage_service.dart';
import 'package:gyawun_metadata_sdk/metadata/interfaces/iui_service.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pub_semver/pub_semver.dart';

class MetadataPluginEngine {
  IMetadataPlugin? _metadataPlugin;
  PluginManifest? _metadataManifest;

  IMetadataPlugin get metadata {
    if (_metadataPlugin == null) {
      throw PluginNotLoadedException();
    }
    return _metadataPlugin!;
  }

  bool get hasMetadata => _metadataPlugin != null;
  PluginManifest? get metadataManifest => _metadataManifest;

  Future<bool> isPluginInstalledOnDisk(String pluginId) async {
    final appDir = await getApplicationSupportDirectory();
    final jsonFile = File(
      p.join(appDir.path, 'plugins', 'metadata', pluginId, 'plugin.json'),
    );
    final evcFile = File(
      p.join(appDir.path, 'plugins', 'metadata', pluginId, 'plugin.evc'),
    );
    return jsonFile.existsSync() && evcFile.existsSync();
  }

  Future<void> loadFromDisk(String pluginId) async {
    final appDir = await getApplicationSupportDirectory();
    final jsonFile = File(
      p.join(appDir.path, 'plugins', 'metadata', pluginId, 'plugin.json'),
    );
    final evcFile = File(
      p.join(appDir.path, 'plugins', 'metadata', pluginId, 'plugin.evc'),
    );

    if (!jsonFile.existsSync() || !evcFile.existsSync()) {
      throw PluginFileNotFoundException(pluginId);
    }

    final jsonContent = jsonFile.readAsStringSync();
    final evcBytes = evcFile.readAsBytesSync();

    await _initializeRuntime(jsonContent, evcBytes);
  }

  Future<void> loadFromZipBytes(Uint8List zipBytes) async {
    final archive = ZipDecoder().decodeBytes(zipBytes);

    String? jsonContent;
    Uint8List? evcBytes;

    for (final file in archive) {
      if (file.name == 'plugin.json') {
        jsonContent = utf8.decode(file.content as List<int>);
      } else if (file.name == 'plugin.evc') {
        evcBytes = Uint8List.fromList(file.content as List<int>);
      }
    }

    if (jsonContent == null || evcBytes == null) {
      throw InvalidPluginArchiveException();
    }

    final manifestMap = jsonDecode(jsonContent) as Map<String, dynamic>;
    final manifest = PluginManifest.fromJson(manifestMap);

    await _saveToDisk(manifest.id, jsonContent, evcBytes);
    await _initializeRuntime(jsonContent, evcBytes);
  }

  Future<void> _initializeRuntime(
    String jsonContent,
    Uint8List evcBytes,
  ) async {
    final manifestMap = jsonDecode(jsonContent) as Map<String, dynamic>;
    final manifest = PluginManifest.fromJson(manifestMap);

    final hostVersion = Version.parse(HostEnv.sdkVersion);
    final pluginVersion = Version.parse(manifest.pluginSdkVersion);

    final sdkConstraint = VersionConstraint.compatibleWith(pluginVersion);

    if (!sdkConstraint.allows(hostVersion)) {
      throw IncompatibleSdkVersionException(
        manifest: manifest,
        hostVersion: HostEnv.sdkVersion,
      );
    }

    final runtime = Runtime(
      evcBytes.buffer.asByteData(
        evcBytes.offsetInBytes,
        evcBytes.lengthInBytes,
      ),
    );
    runtime.addPlugin(GyawunMetadataSdkPlugin());

    final sl = GetIt.instance;
    final hostEnv = HostEnv(
      network: sl<INetworkService>(),
      storage: sl<IStorageService>(),
      ui: sl<IUIService>(),
    );

    _metadataPlugin = loadPluginFromRuntime(
      runtime: runtime,
      packageId: manifest.packageId,
      hostEnv: hostEnv,
    );
    _metadataManifest = manifest;
  }

  Future<void> _saveToDisk(
    String pluginId,
    String jsonContent,
    Uint8List evcBytes,
  ) async {
    final appDir = await getApplicationSupportDirectory();
    final pluginDir = Directory(
      p.join(appDir.path, 'plugins', 'metadata', pluginId),
    );

    if (!pluginDir.existsSync()) {
      pluginDir.createSync(recursive: true);
    }

    File(p.join(pluginDir.path, 'plugin.json')).writeAsStringSync(jsonContent);
    File(p.join(pluginDir.path, 'plugin.evc')).writeAsBytesSync(evcBytes);
  }

  void unloadMetadata() {
    _metadataPlugin = null;
    _metadataManifest = null;
  }
}
