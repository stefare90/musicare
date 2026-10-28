import 'dart:convert';
import 'dart:io';

import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:musicare_audio_host_sdk/musicare_audio_host_sdk.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

class AudioSourcePluginEngine {
  final AudioSourceClient _client;
  IAudioSourcePlugin? _audioSourcePlugin;
  PluginManifest? _activeManifest;
  String? _activePluginDir;

  AudioSourcePluginEngine({required this._client});

  IAudioSourcePlugin get audioSource {
    final plugin = _audioSourcePlugin;
    if (plugin == null) {
      throw PluginNotLoadedException();
    }
    return plugin;
  }

  int? get activePort => _client.baseUri.port;
  PluginManifest? get activeManifest => _activeManifest;
  String? get activePluginId => _activeManifest?.id;
  String? get activePluginDir => _activePluginDir;
  bool get isRunning => _audioSourcePlugin != null;

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
    await _client.loadPlugin(pluginDir: pluginDir);
    _audioSourcePlugin = AudioSourcePluginAdapter(caller: _client);
    _activePluginDir = pluginDir;
    _activeManifest = manifest;
  }

  Future<List<CandidateTrack>> searchCandidates({
    required String title,
    List<String> artists = const [],
    int durationMs = 0,
  }) => audioSource.searchCandidates(
    title: title,
    artists: artists,
    durationMs: durationMs,
  );

  Future<AudioStreamResponse> resolveStream(
    String candidateId, {
    AudioQuality quality = AudioQuality.high,
  }) => audioSource.resolveStream(candidateId: candidateId, quality: quality);

  Future<void> terminate() async {
    _audioSourcePlugin = null;
    _activeManifest = null;
    _activePluginDir = null;
  }

  void checkManifest(PluginManifest manifest) {
    if (manifest.pluginType != PluginType.audioSource) {
      throw InvalidPluginTypeException(
        expectedType: PluginType.audioSource.name,
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
}
