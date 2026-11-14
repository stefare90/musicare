import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

typedef InstalledPluginVersion = ({PluginManifest manifest, String versionDir});

class PluginStorage {
  PluginStorage({Future<Directory> Function()? appDir})
    : _appDir = appDir ?? _defaultAppDir;

  static const String _versionDirPrefix = 'plugin_version_';
  static const String _dataDirName = 'data';

  final Future<Directory> Function() _appDir;

  static Future<Directory> _defaultAppDir() async =>
      Directory((await getApplicationSupportDirectory()).path);

  Future<Directory> pluginsDir() async =>
      Directory(p.join((await _appDir()).path, 'plugins'));

  Future<String> codeDir(PluginType type, String id, String versionDir) async {
    final root = await pluginsDir();
    return p.join(root.path, _segmentOf(type), id, versionDir);
  }

  Future<Directory> dataDir(PluginType type, String id) async {
    final root = await pluginsDir();
    return Directory(p.join(root.path, _segmentOf(type), id, _dataDirName));
  }

  String versionDirKey(PluginType type, String id, String versionDir) =>
      [_segmentOf(type), id, versionDir].join('/');

  Future<PluginManifest?> installed(
    PluginType type,
    String id,
    String versionDir,
  ) async {
    final manifestFile = File(
      p.join(await codeDir(type, id, versionDir), 'plugin.json'),
    );
    return _readManifest(manifestFile);
  }

  /// A taken name gets a suffix: a path a loaded module may read is never reused.
  Future<InstalledPluginVersion> install(
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

    final idDir = await _pluginDir(type, manifest.id);
    idDir.createSync(recursive: true);
    (await dataDir(type, manifest.id)).createSync(recursive: true);
    final versionDir = _freeVersionDir(
      idDir,
      '$_versionDirPrefix${manifest.version}',
    );
    final staging = Directory(p.join(idDir.path, '$versionDir.new'));
    final target = Directory(p.join(idDir.path, versionDir));

    try {
      _extract(archive, staging);
      staging.renameSync(target.path);
    } catch (_) {
      _deleteIfExists(staging);
      rethrow;
    }
    return (manifest: manifest, versionDir: versionDir);
  }

  /// Call it only before the interpreter starts: a loaded module may still read a code dir.
  Future<List<Directory>> prune({required Set<String> keep}) async {
    final root = await pluginsDir();
    if (!root.existsSync()) return const [];

    final removed = <Directory>[];
    for (final type in PluginType.values) {
      final subsystem = Directory(p.join(root.path, _segmentOf(type)));
      if (!subsystem.existsSync()) continue;
      for (final idDir in _directoriesOf(subsystem)) {
        final id = p.basename(idDir.path);
        final entries = _directoriesOf(idDir);
        final active = entries
            .where(
              (dir) =>
                  keep.contains(versionDirKey(type, id, p.basename(dir.path))),
            )
            .toList();
        if (active.isEmpty) {
          idDir.deleteSync(recursive: true);
          removed.add(idDir);
          continue;
        }
        for (final entry in entries) {
          if (active.contains(entry)) continue;
          if (!p.basename(entry.path).startsWith(_versionDirPrefix)) continue;
          entry.deleteSync(recursive: true);
          removed.add(entry);
        }
      }
    }
    return removed;
  }

  Future<Directory> _pluginDir(PluginType type, String id) async {
    final root = await pluginsDir();
    return Directory(p.join(root.path, _segmentOf(type), id));
  }

  String _freeVersionDir(Directory parent, String requested) {
    final base = _safeDirName(requested);
    var index = 1;
    while (true) {
      final candidate = index == 1 ? base : '$base-$index';
      final target = p.join(parent.path, candidate);
      if (!Directory(target).existsSync() &&
          !Directory('$target.new').existsSync()) {
        return candidate;
      }
      index++;
    }
  }

  String _safeDirName(String value) {
    final cleaned = value.replaceAll(RegExp(r'[\\/]'), '_').trim();
    return cleaned.isEmpty ? 'unknown' : cleaned;
  }

  String _segmentOf(PluginType type) {
    return switch (type) {
      PluginType.metadata => 'metadata',
      PluginType.audioSource => 'audio_source',
    };
  }

  PluginManifest? _readManifest(File file) {
    if (!file.existsSync()) return null;
    try {
      return PluginManifest.fromJson(
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
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

  List<Directory> _directoriesOf(Directory parent) =>
      parent.listSync(followLinks: false).whereType<Directory>().toList();
}
