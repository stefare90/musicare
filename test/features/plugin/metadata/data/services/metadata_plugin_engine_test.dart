import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';

class FakeMetadataClient extends Fake implements MetadataClient {
  String? loadedPluginDir;

  @override
  Future<Map<String, dynamic>> loadPlugin({
    required String pluginDir,
    String moduleName = 'main',
  }) async {
    loadedPluginDir = pluginDir;
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
      case 'core.support':
        return 'MusicBrainz metadata provider';
      default:
        return null;
    }
  }
}

class FakeAuthPresenter implements MetadataAuthPresenter {
  int promptFormCalls = 0;

  @override
  Future<Map<String, String>?> promptForm({
    String? title,
    String? message,
    required List<FormInputField> fields,
  }) async {
    promptFormCalls++;
    return null;
  }

  @override
  Future<void> openBrowser(String url) async {}
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

      await engine.loadFromDisk(dir);

      expect(engine.hasMetadata, isTrue);
      expect(engine.metadata, isA<MetadataPluginAdapter>());
      expect(engine.metadataManifest!.id, 'org.musicare.metadata.test');
      expect(client.loadedPluginDir, dir);
    });

    test('loadFromDisk throws when plugin.json is missing', () {
      expect(
        () => engine.loadFromDisk('${tempDir.path}/missing'),
        throwsA(isA<PluginFileNotFoundException>()),
      );
    });

    test('loadFromDisk rejects a manifest of another type', () {
      final dir = createPluginDir(tempDir, type: 'audioSource');

      expect(
        () => engine.loadFromDisk(dir),
        throwsA(isA<InvalidPluginTypeException>()),
      );
    });

    test('loadFromDisk rejects an incompatible SDK version', () {
      final dir = createPluginDir(tempDir, sdkVersion: '1.0.0');

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

    test('core.support is exposed through the adapter', () async {
      await engine.loadFromDisk(createPluginDir(tempDir));

      expect(await engine.metadata.core.support(), 'MusicBrainz metadata provider');
    });

    test('loadFromDisk wires the auth presenter into the adapter', () async {
      final presenter = FakeAuthPresenter();
      final engineWithAuth = MetadataPluginEngine(
        client: client,
        authPresenter: presenter,
      );
      await engineWithAuth.loadFromDisk(createPluginDir(tempDir));

      await engineWithAuth.metadata.auth.authenticate();

      expect(presenter.promptFormCalls, 1);
    });

    test('unloadMetadata clears the loaded plugin', () async {
      await engine.loadFromDisk(createPluginDir(tempDir));

      engine.unloadMetadata();

      expect(engine.hasMetadata, isFalse);
      expect(() => engine.metadata, throwsA(isA<PluginNotLoadedException>()));
    });
  });
}
