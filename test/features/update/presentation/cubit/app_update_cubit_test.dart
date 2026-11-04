import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/features/update/data/exceptions/app_update_failures.dart';
import 'package:music_are/features/update/data/models/app_update.dart';
import 'package:music_are/features/update/data/models/installed_app.dart';
import 'package:music_are/features/update/data/services/app_update_downloader.dart';
import 'package:music_are/features/update/data/services/app_update_installer.dart';
import 'package:music_are/features/update/data/services/app_update_checker.dart';
import 'package:music_are/features/update/presentation/cubit/app_update_cubit.dart';
import 'package:music_are/features/update/presentation/cubit/app_update_state.dart';

class MockAppUpdateChecker extends Mock implements AppUpdateChecker {}

class MockAppUpdateDownloader extends Mock implements AppUpdateDownloader {}

class MockAppUpdateInstaller extends Mock implements AppUpdateInstaller {}

const installed = InstalledApp(
  packageName: 'com.musicare.app',
  versionName: '1.0.1',
  versionCode: 3,
);

final update = AppUpdate(
  versionName: '1.0.2',
  versionCode: 4,
  apkUri: Uri.parse('https://example.com/MusicAre-1.0.2.apk'),
  apkSize: 53477376,
  sha256: 'a' * 64,
);

void main() {
  late MockAppUpdateChecker service;
  late MockAppUpdateDownloader downloader;
  late MockAppUpdateInstaller installer;
  late NoticeBus notices;
  late AppUpdateCubit cubit;
  late List<Notice> emitted;

  setUpAll(() {
    registerFallbackValue(update);
    registerFallbackValue(installed);
  });

  setUp(() {
    service = MockAppUpdateChecker();
    downloader = MockAppUpdateDownloader();
    installer = MockAppUpdateInstaller();
    notices = NoticeBus();
    emitted = [];
    notices.notices.listen(emitted.add);
    cubit = AppUpdateCubit(
      service,
      downloader,
      installer,
      notices,
      readInstalled: () async => installed,
    );

    when(() => installer.updatesDir()).thenAnswer((_) async => '/updates');
    when(
      () => downloader.download(
        any(),
        directory: any(named: 'directory'),
        onProgress: any(named: 'onProgress'),
        isCancelled: any(named: 'isCancelled'),
      ),
    ).thenAnswer((_) async => '/updates/MusicAre-1.0.2.apk');
    when(
      () => installer.install(
        apkPath: any(named: 'apkPath'),
        installed: any(named: 'installed'),
        expectedVersionCode: any(named: 'expectedVersionCode'),
      ),
    ).thenAnswer((_) async {});
  });

  tearDown(() async {
    await cubit.close();
    await notices.close();
  });

  test('emits checking then available and records the installed app', () async {
    when(() => service.latest(installed)).thenAnswer((_) async => update);
    final states = <AppUpdateStatus>[];
    cubit.stream.listen((state) => states.add(state.status));

    await cubit.check();
    await pumpEventQueue();

    expect(states, [AppUpdateStatus.checking, AppUpdateStatus.available]);
    expect(cubit.state.update, update);
    expect(cubit.state.installedLabel, 'v1.0.1 (3)');
    expect(emitted, isEmpty);
  });

  test('emits upToDate when no newer release exists', () async {
    when(() => service.latest(installed)).thenAnswer((_) async => null);

    await cubit.check();

    expect(cubit.state.status, AppUpdateStatus.upToDate);
  });

  test('a silent startup failure stays silent and writes nothing', () async {
    when(() => service.latest(installed)).thenThrow(const UpdateCheckFailed());

    await cubit.check(silent: true);
    await pumpEventQueue();

    expect(cubit.state.status, AppUpdateStatus.idle);
    expect(cubit.state.failure, isNull);
    expect(emitted, isEmpty);
  });

  test('a manual failure is exposed and announced', () async {
    when(
      () => service.latest(installed),
    ).thenThrow(const UpdateCheckFailed(statusCode: 403));

    await cubit.check();
    await pumpEventQueue();

    expect(cubit.state.status, AppUpdateStatus.failed);
    expect(cubit.state.failure, isA<UpdateCheckFailed>());
    expect(emitted.single, isA<ErrorNotice>());
    expect((emitted.single as ErrorNotice).error, isA<UpdateCheckFailed>());
  });

  test('runs a single check at a time', () async {
    final completer = Completer<AppUpdate?>();
    var calls = 0;
    when(() => service.latest(installed)).thenAnswer((_) {
      calls++;
      return completer.future;
    });

    final first = cubit.check();
    final second = cubit.check();
    completer.complete(update);
    await Future.wait([first, second]);

    expect(calls, 1);
    expect(cubit.state.status, AppUpdateStatus.available);
  });

  test('does not start a download without an available update', () async {
    await cubit.updateNow();

    verifyNever(
      () => downloader.download(
        any(),
        directory: any(named: 'directory'),
        onProgress: any(named: 'onProgress'),
        isCancelled: any(named: 'isCancelled'),
      ),
    );
  });

  test(
    'downloads with progress, verifies and hands over to the installer',
    () async {
      when(() => service.latest(installed)).thenAnswer((_) async => update);
      when(
        () => downloader.download(
          any(),
          directory: any(named: 'directory'),
          onProgress: any(named: 'onProgress'),
          isCancelled: any(named: 'isCancelled'),
        ),
      ).thenAnswer((invocation) async {
        final onProgress =
            invocation.namedArguments[#onProgress] as DownloadProgress;
        onProgress(40, update.apkSize);
        return '/updates/MusicAre-1.0.2.apk';
      });
      final installing = Completer<void>();
      when(
        () => installer.install(
          apkPath: any(named: 'apkPath'),
          installed: any(named: 'installed'),
          expectedVersionCode: any(named: 'expectedVersionCode'),
        ),
      ).thenAnswer((_) => installing.future);

      await cubit.check();
      final download = cubit.updateNow();
      await pumpEventQueue();

      expect(cubit.state.status, AppUpdateStatus.installing);
      verify(
        () => installer.install(
          apkPath: '/updates/MusicAre-1.0.2.apk',
          installed: installed,
          expectedVersionCode: 4,
        ),
      ).called(1);

      installing.complete();
      await download;

      expect(cubit.state.status, AppUpdateStatus.available);
    },
  );

  test('reports download progress while streaming', () async {
    when(() => service.latest(installed)).thenAnswer((_) async => update);
    final progress = Completer<void>();
    when(
      () => downloader.download(
        any(),
        directory: any(named: 'directory'),
        onProgress: any(named: 'onProgress'),
        isCancelled: any(named: 'isCancelled'),
      ),
    ).thenAnswer((invocation) async {
      final onProgress =
          invocation.namedArguments[#onProgress] as DownloadProgress;
      onProgress(update.apkSize ~/ 2, update.apkSize);
      await progress.future;
      return '/updates/MusicAre-1.0.2.apk';
    });
    when(
      () => installer.install(
        apkPath: any(named: 'apkPath'),
        installed: any(named: 'installed'),
        expectedVersionCode: any(named: 'expectedVersionCode'),
      ),
    ).thenAnswer((_) async {});

    await cubit.check();
    final download = cubit.updateNow();
    await pumpEventQueue();

    expect(cubit.state.status, AppUpdateStatus.downloading);
    expect(cubit.state.progressPercent, 50);
    expect(cubit.state.transferredLabel, '26 of 51 MB');

    progress.complete();
    await download;
  });

  test(
    'cancel asks the downloader to stop and goes back to available',
    () async {
      when(() => service.latest(installed)).thenAnswer((_) async => update);
      late bool Function() isCancelled;
      when(
        () => downloader.download(
          any(),
          directory: any(named: 'directory'),
          onProgress: any(named: 'onProgress'),
          isCancelled: any(named: 'isCancelled'),
        ),
      ).thenAnswer((invocation) async {
        isCancelled =
            invocation.namedArguments[#isCancelled] as bool Function();
        cubit.cancelDownload();
        expect(isCancelled(), isTrue);
        return null;
      });

      await cubit.check();
      await cubit.updateNow();

      expect(cubit.state.status, AppUpdateStatus.available);
      verifyNever(
        () => installer.install(
          apkPath: any(named: 'apkPath'),
          installed: any(named: 'installed'),
          expectedVersionCode: any(named: 'expectedVersionCode'),
        ),
      );
    },
  );

  test('a corrupted download fails and keeps the update for a retry', () async {
    when(() => service.latest(installed)).thenAnswer((_) async => update);
    when(
      () => downloader.download(
        any(),
        directory: any(named: 'directory'),
        onProgress: any(named: 'onProgress'),
        isCancelled: any(named: 'isCancelled'),
      ),
    ).thenThrow(const UpdateCorrupted());

    await cubit.check();
    await cubit.updateNow();
    await pumpEventQueue();

    expect(cubit.state.status, AppUpdateStatus.failed);
    expect(cubit.state.failure, isA<UpdateCorrupted>());
    expect(cubit.state.update, update);
    expect(emitted.single, isA<ErrorNotice>());
  });
}
