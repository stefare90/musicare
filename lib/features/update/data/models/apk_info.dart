class ApkInfo {
  final String packageName;
  final int versionCode;
  final String certSha256;

  const ApkInfo({
    required this.packageName,
    required this.versionCode,
    required this.certSha256,
  });

  static ApkInfo? fromMethodResult(Object? value) {
    if (value is! Map) return null;
    final packageName = value['packageName'];
    final versionCode = value['versionCode'];
    final certSha256 = value['certSha256'];
    if (packageName is! String || versionCode is! int) return null;
    if (certSha256 is! String) return null;
    return ApkInfo(
      packageName: packageName,
      versionCode: versionCode,
      certSha256: certSha256.toLowerCase(),
    );
  }
}
