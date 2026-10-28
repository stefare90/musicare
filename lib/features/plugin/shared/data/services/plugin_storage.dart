import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PluginStorage {
  PluginStorage({Future<Directory> Function()? appDir})
    : _appDir = appDir ?? _defaultAppDir;

  final Future<Directory> Function() _appDir;

  static Future<Directory> _defaultAppDir() async =>
      Directory((await getApplicationSupportDirectory()).path);

  Future<String> codeDir(PluginType type, String id) async {
    final root = await _appDir();
    return p.join(root.path, 'plugins', _segmentOf(type), id);
  }

  Future<PluginManifest?> installed(PluginType type, String id) async {
    final manifestFile = File(p.join(await codeDir(type, id), 'plugin.json'));
    if (!manifestFile.existsSync()) return null;
    try {
      return PluginManifest.fromJson(
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<PluginManifest> install(
    PluginType type,
    Uint8List zipBytes, {
    required void Function(PluginManifest manifest) validate,
  }) async {
    final archive = ZipDecoder().decodeBytes(zipBytes);
    final manifest = _manifestFrom(archive);
    if (manifest.pluginType != type) {
      throw InvalidPluginTypeException(
        expectedType: type.name,
        actualType: manifest.type,
      );
    }
    validate(manifest);

    final dirPath = await codeDir(type, manifest.id);
    final newDir = Directory('$dirPath.new');
    final backupDir = Directory('$dirPath.bak');
    final liveDir = Directory(dirPath);
    _deleteIfExists(newDir);
    _deleteIfExists(backupDir);

    try {
      _extract(archive, newDir);
      if (liveDir.existsSync()) {
        liveDir.renameSync(backupDir.path);
      }
      newDir.renameSync(dirPath);
    } catch (_) {
      _deleteIfExists(newDir);
      if (!liveDir.existsSync() && backupDir.existsSync()) {
        backupDir.renameSync(dirPath);
      }
      rethrow;
    }
    return manifest;
  }

  Future<void> commit(PluginType type, String id) async {
    final dirPath = await codeDir(type, id);
    _deleteIfExists(Directory('$dirPath.new'));
    _deleteIfExists(Directory('$dirPath.bak'));
  }

  Future<void> rollback(PluginType type, String id) async {
    final dirPath = await codeDir(type, id);
    final liveDir = Directory(dirPath);
    final backupDir = Directory('$dirPath.bak');
    _deleteIfExists(Directory('$dirPath.new'));
    if (!backupDir.existsSync()) {
      _deleteIfExists(liveDir);
      return;
    }
    _deleteIfExists(liveDir);
    backupDir.renameSync(dirPath);
  }

  Future<void> removeCodeDir(PluginType type, String id) async {
    _deleteIfExists(Directory(await codeDir(type, id)));
  }

  String _segmentOf(PluginType type) {
    return switch (type) {
      PluginType.metadata => 'metadata',
      PluginType.audioSource => 'audio_source',
    };
  }

  PluginManifest _manifestFrom(Archive archive) {
    for (final file in archive) {
      if (file.name == 'plugin.json') {
        return PluginManifest.fromJson(
          jsonDecode(utf8.decode(file.content as List<int>))
              as Map<String, dynamic>,
        );
      }
    }
    throw InvalidPluginArchiveException();
  }

  void _extract(Archive archive, Directory destination) {
    destination.createSync(recursive: true);
    for (final file in archive) {
      final filename = p.join(destination.path, file.name);
      if (file.isFile) {
        File(filename)
          ..createSync(recursive: true)
          ..writeAsBytesSync(file.content as List<int>);
      } else {
        Directory(filename).createSync(recursive: true);
      }
    }
  }

  void _deleteIfExists(Directory directory) {
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  }
}
