import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

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
