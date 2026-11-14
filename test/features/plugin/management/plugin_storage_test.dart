import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/plugin/shared/data/services/plugin_storage.dart';

import '../../../helpers/plugin_archive.dart';

void main() {
  const prefix = 'plugin_version_';

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

  String versionDir(String id, String version, {String type = 'metadata'}) =>
      codeDir(id, '$prefix$version', type: type);

  String dataDir(String id, {String type = 'metadata'}) =>
      '${tempDir.path}/plugins/$type/$id/data';

  String idDir(String id, {String type = 'metadata'}) =>
      '${tempDir.path}/plugins/$type/$id';

  test('installed reads plugin.json of the requested version', () async {
    final dir = Directory(versionDir('test.plugin', '1.0.0'))
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
      '${prefix}1.0.0',
    );

    expect(manifest?.id, 'test.plugin');
    expect(
      await storage.installed(PluginType.metadata, 'test.plugin', '9.9.9'),
      isNull,
    );
    expect(await storage.installed(PluginType.metadata, 'missing', '1.0.0'), isNull);
  });

  test('codeDir still resolves a pre-prefix version name', () async {
    final legacy = Directory(codeDir('test.plugin', '4.0.1'))
      ..createSync(recursive: true);
    File('${legacy.path}/plugin.json').writeAsStringSync(
      jsonEncode({
        'id': 'test.plugin',
        'packageId': 'test_plugin',
        'type': 'metadata',
        'name': 'Test',
        'version': '4.0.1',
        'pluginSdkVersion': '6.0.0',
        'author': 'Tester',
        'description': 'Test',
      }),
    );

    expect(
      await storage.codeDir(PluginType.metadata, 'test.plugin', '4.0.1'),
      codeDir('test.plugin', '4.0.1'),
    );
    expect(
      (await storage.installed(PluginType.metadata, 'test.plugin', '4.0.1'))
          ?.version,
      '4.0.1',
    );
  });

  test('install extracts into a prefixed version dir and removes the staging', () async {
    var validated = false;
    final installed = await storage.install(
      PluginType.metadata,
      pluginZip(version: '1.0.0'),
      validate: (_) => validated = true,
    );

    expect(validated, isTrue);
    expect(installed.versionDir, '${prefix}1.0.0');
    expect(
      File('${versionDir(installed.manifest.id, '1.0.0')}/plugin.json')
          .existsSync(),
      isTrue,
    );
    expect(
      Directory('${versionDir(installed.manifest.id, '1.0.0')}.new').existsSync(),
      isFalse,
    );
  });

  test('install creates the data dir and tolerates an existing one', () async {
    final installed = await storage.install(
      PluginType.metadata,
      pluginZip(version: '1.0.0'),
      validate: (_) {},
    );
    final data = Directory(dataDir(installed.manifest.id));
    expect(data.existsSync(), isTrue);

    File('${data.path}/keep.txt').writeAsStringSync('mine');
    await storage.install(
      PluginType.metadata,
      pluginZip(version: '2.0.0'),
      validate: (_) {},
    );

    expect(Directory(dataDir(installed.manifest.id)).existsSync(), isTrue);
    expect(File('${data.path}/keep.txt').existsSync(), isTrue);
  });

  test('installing another version leaves the previous one untouched', () async {
    final first = await storage.install(
      PluginType.metadata,
      pluginZip(version: '1.0.0'),
      validate: (_) {},
    );
    final firstFile = File(
      '${versionDir(first.manifest.id, '1.0.0')}/plugin.json',
    );
    final firstBytes = firstFile.readAsStringSync();

    final second = await storage.install(
      PluginType.metadata,
      pluginZip(version: '2.0.0'),
      validate: (_) {},
    );

    expect(second.versionDir, '${prefix}2.0.0');
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
      '${versionDir(first.manifest.id, '1.0.0')}/plugin.json',
    );
    final firstBytes = firstFile.readAsStringSync();

    final second = await storage.install(
      PluginType.metadata,
      pluginZip(version: '1.0.0'),
      validate: (_) {},
    );

    expect(second.versionDir, '${prefix}1.0.0-2');
    expect(firstFile.readAsStringSync(), firstBytes);
    expect(
      File('${versionDir(first.manifest.id, '1.0.0-2')}/plugin.json')
          .existsSync(),
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
      '${versionDir(installed.manifest.id, '1.0.0')}/plugin.json',
    ).readAsStringSync();
    expect(json, contains('"version":"1.0.0"'));
  });

  test('prune keeps the active version and data, drops the rest', () async {
    Directory(versionDir('org.example', '1.0.0')).createSync(recursive: true);
    Directory(versionDir('org.example', '2.0.0')).createSync(recursive: true);
    final leftover = Directory('${versionDir('org.example', '3.0.0')}.new')
      ..createSync(recursive: true);
    final legacy = Directory(codeDir('org.example', '4.0.1'))
      ..createSync(recursive: true);
    final data = Directory(dataDir('org.example'))..createSync(recursive: true);
    final dataFile = File('${data.path}/cache.bin')..writeAsStringSync('data');
    final auth = File('${idDir('org.example')}/auth.json')
      ..writeAsStringSync('{"token":"x"}');
    Directory(versionDir('old.example', '3.0.0')).createSync(recursive: true);
    Directory(dataDir('old.example')).createSync(recursive: true);
    final oldAuth = File('${idDir('old.example')}/auth.json')
      ..writeAsStringSync('{"token":"old"}');

    final removed = await storage.prune(
      keep: {
        storage.versionDirKey(
          PluginType.metadata,
          'org.example',
          '${prefix}2.0.0',
        ),
      },
    );

    expect(
      removed.map((d) => d.path).toSet(),
      {
        versionDir('org.example', '1.0.0'),
        leftover.path,
        idDir('old.example'),
      },
    );
    expect(
      Directory(versionDir('org.example', '2.0.0')).existsSync(),
      isTrue,
    );
    expect(data.existsSync(), isTrue);
    expect(dataFile.existsSync(), isTrue);
    expect(legacy.existsSync(), isTrue);
    expect(auth.existsSync(), isTrue);
    expect(Directory(idDir('old.example')).existsSync(), isFalse);
    expect(oldAuth.existsSync(), isFalse);
  });

  test('prune keeps a legacy active dir untouched', () async {
    final legacy = Directory(codeDir('org.example', '4.0.1'))
      ..createSync(recursive: true);
    final data = Directory(dataDir('org.example'))..createSync(recursive: true);

    final removed = await storage.prune(
      keep: {
        storage.versionDirKey(PluginType.metadata, 'org.example', '4.0.1'),
      },
    );

    expect(removed, isEmpty);
    expect(legacy.existsSync(), isTrue);
    expect(data.existsSync(), isTrue);
  });

  test('prune removes the leftovers of an interrupted install', () async {
    Directory(versionDir('org.example', '1.0.0')).createSync(recursive: true);
    final leftover = Directory('${versionDir('org.example', '2.0.0')}.new')
      ..createSync(recursive: true);

    await storage.prune(
      keep: {
        storage.versionDirKey(
          PluginType.metadata,
          'org.example',
          '${prefix}1.0.0',
        ),
      },
    );

    expect(leftover.existsSync(), isFalse);
  });

  test('prune leaves files alone: only directories are removed', () async {
    Directory(versionDir('org.example', '1.0.0')).createSync(recursive: true);
    final dataFile = File('${idDir('org.example')}/auth.json')
      ..writeAsStringSync('{"token":"x"}');
    final stray = File('${tempDir.path}/plugins/metadata/notes.txt')
      ..writeAsStringSync('keep me');

    await storage.prune(
      keep: {
        storage.versionDirKey(
          PluginType.metadata,
          'org.example',
          '${prefix}1.0.0',
        ),
      },
    );

    expect(dataFile.existsSync(), isTrue);
    expect(stray.existsSync(), isTrue);
  });

  test('prune removes an id with no active version entirely', () async {
    Directory(versionDir('gone.example', '1.0.0')).createSync(recursive: true);
    final data = Directory(dataDir('gone.example'))..createSync(recursive: true);
    final dataFile = File('${data.path}/cache.bin')..writeAsStringSync('data');
    File('${idDir('gone.example')}/auth.json').writeAsStringSync(
      '{"token":"x"}',
    );

    final removed = await storage.prune(keep: const {});

    expect(Directory(idDir('gone.example')).existsSync(), isFalse);
    expect(dataFile.existsSync(), isFalse);
    expect(removed.map((d) => d.path), [idDir('gone.example')]);
  });

  test('prune does nothing when the store does not exist', () async {
    expect(await storage.prune(keep: const {}), isEmpty);
  });
}
