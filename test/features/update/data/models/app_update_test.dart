import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/features/update/data/models/app_update.dart';

Map<String, dynamic> release({
  String tag = 'v1.0.2+4',
  List<Map<String, dynamic>>? assets,
}) {
  return {
    'tag_name': tag,
    'assets':
        assets ??
        [
          {
            'name': 'MusicAre-1.0.2.apk',
            'size': 53179994,
            'digest': 'sha256:${'a' * 64}',
            'browser_download_url':
                'https://github.com/stefare90/musicare/releases/download/'
                'v1.0.2+4/MusicAre-1.0.2.apk',
          },
        ],
  };
}

Map<String, dynamic> apkAsset({
  String name = 'MusicAre-1.0.2.apk',
  Object? size = 53179994,
  Object? digest =
      'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  Object? url = 'https://example.com/MusicAre-1.0.2.apk',
}) {
  return {
    'name': name,
    'size': size,
    'digest': digest,
    'browser_download_url': url,
  };
}

void main() {
  group('AppUpdate.fromRelease', () {
    test('parses a valid release into an update', () {
      final update = AppUpdate.fromRelease(release(), installedVersionCode: 3);

      expect(update, isNotNull);
      expect(update!.versionName, '1.0.2');
      expect(update.versionCode, 4);
      expect(update.apkSize, 53179994);
      expect(update.sha256, 'a' * 64);
      expect(update.apkUri.toString(), contains('MusicAre-1.0.2.apk'));
      expect(update.sizeLabel, '51 MB');
    });

    test('picks the apk asset among other assets', () {
      final update = AppUpdate.fromRelease(
        release(
          assets: [
            apkAsset(name: 'notes.txt', digest: 'sha256:${'b' * 64}'),
            apkAsset(size: 100, digest: 'sha256:${'c' * 64}'),
          ],
        ),
        installedVersionCode: 3,
      );

      expect(update!.sha256, 'c' * 64);
    });

    test('lowercases the digest', () {
      final update = AppUpdate.fromRelease(
        release(assets: [apkAsset(digest: 'sha256:${'A' * 64}')]),
        installedVersionCode: 3,
      );

      expect(update!.sha256, 'a' * 64);
    });

    test('never returns an update for the installed version', () {
      expect(AppUpdate.fromRelease(release(), installedVersionCode: 4), isNull);
    });

    test('never returns a downgrade', () {
      expect(AppUpdate.fromRelease(release(), installedVersionCode: 5), isNull);
    });

    for (final tag in [
      '1.0.2+4',
      'v1.0.2',
      'v1.0+4',
      'v1.0.2.3+4',
      'v1.0.2+4-beta',
      'v1.0.2+',
      'vv1.0.2+4',
      '',
    ]) {
      test('rejects the malformed tag "$tag"', () {
        expect(
          AppUpdate.fromRelease(release(tag: tag), installedVersionCode: 3),
          isNull,
        );
      });
    }

    test('rejects a release without assets', () {
      expect(
        AppUpdate.fromRelease({
          'tag_name': 'v1.0.2+4',
        }, installedVersionCode: 3),
        isNull,
      );
    });

    test('rejects a release without an apk asset', () {
      expect(
        AppUpdate.fromRelease(
          release(assets: [apkAsset(name: 'MusicAre-1.0.2.aab')]),
          installedVersionCode: 3,
        ),
        isNull,
      );
    });

    test('rejects an apk with a zero or missing size', () {
      expect(
        AppUpdate.fromRelease(
          release(assets: [apkAsset(size: 0)]),
          installedVersionCode: 3,
        ),
        isNull,
      );
      expect(
        AppUpdate.fromRelease(
          release(assets: [apkAsset(size: null)]),
          installedVersionCode: 3,
        ),
        isNull,
      );
    });

    test('rejects an apk with a missing or malformed digest', () {
      expect(
        AppUpdate.fromRelease(
          release(assets: [apkAsset(digest: null)]),
          installedVersionCode: 3,
        ),
        isNull,
      );
      expect(
        AppUpdate.fromRelease(
          release(assets: [apkAsset(digest: 'md5:${'a' * 32}')]),
          installedVersionCode: 3,
        ),
        isNull,
      );
      expect(
        AppUpdate.fromRelease(
          release(assets: [apkAsset(digest: 'sha256:abc')]),
          installedVersionCode: 3,
        ),
        isNull,
      );
    });

    test('rejects an apk without a download url', () {
      expect(
        AppUpdate.fromRelease(
          release(assets: [apkAsset(url: null)]),
          installedVersionCode: 3,
        ),
        isNull,
      );
    });
  });
}
