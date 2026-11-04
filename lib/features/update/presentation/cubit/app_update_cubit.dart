import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/features/update/data/exceptions/app_update_failures.dart';
import 'package:music_are/features/update/data/models/installed_app.dart';
import 'package:music_are/features/update/data/services/app_update_downloader.dart';
import 'package:music_are/features/update/data/services/app_update_installer.dart';
import 'package:music_are/features/update/data/services/app_update_checker.dart';
import 'package:music_are/features/update/presentation/cubit/app_update_state.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppUpdateCubit extends Cubit<AppUpdateState> {
  final AppUpdateChecker _checker;
  final AppUpdateDownloader _downloader;
  final AppUpdateInstaller _installer;
  final NoticeBus _notices;
  final Future<InstalledApp> Function() _readInstalled;

  bool _checkInFlight = false;
  bool _cancelRequested = false;

  AppUpdateCubit(
    this._checker,
    this._downloader,
    this._installer,
    this._notices, {
    Future<InstalledApp> Function()? readInstalled,
  }) : _readInstalled = readInstalled ?? _fromPackageInfo,
       super(const AppUpdateState.idle());

  static Future<InstalledApp> _fromPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    return InstalledApp(
      packageName: info.packageName,
      versionName: info.version,
      versionCode: int.tryParse(info.buildNumber) ?? 0,
    );
  }

  Future<void> check({bool silent = false}) async {
    if (_checkInFlight ||
        state.isBusy ||
        state.status == AppUpdateStatus.checking) {
      return;
    }
    _checkInFlight = true;
    var installed = state.installed;
    try {
      installed = installed ?? await _readInstalled();
      if (isClosed) return;
      emit(AppUpdateState.checking(installed));
      final update = await _checker.latest(installed);
      if (isClosed) return;
      emit(
        update == null
            ? AppUpdateState.upToDate(installed)
            : AppUpdateState.available(installed, update),
      );
    } on AppUpdateFailure catch (failure) {
      if (isClosed) return;
      if (silent) {
        emit(AppUpdateState.idle(installed));
      } else {
        emit(AppUpdateState.failed(failure, installed: installed));
        _notices.emit(Notice.error(failure));
      }
    } finally {
      _checkInFlight = false;
    }
  }

  Future<void> updateNow() async {
    final update = state.update;
    final installed = state.installed;
    if (update == null || installed == null || state.isBusy) return;

    _cancelRequested = false;
    emit(
      AppUpdateState.downloading(
        installed,
        update,
        receivedBytes: 0,
        totalBytes: update.apkSize,
      ),
    );

    try {
      final directory = await _installer.updatesDir();
      final path = await _downloader.download(
        update,
        directory: directory,
        onProgress: (received, total) {
          if (isClosed || _cancelRequested) return;
          emit(
            AppUpdateState.downloading(
              installed,
              update,
              receivedBytes: received,
              totalBytes: total > 0 ? total : update.apkSize,
            ),
          );
        },
        isCancelled: () => _cancelRequested,
      );
      if (isClosed) return;
      if (path == null) {
        emit(AppUpdateState.available(installed, update));
        return;
      }

      emit(AppUpdateState.installing(installed, update));
      await _installer.install(
        apkPath: path,
        installed: installed,
        expectedVersionCode: update.versionCode,
      );
      if (isClosed) return;
      emit(AppUpdateState.available(installed, update));
    } on AppUpdateFailure catch (failure) {
      if (isClosed) return;
      emit(
        AppUpdateState.failed(failure, installed: installed, update: update),
      );
      _notices.emit(Notice.error(failure));
    }
  }

  void cancelDownload() {
    if (state.status == AppUpdateStatus.downloading) {
      _cancelRequested = true;
    }
  }
}
