import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:music_are/features/update/data/exceptions/app_update_failures.dart';
import 'package:music_are/features/update/data/models/app_update.dart';
import 'package:music_are/features/update/data/services/app_update_downloader.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory directory;

  final apkBytes = List<int>.generate(256, (index) => index % 256);
  final apkSha = sha256.convert(apkBytes).toString();

  AppUpdate update({String sha = ''}) => AppUpdate(
    versionName: '1.0.2',
    versionCode: 4,
    apkUri: Uri.parse('https://example.com/MusicAre-1.0.2.apk'),
    apkSize: apkBytes.length,
    sha256: sha.isEmpty ? apkSha : sha,
  );

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('musicare-update-test');
  });

  tearDown(() async {
    if (directory.existsSync()) await directory.delete(recursive: true);
  });

  test('downloads, reports progress and verifies the digest', () async {
    final service = AppUpdateDownloader(
      client: MockClient.streaming((request, bodyStream) async {
        return http.StreamedResponse(
          Stream.fromIterable([
            apkBytes.sublist(0, 128),
            apkBytes.sublist(128),
          ]),
          200,
          contentLength: apkBytes.length,
        );
      }),
    );
    final progress = <int>[];

    final path = await service.download(
      update(),
      directory: directory.path,
      onProgress: (received, total) {
        progress.add(received);
        expect(total, apkBytes.length);
      },
      isCancelled: () => false,
    );

    expect(path, p.join(directory.path, 'MusicAre-1.0.2.apk'));
    final downloaded = File(path!);
    expect(downloaded.readAsBytesSync(), apkBytes);
    expect(sha256.convert(downloaded.readAsBytesSync()).toString(), apkSha);
    expect(progress, [128, apkBytes.length]);
    expect(
      File('${downloaded.path}.part').existsSync(),
      isFalse,
      reason: 'the partial file must be renamed, not left behind',
    );
  });

  test('deletes the partial file and fails on a digest mismatch', () async {
    final service = AppUpdateDownloader(
      client: MockClient.streaming((request, bodyStream) async {
        return http.StreamedResponse(
          Stream.fromIterable([apkBytes]),
          200,
          contentLength: apkBytes.length,
        );
      }),
    );

    await expectLater(
      service.download(
        update(sha: 'b' * 64),
        directory: directory.path,
        onProgress: (_, _) {},
        isCancelled: () => false,
      ),
      throwsA(isA<UpdateCorrupted>()),
    );

    expect(
      File(p.join(directory.path, 'MusicAre-1.0.2.apk')).existsSync(),
      isFalse,
    );
    expect(
      File(p.join(directory.path, 'MusicAre-1.0.2.apk.part')).existsSync(),
      isFalse,
    );
  });

  test('cancel stops the download and deletes every file', () async {
    final service = AppUpdateDownloader(
      client: MockClient.streaming((request, bodyStream) async {
        return http.StreamedResponse(
          Stream.fromIterable([
            apkBytes.sublist(0, 128),
            apkBytes.sublist(128),
          ]),
          200,
          contentLength: apkBytes.length,
        );
      }),
    );
    var checks = 0;

    final path = await service.download(
      update(),
      directory: directory.path,
      onProgress: (_, _) {},
      isCancelled: () => ++checks > 1,
    );

    expect(path, isNull);
    expect(directory.listSync(), isEmpty);
  });

  test('reuses an already verified apk without touching the network', () async {
    final cached = File(p.join(directory.path, 'MusicAre-1.0.2.apk'));
    await cached.writeAsBytes(apkBytes);
    final service = AppUpdateDownloader(
      client: MockClient.streaming((request, bodyStream) async {
        fail('the network must not be used when the cached apk is verified');
      }),
    );

    final path = await service.download(
      update(),
      directory: directory.path,
      onProgress: (_, _) {},
      isCancelled: () => false,
    );

    expect(path, cached.path);
  });

  test(
    'downloads again when the cached apk does not match the digest',
    () async {
      final cached = File(p.join(directory.path, 'MusicAre-1.0.2.apk'));
      await cached.writeAsBytes([1, 2, 3]);
      final service = AppUpdateDownloader(
        client: MockClient.streaming((request, bodyStream) async {
          return http.StreamedResponse(
            Stream.fromIterable([apkBytes]),
            200,
            contentLength: apkBytes.length,
          );
        }),
      );

      final path = await service.download(
        update(),
        directory: directory.path,
        onProgress: (_, _) {},
        isCancelled: () => false,
      );

      expect(File(path!).readAsBytesSync(), apkBytes);
    },
  );

  test('removes apks of other versions', () async {
    final stale = File(p.join(directory.path, 'MusicAre-1.0.0.apk'));
    await stale.writeAsBytes([7, 7, 7]);
    final service = AppUpdateDownloader(
      client: MockClient.streaming((request, bodyStream) async {
        return http.StreamedResponse(
          Stream.fromIterable([apkBytes]),
          200,
          contentLength: apkBytes.length,
        );
      }),
    );

    await service.download(
      update(),
      directory: directory.path,
      onProgress: (_, _) {},
      isCancelled: () => false,
    );

    expect(stale.existsSync(), isFalse);
  });

  test('maps an HTTP failure to UpdateDownloadFailed', () async {
    final service = AppUpdateDownloader(
      client: MockClient.streaming((request, bodyStream) async {
        return http.StreamedResponse(const Stream.empty(), 500);
      }),
    );

    await expectLater(
      service.download(
        update(),
        directory: directory.path,
        onProgress: (_, _) {},
        isCancelled: () => false,
      ),
      throwsA(isA<UpdateDownloadFailed>()),
    );
    expect(directory.listSync(), isEmpty);
  });

  test('maps a transport error to UpdateDownloadFailed', () async {
    final service = AppUpdateDownloader(
      client: MockClient.streaming((request, bodyStream) async {
        throw http.ClientException('offline');
      }),
    );

    await expectLater(
      service.download(
        update(),
        directory: directory.path,
        onProgress: (_, _) {},
        isCancelled: () => false,
      ),
      throwsA(isA<UpdateDownloadFailed>()),
    );
    expect(directory.listSync(), isEmpty);
  });
}
