import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';

ListenEvent testListenEvent() {
  return ListenEvent(
    kind: ListenKind.playingNow,
    track: Track(
      id: 'recording',
      name: 'Karma Police',
      externalUri: '',
      artists: [Artist(id: 'artist', name: 'Radiohead', externalUri: '')],
      album: Album(
        id: 'release-group',
        name: 'OK Computer',
        artists: const [],
        releaseDate: '',
        externalUri: '',
        totalTracks: 12,
        albumType: AlbumType.album,
      ),
      durationMs: 261000,
    ),
  );
}

class FakeMetadataClient extends Fake implements MetadataClient {
  String? loadedCodeDir;
  String? loadedDataDir;
  Object? listenError;

  @override
  Future<Map<String, dynamic>> loadPlugin({
    required String codeDir,
    required String dataDir,
    String moduleName = 'main',
  }) async {
    loadedCodeDir = codeDir;
    loadedDataDir = dataDir;
    return {'loaded': 'Test Plugin', 'id': 'test', 'version': '1.0.0'};
  }

  @override
  Future<dynamic> call(String method, [Map<String, dynamic>? args]) async {
    switch (method) {
      case 'auth.start':
        return {
          'state': 'needs_form',
          'fields': [
            {'id': 'token', 'label': 'Token', 'is_password': true},
          ],
        };
      case 'listen.record':
        if (listenError != null) throw listenError!;
        return null;
      default:
        return null;
    }
  }
}

String createPluginDir(
  Directory root, {
  String type = 'metadata',
  String sdkVersion = packageVersion,
  String version = '1.0.0',
}) {
  final dir = Directory('${root.path}/plugin')..createSync(recursive: true);
  File('${dir.path}/plugin.json').writeAsStringSync(
    jsonEncode({
      'id': 'org.musicare.metadata.test',
      'packageId': 'musicare_metadata_test_plugin',
      'type': type,
      'name': 'Test Plugin',
      'version': version,
      'pluginSdkVersion': sdkVersion,
      'author': 'Test Author',
      'description': 'Test Plugin Description',
    }),
  );
  Directory('${dir.path}/src').createSync(recursive: true);
  File('${dir.path}/src/main.py')
      .writeAsStringSync('def get_plugin():\n    return None\n');
  return dir.path;
}

void main() {
  group('MetadataPluginEngine Unit Tests', () {
    late FakeMetadataClient client;
    late MetadataPluginEngine engine;
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('metadata_engine_test_');
      client = FakeMetadataClient();
      engine = MetadataPluginEngine(client: client);
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('loadFromDisk loads the manifest and the runtime', () async {
      final dir = createPluginDir(tempDir);

      await engine.loadFromDisk(codeDir: dir, dataDir: '${tempDir.path}/data');

      expect(engine.hasMetadata, isTrue);
      expect(engine.metadata, isA<MetadataPluginAdapter>());
      expect(engine.metadataManifest!.id, 'org.musicare.metadata.test');
      expect(client.loadedCodeDir, dir);
      expect(client.loadedDataDir, '${tempDir.path}/data');
    });

    test('loadFromDisk throws when plugin.json is missing', () {
      expect(
        () => engine.loadFromDisk(codeDir: '${tempDir.path}/missing', dataDir: '${tempDir.path}/data'),
        throwsA(isA<PluginFileNotFoundException>()),
      );
    });

    test('loadFromDisk rejects a manifest of another type', () {
      final dir = createPluginDir(tempDir, type: 'audioSource');

      expect(
        () => engine.loadFromDisk(codeDir: dir, dataDir: '${tempDir.path}/data'),
        throwsA(isA<InvalidPluginTypeException>()),
      );
    });

    test('loadFromDisk rejects an incompatible SDK version', () {
      final dir = createPluginDir(tempDir, sdkVersion: '1.0.0');

      expect(
        () => engine.loadFromDisk(codeDir: dir, dataDir: '${tempDir.path}/data'),
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
      expect(
        engine.isCompatible(
          PluginManifest.fromJson({
            'id': 'x',
            'packageId': 'x',
            'type': 'audioSource',
            'name': 'x',
            'version': '1.0.0',
            'pluginSdkVersion': packageVersion,
            'author': 'x',
            'description': 'x',
          }),
        ),
        isFalse,
      );
    });

    test('listen.record is exposed through the adapter', () async {
      await engine.loadFromDisk(
        codeDir: createPluginDir(tempDir),
        dataDir: '${tempDir.path}/data',
      );

      await engine.metadata.listen.record(testListenEvent());
    });

    test('unloadMetadata clears the loaded plugin', () async {
      await engine.loadFromDisk(
        codeDir: createPluginDir(tempDir),
        dataDir: '${tempDir.path}/data',
      );

      engine.unloadMetadata();

      expect(engine.hasMetadata, isFalse);
      expect(() => engine.metadata, throwsA(isA<PluginNotLoadedException>()));
    });
  });
}
