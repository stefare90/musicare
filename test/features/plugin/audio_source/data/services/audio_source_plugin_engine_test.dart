import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/features/player/data/models/resolved_track_playback.dart';
import 'package:music_are/features/plugin/audio_source/data/services/audio_source_plugin_engine.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:musicare_audio_host_sdk/musicare_audio_host_sdk.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart' show Track, Artist, Album, AlbumType;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FakeAudioSourceClient extends Fake implements AudioSourceClient {
  @override
  final Uri baseUri = Uri.parse('http://127.0.0.1:8765');

  String? loadedPluginDir;

  @override
  Future<Map<String, dynamic>> loadPlugin({
    required String pluginDir,
    String moduleName = 'main',
  }) async {
    loadedPluginDir = pluginDir;
    return {'loaded': 'YouTube Audio Source', 'id': 'test', 'version': '1.0.0'};
  }

  @override
  Future<dynamic> call(String method, [Map<String, dynamic>? args]) async {
    switch (method) {
      case 'candidates.search':
        return [
          {'id': 'c1', 'title': 'Test Song', 'artist': 'Artist'},
        ];
      case 'stream.resolve':
        return {'url': 'https://cdn.example.com/audio.m4a', 'quality': 'high'};
      default:
        throw UnimplementedError(method);
    }
  }
}

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final Directory tempDir;
  FakePathProviderPlatform(this.tempDir);

  @override
  Future<String?> getApplicationSupportPath() async => tempDir.path;
}

Uint8List createTestAudioSourceZip({
  String id = 'org.musicare.audiosource.youtube',
  String type = 'audioSource',
  String sdkVersion = packageVersion,
  bool includeJson = true,
}) {
  final archive = Archive();
  if (includeJson) {
    final jsonContent = jsonEncode({
      'id': id,
      'packageId': 'musicare_audiosource_youtube_plugin',
      'type': type,
      'name': 'YouTube Audio Source',
      'version': '1.0.0',
      'pluginSdkVersion': sdkVersion,
      'author': 'MusicAre Team',
      'description': 'Test source',
    });
    final jsonBytes = utf8.encode(jsonContent);
    archive.addFile(ArchiveFile('plugin.json', jsonBytes.length, jsonBytes));
    final pyBytes = utf8.encode('def get_plugin(): pass');
    archive.addFile(ArchiveFile('main.py', pyBytes.length, pyBytes));
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

Track createTestTrack() => Track(
  id: 't1',
  name: 'Test Song',
  externalUri: '',
  artists: [Artist(id: 'a1', name: 'Artist', externalUri: '')],
  album: Album(
    id: 'al1',
    name: 'Album',
    artists: [],
    releaseDate: '',
    externalUri: '',
    totalTracks: 1,
    albumType: AlbumType.single,
  ),
  durationMs: 120000,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioSourcePluginEngine Unit Tests', () {
    late FakeAudioSourceClient client;
    late AudioSourcePluginEngine engine;
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('audio_source_test_');
      PathProviderPlatform.instance = FakePathProviderPlatform(tempDir);
      client = FakeAudioSourceClient();
      engine = AudioSourcePluginEngine(client: client);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('isPluginInstalledOnDisk returns false when files do not exist', () async {
      expect(await engine.isPluginInstalledOnDisk('missing'), isFalse);
    });

    test('loadFromDisk throws PluginFileNotFoundException when missing', () {
      expect(
        () async => await engine.loadFromDisk('missing'),
        throwsA(isA<PluginFileNotFoundException>()),
      );
    });

    test('loadFromZipBytes unpacks the zip and loads the plugin', () async {
      await engine.loadFromZipBytes(createTestAudioSourceZip());

      expect(engine.isRunning, isTrue);
      expect(engine.activePluginId, 'org.musicare.audiosource.youtube');
      expect(engine.activePort, 8765);
      expect(engine.activeManifest?.name, 'YouTube Audio Source');
      expect(client.loadedPluginDir, contains('org.musicare.audiosource.youtube'));
    });

    test('loadFromZipBytes rejects an archive without plugin.json', () {
      expect(
        () async =>
            await engine.loadFromZipBytes(createTestAudioSourceZip(includeJson: false)),
        throwsA(isA<InvalidPluginArchiveException>()),
      );
    });

    test('loadFromZipBytes rejects a non-audioSource manifest', () {
      expect(
        () async =>
            await engine.loadFromZipBytes(createTestAudioSourceZip(type: 'metadata')),
        throwsA(isA<InvalidPluginTypeException>()),
      );
    });

    test('loadFromZipBytes throws IncompatibleSdkVersionException on a mismatch', () {
      expect(
        () async =>
            await engine.loadFromZipBytes(createTestAudioSourceZip(sdkVersion: '9.0.0')),
        throwsA(isA<IncompatibleSdkVersionException>()),
      );
    });

    test('resolveTrack throws PluginNotLoadedException when no plugin is loaded', () {
      expect(
        () async => await engine.resolveTrack(createTestTrack()),
        throwsA(isA<PluginNotLoadedException>()),
      );
    });

    test('audioSource throws PluginNotLoadedException when no plugin is loaded', () {
      expect(() => engine.audioSource, throwsA(isA<PluginNotLoadedException>()));
    });

    test('audioSource exposes the loaded adapter', () async {
      await engine.loadFromZipBytes(createTestAudioSourceZip());

      expect(engine.audioSource, isA<AudioSourcePluginAdapter>());
    });

    test('resolveTrack composes candidates.search and stream.resolve', () async {
      await engine.loadFromZipBytes(createTestAudioSourceZip());

      final ResolvedTrackPlayback playback = await engine.resolveTrack(
        createTestTrack(),
      );

      expect(playback.activeCandidateId, 'c1');
      expect(playback.stream?.url, 'https://cdn.example.com/audio.m4a');
      expect(playback.candidates.single.id, 'c1');
    });

    test('resolveStream returns the resolved stream', () async {
      await engine.loadFromZipBytes(createTestAudioSourceZip());

      final stream = await engine.resolveStream('c2');

      expect(stream.url, 'https://cdn.example.com/audio.m4a');
    });

    test('terminate clears the active plugin state', () async {
      await engine.loadFromZipBytes(createTestAudioSourceZip());
      expect(engine.isRunning, isTrue);

      await engine.terminate();

      expect(engine.isRunning, isFalse);
      expect(engine.activeManifest, isNull);
      expect(engine.activePluginDir, isNull);
    });
  });
}
