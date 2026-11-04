import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:music_are/features/update/data/exceptions/app_update_failures.dart';
import 'package:music_are/features/update/data/models/app_update.dart';
import 'package:path/path.dart' as p;

typedef DownloadProgress = void Function(int receivedBytes, int totalBytes);

class AppUpdateDownloader {
  final http.Client _client;

  AppUpdateDownloader({http.Client? client})
    : _client = client ?? http.Client();

  Future<String?> download(
    AppUpdate update, {
    required String directory,
    required DownloadProgress onProgress,
    required bool Function() isCancelled,
  }) async {
    final target = File(
      p.join(directory, 'MusicAre-${update.versionName}.apk'),
    );
    await Directory(directory).create(recursive: true);
    await _deleteStaleApks(directory, keepName: p.basename(target.path));

    if (await target.exists() && await _sha256Of(target) == update.sha256) {
      return target.path;
    }

    final part = File('${target.path}.part');
    await _deleteIfExists(part);
    IOSink? sink;
    ByteConversionSink? hashSink;
    var received = 0;

    try {
      final response = await _client.send(http.Request('GET', update.apkUri));
      if (response.statusCode != 200) {
        throw const UpdateDownloadFailed();
      }

      final total = response.contentLength ?? update.apkSize;
      final digest = _DigestCollector();
      final hash = sha256.startChunkedConversion(digest);
      final output = part.openWrite();
      hashSink = hash;
      sink = output;

      await for (final chunk in response.stream) {
        if (isCancelled()) {
          await output.close();
          sink = null;
          await _deleteIfExists(part);
          return null;
        }
        output.add(chunk);
        hash.add(chunk);
        received += chunk.length;
        onProgress(received, total > 0 ? total : received);
      }

      await output.close();
      sink = null;
      hash.close();
      hashSink = null;

      if (isCancelled()) {
        await _deleteIfExists(part);
        return null;
      }
      if (digest.value?.toString() != update.sha256) {
        await _deleteIfExists(part);
        throw const UpdateCorrupted();
      }

      await part.rename(target.path);
      return target.path;
    } on AppUpdateFailure {
      await sink?.close();
      hashSink?.close();
      await _deleteIfExists(part);
      rethrow;
    } on Exception {
      await sink?.close();
      hashSink?.close();
      await _deleteIfExists(part);
      throw const UpdateDownloadFailed();
    }
  }

  Future<void> _deleteStaleApks(
    String directory, {
    required String keepName,
  }) async {
    await for (final entity in Directory(directory).list()) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      if (name != keepName && name.endsWith('.apk')) {
        await _deleteIfExists(entity);
      }
    }
  }

  Future<String> _sha256Of(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  Future<void> _deleteIfExists(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // Best effort: a stale file that cannot be deleted does not change the
      // outcome of the download itself.
    }
  }
}

class _DigestCollector implements Sink<Digest> {
  Digest? value;

  @override
  void add(Digest data) {
    value = data;
  }

  @override
  void close() {}
}
