import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:music_are/features/player/data/models/resolved_track_playback.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:musicare_audio_host_sdk/musicare_audio_host_sdk.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart' show Track;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pub_semver/pub_semver.dart';

/// App-level audio source plugin service: installs and keeps the current plugin on disk
/// and exposes it (search/resolve) through [AudioSourcePluginAdapter].
///
/// The Python interpreter lifecycle belongs to `musicare_runtime_host`; this class only
/// owns the plugin directory, the manifest and the SDK adapter built on [AudioSourceClient].
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

  Future<bool> isPluginInstalledOnDisk(String pluginId) async {
    final pluginDir = await _pluginDirPath(pluginId);
    return File(p.join(pluginDir, 'plugin.json')).existsSync();
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
    _checkManifest(manifest);
    await _client.loadPlugin(pluginDir: pluginDir);
    _audioSourcePlugin = AudioSourcePluginAdapter(caller: _client);
    _activePluginDir = pluginDir;
    _activeManifest = manifest;
  }

  Future<void> loadFromZipBytes(Uint8List zipBytes) async {
    final archive = ZipDecoder().decodeBytes(zipBytes);
    PluginManifest? manifest;
    for (final file in archive) {
      if (file.name == 'plugin.json') {
        manifest = PluginManifest.fromJson(
          jsonDecode(utf8.decode(file.content as List<int>))
              as Map<String, dynamic>,
        );
        break;
      }
    }

    if (manifest == null) {
      throw InvalidPluginArchiveException();
    }
    _checkManifest(manifest);

    final pluginDir = Directory(await _pluginDirPath(manifest.id));
    if (pluginDir.existsSync()) {
      pluginDir.deleteSync(recursive: true);
    }
    pluginDir.createSync(recursive: true);

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

    await _client.loadPlugin(pluginDir: pluginDir.path);
    _audioSourcePlugin = AudioSourcePluginAdapter(caller: _client);
    _activePluginDir = pluginDir.path;
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

  /// Temporary composition kept while the player still consumes a single call. The app
  /// orchestrates `candidates.search` and `stream.resolve` itself from 4b on.
  Future<ResolvedTrackPlayback> resolveTrack(
    Track track, {
    AudioQuality quality = AudioQuality.high,
  }) async {
    final plugin = audioSource;

    final candidates = await plugin.searchCandidates(
      title: track.name,
      artists: track.artists.map((a) => a.name).toList(),
      durationMs: track.durationMs,
    );
    if (candidates.isEmpty) {
      return const ResolvedTrackPlayback(
        stream: null,
        candidates: [],
        activeCandidateId: '',
      );
    }

    final stream = await plugin.resolveStream(
      candidateId: candidates.first.id,
      quality: quality,
    );
    return ResolvedTrackPlayback(
      stream: stream,
      candidates: candidates,
      activeCandidateId: candidates.first.id,
    );
  }

  Future<void> terminate() async {
    _audioSourcePlugin = null;
    _activeManifest = null;
    _activePluginDir = null;
  }

  void _checkManifest(PluginManifest manifest) {
    if (manifest.pluginType != PluginType.audioSource) {
      throw InvalidPluginTypeException(
        expectedType: 'audioSource',
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

  Future<String> _pluginDirPath(String pluginId) async {
    final appDir = await getApplicationSupportDirectory();
    return p.join(appDir.path, 'plugins', 'audio_source', pluginId);
  }
}
