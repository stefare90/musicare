import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/features/plugin/audio_source/data/services/audio_source_plugin_engine.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:musicare_audio_host_sdk/musicare_audio_host_sdk.dart';

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

String createPluginDir(
  Directory root, {
  String type = 'audioSource',
  String sdkVersion = packageVersion,
  String version = '1.0.0',
}) {
  final dir = Directory('${root.path}/plugin')..createSync(recursive: true);
  File('${dir.path}/plugin.json').writeAsStringSync(
    jsonEncode({
      'id': 'org.musicare.audiosource.youtube',
      'packageId': 'musicare_audiosource_youtube_plugin',
      'type': type,
      'name': 'YouTube Audio Source',
      'version': version,
      'pluginSdkVersion': sdkVersion,
      'author': 'MusicAre Team',
      'description': 'Test source',
    }),
  );
  File('${dir.path}/main.py').writeAsStringSync('def get_plugin(): pass');
  return dir.path;
}

void main() {
  group('AudioSourcePluginEngine Unit Tests', () {
    late FakeAudioSourceClient client;
    late AudioSourcePluginEngine engine;
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('audio_source_test_');
      client = FakeAudioSourceClient();
      engine = AudioSourcePluginEngine(client: client);
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('loadFromDisk loads the plugin from the directory', () async {
      final dir = createPluginDir(tempDir);

      await engine.loadFromDisk(dir);

      expect(engine.isRunning, isTrue);
      expect(engine.activePluginId, 'org.musicare.audiosource.youtube');
      expect(engine.activePort, 8765);
      expect(engine.activeManifest?.name, 'YouTube Audio Source');
      expect(client.loadedPluginDir, dir);
    });

    test('loadFromDisk throws when plugin.json is missing', () {
      expect(
        () => engine.loadFromDisk('${tempDir.path}/missing'),
        throwsA(isA<PluginFileNotFoundException>()),
      );
    });

    test('loadFromDisk rejects a non-audioSource manifest', () {
      final dir = createPluginDir(tempDir, type: 'metadata');

      expect(
        () => engine.loadFromDisk(dir),
        throwsA(isA<InvalidPluginTypeException>()),
      );
    });

    test('loadFromDisk throws on an SDK mismatch', () {
      final dir = createPluginDir(tempDir, sdkVersion: '9.0.0');

      expect(
        () => engine.loadFromDisk(dir),
        throwsA(isA<IncompatibleSdkVersionException>()),
      );
    });

    test('isCompatible reflects the manifest checks', () {
      final dir = createPluginDir(tempDir);
      final manifest = PluginManifest.fromJson(
        jsonDecode(File('$dir/plugin.json').readAsStringSync())
            as Map<String, dynamic>,
      );

      expect(engine.isCompatible(manifest), isTrue);
    });

    test('audioSource throws when no plugin is loaded', () {
      expect(() => engine.audioSource, throwsA(isA<PluginNotLoadedException>()));
    });

    test('searchCandidates delegates to the loaded plugin', () async {
      await engine.loadFromDisk(createPluginDir(tempDir));

      final candidates = await engine.searchCandidates(title: 'Test Song');

      expect(candidates.single.id, 'c1');
    });

    test('resolveStream returns the resolved stream', () async {
      await engine.loadFromDisk(createPluginDir(tempDir));

      final stream = await engine.resolveStream('c2');

      expect(stream.url, 'https://cdn.example.com/audio.m4a');
    });

    test('terminate clears the active plugin state', () async {
      await engine.loadFromDisk(createPluginDir(tempDir));
      expect(engine.isRunning, isTrue);

      await engine.terminate();

      expect(engine.isRunning, isFalse);
      expect(engine.activeManifest, isNull);
      expect(engine.activePluginDir, isNull);
    });
  });
}
