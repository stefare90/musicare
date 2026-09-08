import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:musicare_dart_host_sdk/musicare_dart_host_sdk.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AudioSourcePluginEngine {
  final AudioSourceClient _client;
  PluginManifest? _activeManifest;
  String? _activePluginDir;

  AudioSourcePluginEngine({AudioSourceClient? client})
    : _client = client ?? AudioSourceClient();

  int? get activePort => _client.port;
  PluginManifest? get activeManifest => _activeManifest;
  String? get activePluginId => _activeManifest?.id;
  String? get activePluginDir => _activePluginDir;
  bool get isRunning => _client.isStarted && _activeManifest != null;

  Future<bool> isPluginInstalledOnDisk(String pluginId) async {
    final appDir = await getApplicationSupportDirectory();
    final pluginDir = Directory(
      p.join(appDir.path, 'plugins', 'audio_source', pluginId),
    );
    final jsonFile = File(p.join(pluginDir.path, 'plugin.json'));
    return pluginDir.existsSync() && jsonFile.existsSync();
  }

  Future<void> loadFromDisk(String pluginId) async {
    final appDir = await getApplicationSupportDirectory();
    final pluginDir = Directory(
      p.join(appDir.path, 'plugins', 'audio_source', pluginId),
    );
    final jsonFile = File(p.join(pluginDir.path, 'plugin.json'));

    debugPrint('📁 [Engine] Checking disk: ${pluginDir.path}');
    if (!pluginDir.existsSync() || !jsonFile.existsSync()) {
      debugPrint('❌ [Engine] Files not found on disk for $pluginId');
      throw PluginFileNotFoundException(pluginId);
    }

    final manifestMap =
        jsonDecode(jsonFile.readAsStringSync()) as Map<String, dynamic>;
    final manifest = PluginManifest.fromJson(manifestMap);

    if (manifest.pluginType != PluginType.audioSource) {
      throw InvalidPluginTypeException(
        expectedType: 'audioSource',
        actualType: manifest.type,
      );
    }

    _activePluginDir = pluginDir.path;

    // 1. Ensure the fixed SeriousPython host daemon is running
    if (!_client.isStarted) {
      debugPrint('🚀 [Engine] Starting SeriousPython host daemon...');
      await _client.start();
    }

    // 2. Dynamically inject the unzipped plugin into the Python runtime
    debugPrint('🔌 [Engine] Dynamically injecting plugin: ${pluginDir.path}');
    final loadResult = await _client.loadPlugin(pluginDir.path);
    debugPrint(
      '✅ [Engine] Plugin "${loadResult['loaded']}" loaded successfully on port ${_client.port}!',
    );

    _activeManifest = manifest;
  }

  Future<void> loadFromZipBytes(Uint8List zipBytes) async {
    final archive = ZipDecoder().decodeBytes(zipBytes);

    String? jsonContent;
    for (final file in archive) {
      if (file.name == 'plugin.json') {
        jsonContent = utf8.decode(file.content as List<int>);
        break;
      }
    }

    if (jsonContent == null) {
      throw InvalidPluginArchiveException();
    }

    final manifestMap = jsonDecode(jsonContent) as Map<String, dynamic>;
    final manifest = PluginManifest.fromJson(manifestMap);

    if (manifest.pluginType != PluginType.audioSource) {
      throw InvalidPluginTypeException(
        expectedType: 'audioSource',
        actualType: manifest.type,
      );
    }

    final appDir = await getApplicationSupportDirectory();
    final pluginDir = Directory(
      p.join(appDir.path, 'plugins', 'audio_source', manifest.id),
    );

    if (pluginDir.existsSync()) {
      pluginDir.deleteSync(recursive: true);
    }
    pluginDir.createSync(recursive: true);

    for (final file in archive) {
      final filename = p.join(pluginDir.path, file.name);
      if (file.isFile) {
        final outFile = File(filename);
        outFile.createSync(recursive: true);
        outFile.writeAsBytesSync(file.content as List<int>);
      } else {
        Directory(filename).createSync(recursive: true);
      }
    }

    await loadFromDisk(manifest.id);
  }

  Future<List<AudioStreamResponse>> resolveStream(
    Track track, {
    AudioQuality quality = AudioQuality.high,
  }) async {
    if (!isRunning) {
      throw PluginNotLoadedException();
    }

    return _client.getStream(
      title: track.name,
      artists: track.artists.map((a) => a.name).toList(),
      durationMs: track.durationMs,
      quality: quality,
    );
  }

  Future<void> terminate() async {
    if (isRunning) {
      _client.stop();
      _activeManifest = null;
      _activePluginDir = null;
    }
  }
}
