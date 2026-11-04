class InstalledApp {
  final String packageName;
  final String versionName;
  final int versionCode;

  const InstalledApp({
    required this.packageName,
    required this.versionName,
    required this.versionCode,
  });

  String get label => 'v$versionName ($versionCode)';
}
