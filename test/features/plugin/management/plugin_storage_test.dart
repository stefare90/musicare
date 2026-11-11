import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/plugin/shared/data/services/plugin_storage.dart';

import '../../../helpers/plugin_archive.dart';

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

  String codeDir(String id, String versionDir, {String type = 'metadata'}) =>
      '${tempDir.path}/plugins/$type/$id/$versionDir';

  String idDir(String id, {String type = 'metadata'}) =>
      '${tempDir.path}/plugins/$type/$id';

  test('installed reads plugin.json of the requested version', () async {
    final dir = Directory(codeDir('test.plugin', '1.0.0'))
      ..createSync(recursive: true);
    File('${dir.path}/plugin.json').writeAsStringSync(
      jsonEncode({
        'id': 'test.plugin',
        'packageId': 'test_plugin',
        'type': 'metadata',
        'name': 'Test',
        'version': '1.0.0',
        'pluginSdkVersion': '6.0.0',
        'author': 'Tester',
        'description': 'Test',
      }),
    );

    final manifest = await storage.installed(
      PluginType.metadata,
      'test.plugin',
      '1.0.0',
    );

    expect(manifest?.id, 'test.plugin');
    expect(
      await storage.installed(PluginType.metadata, 'test.plugin', '9.9.9'),
      isNull,
    );
    expect(await storage.installed(PluginType.metadata, 'missing', '1.0.0'), isNull);
  });

  test('install extracts into a versioned directory and removes the staging', () async {
    var validated = false;
    final installed = await storage.install(
      PluginType.metadata,
      pluginZip(version: '1.0.0'),
      validate: (_) => validated = true,
    );

    expect(validated, isTrue);
    expect(installed.versionDir, '1.0.0');
    expect(
      File('${codeDir(installed.manifest.id, '1.0.0')}/plugin.json').existsSync(),
      isTrue,
    );
    expect(
      Directory('${codeDir(installed.manifest.id, '1.0.0')}.new').existsSync(),
      isFalse,
    );
  });

  test('installing another version leaves the previous one untouched', () async {
    final first = await storage.install(
      PluginType.metadata,
      pluginZip(version: '1.0.0'),
      validate: (_) {},
    );
    final firstFile = File(
      '${codeDir(first.manifest.id, '1.0.0')}/plugin.json',
    );
    final firstBytes = firstFile.readAsStringSync();

    final second = await storage.install(
      PluginType.metadata,
      pluginZip(version: '2.0.0'),
      validate: (_) {},
    );

    expect(second.versionDir, '2.0.0');
    expect(firstFile.existsSync(), isTrue);
    expect(firstFile.readAsStringSync(), firstBytes);
  });

  test('reinstalling the same version takes a new path, never the live one', () async {
    final first = await storage.install(
      PluginType.metadata,
      pluginZip(version: '1.0.0'),
      validate: (_) {},
    );
    final firstFile = File(
      '${codeDir(first.manifest.id, '1.0.0')}/plugin.json',
    );
    final firstBytes = firstFile.readAsStringSync();

    final second = await storage.install(
      PluginType.metadata,
      pluginZip(version: '1.0.0'),
      validate: (_) {},
    );

    expect(second.versionDir, '1.0.0-2');
    expect(firstFile.readAsStringSync(), firstBytes);
    expect(
      File('${codeDir(first.manifest.id, '1.0.0-2')}/plugin.json').existsSync(),
      isTrue,
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

    expect(Directory('${tempDir.path}/plugins').existsSync(), isFalse);
  });

  test('an invalid archive leaves the installed code untouched', () async {
    final installed = await storage.install(
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
      '${codeDir(installed.manifest.id, '1.0.0')}/plugin.json',
    ).readAsStringSync();
    expect(json, contains('"version":"1.0.0"'));
  });

  test('prune keeps the active version and data, drops the rest', () async {
    Directory(codeDir('org.example', '1.0.0')).createSync(recursive: true);
    Directory(codeDir('org.example', '2.0.0')).createSync(recursive: true);
    final auth = File('${idDir('org.example')}/auth.json')
      ..writeAsStringSync('{"token":"x"}');
    Directory(codeDir('old.example', '3.0.0')).createSync(recursive: true);
    final oldAuth = File('${idDir('old.example')}/auth.json')
      ..writeAsStringSync('{"token":"old"}');

    final removed = await storage.prune(
      keep: {
        storage.versionDirKey(PluginType.metadata, 'org.example', '2.0.0'),
      },
    );

    expect(
      removed.map((d) => d.path).toSet(),
      {
        codeDir('org.example', '1.0.0'),
        idDir('old.example'),
      },
    );
    expect(Directory(codeDir('org.example', '2.0.0')).existsSync(), isTrue);
    expect(auth.existsSync(), isTrue);
    expect(Directory(idDir('old.example')).existsSync(), isFalse);
    expect(oldAuth.existsSync(), isFalse);
  });

  test('prune removes the leftovers of an interrupted install', () async {
    Directory(codeDir('org.example', '1.0.0')).createSync(recursive: true);
    final leftover = Directory('${codeDir('org.example', '2.0.0')}.new')
      ..createSync(recursive: true);

    await storage.prune(
      keep: {
        storage.versionDirKey(PluginType.metadata, 'org.example', '1.0.0'),
      },
    );

    expect(leftover.existsSync(), isFalse);
  });

  test('prune leaves files alone: only directories are removed', () async {
    Directory(codeDir('org.example', '1.0.0')).createSync(recursive: true);
    final dataFile = File('${idDir('org.example')}/auth.json')
      ..writeAsStringSync('{"token":"x"}');
    final stray = File('${tempDir.path}/plugins/metadata/notes.txt')
      ..writeAsStringSync('keep me');

    await storage.prune(
      keep: {
        storage.versionDirKey(PluginType.metadata, 'org.example', '1.0.0'),
      },
    );

    expect(dataFile.existsSync(), isTrue);
    expect(stray.existsSync(), isTrue);
  });

  test('prune removes an id with no active version entirely', () async {
    Directory(codeDir('gone.example', '1.0.0')).createSync(recursive: true);
    File('${idDir('gone.example')}/auth.json').writeAsStringSync(
      '{"token":"x"}',
    );

    final removed = await storage.prune(keep: const {});

    expect(Directory(idDir('gone.example')).existsSync(), isFalse);
    expect(removed.map((d) => d.path), [idDir('gone.example')]);
  });

  test('prune does nothing when the store does not exist', () async {
    expect(await storage.prune(keep: const {}), isEmpty);
  });
}
