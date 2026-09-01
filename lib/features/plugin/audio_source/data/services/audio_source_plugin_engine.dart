import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:music_are/features/plugin/audio_source/data/models/audio_quality.dart';
import 'package:music_are/features/plugin/audio_source/data/models/audio_stream_response.dart';
import 'package:music_are/features/plugin/audio_source/data/services/audio_source_client.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:serious_python/serious_python.dart';

class AudioSourcePluginEngine {
  final AudioSourceClient _client;
  PluginManifest? _activeManifest;

  AudioSourcePluginEngine({AudioSourceClient? client})
    : _client = client ?? AudioSourceClient();

  int? get activePort => _client.port;
  PluginManifest? get activeManifest => _activeManifest;
  String? get activePluginId => _activeManifest?.id;
  bool get isRunning => _client.isConfigured && _activeManifest != null;

  Future<int> getUnusedPort() async {
    final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = socket.port;
    await socket.close();
    return port;
  }

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

    if (!pluginDir.existsSync() || !jsonFile.existsSync()) {
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

    await terminate();

    final port = await getUnusedPort();
    _client.setPort(port);

    final entryPointPath = p.join(pluginDir.path, 'src', 'main.py');
    Directory.current = pluginDir;

    SeriousPython.runProgram(
      entryPointPath,
      modulePaths: [pluginDir.path],
      environmentVariables: {'PORT': port.toString()},
      sync: false,
    );

    final isReady = await _waitForServerReady();
    if (!isReady) {
      await terminate();
      throw AudioSourceDaemonStartupTimeoutException(port);
    }

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

  Future<bool> _waitForServerReady({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < timeout) {
      final isReady = await _client.ping();
      if (isReady) return true;
      await Future.delayed(const Duration(milliseconds: 250));
    }
    return false;
  }

  Future<List<AudioStreamResponse>> resolveStream(
    Track track, {
    AudioQuality quality = AudioQuality.high,
  }) async {
    if (!isRunning) {
      throw PluginNotLoadedException();
    }
    return _client.getStream(track: track, quality: quality);
  }

  Future<void> terminate() async {
    if (isRunning || _client.isConfigured) {
      try {
        SeriousPython.terminate();
      } catch (_) {}
      _client.reset();
      _activeManifest = null;
    }
  }
}
