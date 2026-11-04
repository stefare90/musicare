import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:music_are/features/update/data/exceptions/app_update_failures.dart';
import 'package:music_are/features/update/data/models/installed_app.dart';
import 'package:music_are/features/update/data/services/app_update_checker.dart';

const installed = InstalledApp(
  packageName: 'com.musicare.app',
  versionName: '1.0.1',
  versionCode: 3,
);

const validRelease = '''
{
  "tag_name": "v1.0.2+4",
  "assets": [
    {
      "name": "MusicAre-1.0.2.apk",
      "size": 53179994,
      "digest": "sha256:6a710d6760b954cb1d1304ddae7fd277a9a35c1285320d04249d0560692a3fb8",
      "browser_download_url": "https://github.com/stefare90/musicare/releases/download/v1.0.2%2B4/MusicAre-1.0.2.apk"
    }
  ]
}
''';

void main() {
  test(
    'requests the canonical MusicAre repository with the required headers',
    () async {
      late http.BaseRequest captured;
      final service = AppUpdateChecker(
        client: MockClient((request) async {
          captured = request;
          return http.Response(validRelease, 200);
        }),
      );

      final update = await service.latest(installed);

      expect(
        captured.url.toString(),
        'https://api.github.com/repos/stefare90/musicare/releases/latest',
      );
      expect(captured.headers['Accept'], 'application/vnd.github+json');
      expect(captured.headers['User-Agent'], 'MusicAre/1.0.1 (3)');
      expect(update!.versionName, '1.0.2');
      expect(update.versionCode, 4);
    },
  );

  test('returns null on 404 (no published release)', () async {
    final service = AppUpdateChecker(
      client: MockClient((_) async => http.Response('Not Found', 404)),
    );

    expect(await service.latest(installed), isNull);
  });

  for (final code in [403, 429, 500]) {
    test('throws UpdateCheckFailed on HTTP $code', () async {
      final service = AppUpdateChecker(
        client: MockClient((_) async => http.Response('nope', code)),
      );

      await expectLater(
        service.latest(installed),
        throwsA(
          isA<UpdateCheckFailed>().having(
            (e) => e.statusCode,
            'statusCode',
            code,
          ),
        ),
      );
    });
  }

  test('throws UpdateCheckFailed on a transport error', () async {
    final service = AppUpdateChecker(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );

    await expectLater(
      service.latest(installed),
      throwsA(isA<UpdateCheckFailed>()),
    );
  });

  test('returns null for a malformed payload instead of failing', () async {
    final service = AppUpdateChecker(
      client: MockClient((_) async => http.Response('not json', 200)),
    );

    expect(await service.latest(installed), isNull);
  });

  test('returns null when the release is not an installable update', () async {
    final service = AppUpdateChecker(
      client: MockClient(
        (_) async => http.Response('{"tag_name":"v1.0.1+3","assets":[]}', 200),
      ),
    );

    expect(await service.latest(installed), isNull);
  });
}
