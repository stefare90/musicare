import 'package:music_are/features/update/data/exceptions/app_update_failures.dart';
import 'package:music_are/features/update/data/models/app_update.dart';
import 'package:music_are/features/update/data/models/installed_app.dart';

enum AppUpdateStatus {
  idle,
  checking,
  upToDate,
  available,
  downloading,
  installing,
  failed,
}

class AppUpdateState {
  final AppUpdateStatus status;
  final InstalledApp? installed;
  final AppUpdate? update;
  final int receivedBytes;
  final int totalBytes;
  final AppUpdateFailure? failure;

  const AppUpdateState({
    required this.status,
    this.installed,
    this.update,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.failure,
  });

  const AppUpdateState.idle([InstalledApp? installed])
    : this(status: AppUpdateStatus.idle, installed: installed);

  const AppUpdateState.checking(InstalledApp? installed)
    : this(status: AppUpdateStatus.checking, installed: installed);

  const AppUpdateState.upToDate(InstalledApp? installed)
    : this(status: AppUpdateStatus.upToDate, installed: installed);

  const AppUpdateState.available(InstalledApp? installed, AppUpdate update)
    : this(
        status: AppUpdateStatus.available,
        installed: installed,
        update: update,
      );

  const AppUpdateState.downloading(
    InstalledApp? installed,
    AppUpdate update, {
    required int receivedBytes,
    required int totalBytes,
  }) : this(
         status: AppUpdateStatus.downloading,
         installed: installed,
         update: update,
         receivedBytes: receivedBytes,
         totalBytes: totalBytes,
       );

  const AppUpdateState.installing(InstalledApp? installed, AppUpdate update)
    : this(
        status: AppUpdateStatus.installing,
        installed: installed,
        update: update,
      );

  const AppUpdateState.failed(
    AppUpdateFailure failure, {
    InstalledApp? installed,
    AppUpdate? update,
  }) : this(
         status: AppUpdateStatus.failed,
         installed: installed,
         update: update,
         failure: failure,
       );

  bool get isBusy =>
      status == AppUpdateStatus.downloading ||
      status == AppUpdateStatus.installing;

  double? get progress {
    if (status != AppUpdateStatus.downloading || totalBytes <= 0) return null;
    return (receivedBytes / totalBytes).clamp(0.0, 1.0);
  }

  int get progressPercent => progress == null ? 0 : (progress! * 100).floor();

  String get transferredLabel {
    final transferred = (receivedBytes / (1024 * 1024)).round();
    final total = (totalBytes / (1024 * 1024)).round();
    return '$transferred of $total MB';
  }

  String get installedLabel => installed?.label ?? '—';
}
