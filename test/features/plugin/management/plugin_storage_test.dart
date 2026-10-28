import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/plugin/shared/data/services/plugin_storage.dart';

Uint8List pluginZip({
  String id = 'org.musicare.metadata.test',
  String type = 'metadata',
  String version = '1.0.0',
}) {
  final archive = Archive();
  final jsonBytes = utf8.encode(
    jsonEncode({
      'id': id,
      'packageId': 'test_plugin',
      'type': type,
      'name': 'Test Plugin',
      'version': version,
      'pluginSdkVersion': '6.0.0',
      'author': 'Tester',
      'description': 'Test',
    }),
  );
  archive.addFile(ArchiveFile('plugin.json', jsonBytes.length, jsonBytes));
  final mainBytes = utf8.encode('def get_plugin(): pass');
  archive.addFile(ArchiveFile('src/main.py', mainBytes.length, mainBytes));
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

void main() {
  late Directory tempDir;
  late PluginStorage storage;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('plugin_storage_test_');
    storage = PluginStorage(appDir: () async => tempDir);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('installed reads plugin.json for the given id', () async {
    final dir = Directory('${tempDir.path}/plugins/metadata/test.plugin')
      ..createSync(recursive: true);
    File('${dir.path}/plugin.json').writeAsStringSync(
      jsonEncode({
        'id': 'test.plugin',
        'packageId': 'test_plugin',
        'type': 'metadata',
        'name': 'Plugin',
        'version': '1.0.0',
        'pluginSdkVersion': '6.0.0',
        'author': 'Tester',
        'description': 'Test',
      }),
    );

    final manifest = await storage.installed(
      PluginType.metadata,
      'test.plugin',
    );

    expect(manifest?.id, 'test.plugin');
  });

  test('installed returns null when the manifest is missing', () async {
    expect(await storage.installed(PluginType.metadata, 'missing'), isNull);
  });

  test('install extracts the archive and commit removes the backup', () async {
    var validated = false;
    final manifest = await storage.install(
      PluginType.metadata,
      pluginZip(version: '1.0.0'),
      validate: (_) => validated = true,
    );

    expect(validated, isTrue);
    expect(manifest.version, '1.0.0');
    expect(
      File(
        '${tempDir.path}/plugins/metadata/${manifest.id}/plugin.json',
      ).existsSync(),
      isTrue,
    );

    await storage.install(
      PluginType.metadata,
      pluginZip(version: '2.0.0'),
      validate: (_) {},
    );
    final backup = Directory(
      '${tempDir.path}/plugins/metadata/${manifest.id}.bak',
    );
    expect(backup.existsSync(), isTrue);

    await storage.commit(PluginType.metadata, manifest.id);
    expect(backup.existsSync(), isFalse);
  });

  test('rollback restores the previous code', () async {
    final manifest = await storage.install(
      PluginType.metadata,
      pluginZip(version: '1.0.0'),
      validate: (_) {},
    );
    await storage.install(
      PluginType.metadata,
      pluginZip(version: '2.0.0'),
      validate: (_) {},
    );

    await storage.rollback(PluginType.metadata, manifest.id);

    final json = File(
      '${tempDir.path}/plugins/metadata/${manifest.id}/plugin.json',
    ).readAsStringSync();
    expect(json, contains('"version":"1.0.0"'));
  });

  test('rollback removes a newly installed id without a backup', () async {
    final manifest = await storage.install(
      PluginType.metadata,
      pluginZip(id: 'new.plugin'),
      validate: (_) {},
    );

    await storage.rollback(PluginType.metadata, manifest.id);

    expect(
      Directory('${tempDir.path}/plugins/metadata/${manifest.id}').existsSync(),
      isFalse,
    );
  });

  test('install rejects a manifest of the wrong type', () async {
    await expectLater(
      storage.install(
        PluginType.audioSource,
        pluginZip(type: 'metadata'),
        validate: (_) {},
      ),
      throwsA(isA<InvalidPluginTypeException>()),
    );
  });

  test('an invalid archive leaves the installed code untouched', () async {
    final manifest = await storage.install(
      PluginType.metadata,
      pluginZip(version: '1.0.0'),
      validate: (_) {},
    );

    await expectLater(
      storage.install(
        PluginType.metadata,
        Uint8List.fromList([1, 2, 3]),
        validate: (_) {},
      ),
      throwsA(isA<Exception>()),
    );

    final json = File(
      '${tempDir.path}/plugins/metadata/${manifest.id}/plugin.json',
    ).readAsStringSync();
    expect(json, contains('"version":"1.0.0"'));
  });

  test('removeCodeDir does not touch the plugin data directory', () async {
    final manifest = await storage.install(
      PluginType.metadata,
      pluginZip(),
      validate: (_) {},
    );
    final dataDir = Directory('${tempDir.path}/data/plugins/metadata/${manifest.id}')
      ..createSync(recursive: true);
    File('${dataDir.path}/auth.json').writeAsStringSync('{"token":"x"}');

    await storage.removeCodeDir(PluginType.metadata, manifest.id);

    expect(
      Directory('${tempDir.path}/plugins/metadata/${manifest.id}').existsSync(),
      isFalse,
    );
    expect(File('${dataDir.path}/auth.json').existsSync(), isTrue);
  });
}
