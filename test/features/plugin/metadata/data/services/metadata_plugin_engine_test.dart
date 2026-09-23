import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

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
  Future<Map<String, String>?> promptForm(List<FormInputField> fields) async {
    promptFormCalls++;
    return null;
  }

  @override
  Future<void> openBrowser(String url) async {}
}

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final Directory tempDir;
  FakePathProviderPlatform(this.tempDir);

  @override
  Future<String?> getApplicationSupportPath() async => tempDir.path;
}

Uint8List createTestPluginZip({
  String sdkVersion = packageVersion,
  String pluginId = 'org.musicare.metadata.test',
  bool includeJson = true,
}) {
  final archive = Archive();

  if (includeJson) {
    final jsonBytes = utf8.encode(
      jsonEncode({
        'id': pluginId,
        'packageId': 'musicare_metadata_test_plugin',
        'type': 'metadata',
        'name': 'Test Plugin',
        'version': '1.0.0',
        'pluginSdkVersion': sdkVersion,
        'author': 'Test Author',
        'description': 'Test Plugin Description',
      }),
    );
    archive.addFile(ArchiveFile('plugin.json', jsonBytes.length, jsonBytes));
    final entryBytes = utf8.encode('def get_plugin():\n    return None\n');
    archive.addFile(
      ArchiveFile('src/main.py', entryBytes.length, entryBytes),
    );
  }

  return Uint8List.fromList(ZipEncoder().encode(archive));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MetadataPluginEngine Unit Tests', () {
    late FakeMetadataClient client;
    late MetadataPluginEngine engine;
    late Directory tempDirectory;

    setUp(() {
      tempDirectory = Directory.systemTemp.createTempSync(
        'metadata_plugin_engine_test_',
      );
      PathProviderPlatform.instance = FakePathProviderPlatform(tempDirectory);
      client = FakeMetadataClient();
      engine = MetadataPluginEngine(client: client);
    });

    tearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    test('accessing metadata when unloaded throws PluginNotLoadedException', () {
      expect(engine.hasMetadata, isFalse);
      expect(() => engine.metadata, throwsA(isA<PluginNotLoadedException>()));
    });

    test('loadFromDisk throws PluginFileNotFoundException when missing', () {
      expect(
        () async => await engine.loadFromDisk('missing'),
        throwsA(isA<PluginFileNotFoundException>()),
      );
    });

    test('loadFromZipBytes extracts the plugin and loads it into the runtime', () async {
      await engine.loadFromZipBytes(createTestPluginZip());

      expect(engine.hasMetadata, isTrue);
      expect(engine.metadata, isA<MetadataPluginAdapter>());
      expect(engine.metadataManifest!.id, 'org.musicare.metadata.test');
      expect(client.loadedPluginDir, isNotNull);
      expect(
        await engine.isPluginInstalledOnDisk('org.musicare.metadata.test'),
        isTrue,
      );
    });

    test('loadFromZipBytes rejects an archive without plugin.json', () {
      expect(
        () async =>
            await engine.loadFromZipBytes(createTestPluginZip(includeJson: false)),
        throwsA(isA<InvalidPluginArchiveException>()),
      );
    });

    test('core.support is exposed through the adapter as an async call', () async {
      await engine.loadFromZipBytes(createTestPluginZip());

      final support = engine.metadata.core.support();

      expect(support, isA<Future<String>>());
      expect(await support, 'MusicBrainz metadata provider');
    });

    test(
      'loadFromZipBytes wires the auth presenter into the adapter',
      () async {
        final presenter = FakeAuthPresenter();
        final engineWithAuth = MetadataPluginEngine(
          client: client,
          authPresenter: presenter,
        );
        await engineWithAuth.loadFromZipBytes(createTestPluginZip());

        await engineWithAuth.metadata.auth.authenticate();

        expect(presenter.promptFormCalls, 1);
      },
    );

    test(
      'loadFromZipBytes throws IncompatibleSdkVersionException on a major mismatch',
      () {
        expect(
          () async =>
              await engine.loadFromZipBytes(createTestPluginZip(sdkVersion: '1.0.0')),
          throwsA(isA<IncompatibleSdkVersionException>()),
        );
      },
    );
  });
}
