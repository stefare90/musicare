import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/features/update/data/exceptions/app_update_failures.dart';
import 'package:music_are/features/update/data/models/installed_app.dart';
import 'package:music_are/features/update/data/services/app_update_installer.dart';

const installed = InstalledApp(
  packageName: 'com.musicare.app',
  versionName: '1.0.1',
  versionCode: 3,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late Directory directory;
  late File apk;
  late List<MethodCall> calls;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('musicare-installer-test');
    apk = File('${directory.path}/MusicAre-1.0.2.apk')
      ..writeAsBytesSync([1, 2, 3]);
    calls = [];
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(AppUpdateInstaller.channel, null);
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  });

  void handle(Future<Object?> Function(MethodCall call) onCall) {
    messenger.setMockMethodCallHandler(AppUpdateInstaller.channel, (call) {
      calls.add(call);
      return onCall(call);
    });
  }

  test('reads the updates directory from the channel', () async {
    handle((_) async => '${directory.path}/updates');

    expect(
      await AppUpdateInstaller().updatesDir(),
      '${directory.path}/updates',
    );
    expect(calls.single.method, 'updatesDir');
  });

  test(
    'installs a matching apk and normalizes the certificate digest',
    () async {
      handle((call) async {
        switch (call.method) {
          case 'signature':
            return 'aa' * 32;
          case 'apkInfo':
            expect(call.arguments, {'path': apk.path});
            return {
              'packageName': 'com.musicare.app',
              'versionCode': 4,
              'certSha256': 'AA' * 32,
            };
          case 'install':
            expect(call.arguments, {'path': apk.path});
            return null;
        }
        fail('unexpected method ${call.method}');
      });

      await AppUpdateInstaller().install(
        apkPath: apk.path,
        installed: installed,
        expectedVersionCode: 4,
      );

      expect(apk.existsSync(), isTrue);
      expect(calls.map((call) => call.method), [
        'apkInfo',
        'signature',
        'install',
      ]);
    },
  );

  test('rejects and deletes an apk for another package', () async {
    handle((call) async {
      switch (call.method) {
        case 'signature':
          return 'aa' * 32;
        case 'apkInfo':
          return {
            'packageName': 'com.example.other',
            'versionCode': 4,
            'certSha256': 'aa' * 32,
          };
      }
      fail('install must not be reached');
    });

    await expectLater(
      AppUpdateInstaller().install(
        apkPath: apk.path,
        installed: installed,
        expectedVersionCode: 4,
      ),
      throwsA(isA<UpdateRejected>()),
    );
    expect(apk.existsSync(), isFalse);
  });

  test('rejects an apk whose versionCode is not the published one', () async {
    handle((call) async {
      switch (call.method) {
        case 'signature':
          return 'aa' * 32;
        case 'apkInfo':
          return {
            'packageName': 'com.musicare.app',
            'versionCode': 3,
            'certSha256': 'aa' * 32,
          };
      }
      fail('install must not be reached');
    });

    await expectLater(
      AppUpdateInstaller().install(
        apkPath: apk.path,
        installed: installed,
        expectedVersionCode: 4,
      ),
      throwsA(isA<UpdateRejected>()),
    );
    expect(apk.existsSync(), isFalse);
  });

  test('rejects an apk signed with a different certificate', () async {
    handle((call) async {
      switch (call.method) {
        case 'signature':
          return 'bb' * 32;
        case 'apkInfo':
          return {
            'packageName': 'com.musicare.app',
            'versionCode': 4,
            'certSha256': 'aa' * 32,
          };
      }
      fail('install must not be reached');
    });

    await expectLater(
      AppUpdateInstaller().install(
        apkPath: apk.path,
        installed: installed,
        expectedVersionCode: 4,
      ),
      throwsA(isA<UpdateRejected>()),
    );
    expect(apk.existsSync(), isFalse);
  });

  test('rejects an unreadable package archive', () async {
    handle((call) async {
      switch (call.method) {
        case 'signature':
          return 'aa' * 32;
        case 'apkInfo':
          return null;
      }
      fail('install must not be reached');
    });

    await expectLater(
      AppUpdateInstaller().install(
        apkPath: apk.path,
        installed: installed,
        expectedVersionCode: 4,
      ),
      throwsA(isA<UpdateRejected>()),
    );
  });

  test('maps a channel failure while opening the installer', () async {
    handle((call) async {
      switch (call.method) {
        case 'signature':
          return 'aa' * 32;
        case 'apkInfo':
          return {
            'packageName': 'com.musicare.app',
            'versionCode': 4,
            'certSha256': 'aa' * 32,
          };
        case 'install':
          throw PlatformException(code: 'install_failed');
      }
      fail('unexpected method ${call.method}');
    });

    await expectLater(
      AppUpdateInstaller().install(
        apkPath: apk.path,
        installed: installed,
        expectedVersionCode: 4,
      ),
      throwsA(isA<UpdateInstallFailed>()),
    );
  });

  test('maps a missing platform channel to UpdateInstallFailed', () async {
    messenger.setMockMethodCallHandler(AppUpdateInstaller.channel, null);

    await expectLater(
      AppUpdateInstaller().updatesDir(),
      throwsA(isA<UpdateInstallFailed>()),
    );
  });
}
