sealed class AppUpdateFailure implements Exception {
  const AppUpdateFailure();
}

final class UpdateCheckFailed extends AppUpdateFailure {
  final int? statusCode;

  const UpdateCheckFailed({this.statusCode});

  @override
  String toString() =>
      'UpdateCheckFailed${statusCode == null ? '' : '($statusCode)'}';
}

final class UpdateDownloadFailed extends AppUpdateFailure {
  const UpdateDownloadFailed();

  @override
  String toString() => 'UpdateDownloadFailed';
}

final class UpdateCorrupted extends AppUpdateFailure {
  const UpdateCorrupted();

  @override
  String toString() => 'UpdateCorrupted';
}

final class UpdateRejected extends AppUpdateFailure {
  const UpdateRejected();

  @override
  String toString() => 'UpdateRejected';
}

final class UpdateInstallFailed extends AppUpdateFailure {
  const UpdateInstallFailed();

  @override
  String toString() => 'UpdateInstallFailed';
}
