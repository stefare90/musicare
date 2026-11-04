class AppUpdate {
  static final RegExp _tagPattern = RegExp(r'^v(\d+\.\d+\.\d+)\+(\d+)$');
  static final RegExp _digestPattern = RegExp(r'^sha256:([0-9a-fA-F]{64})$');

  final String versionName;
  final int versionCode;
  final Uri apkUri;
  final int apkSize;
  final String sha256;

  const AppUpdate({
    required this.versionName,
    required this.versionCode,
    required this.apkUri,
    required this.apkSize,
    required this.sha256,
  });

  String get sizeLabel => '${(apkSize / (1024 * 1024)).round()} MB';

  static AppUpdate? fromRelease(
    Map<String, dynamic> release, {
    required int installedVersionCode,
  }) {
    final tag = release['tag_name'];
    if (tag is! String) return null;
    final tagMatch = _tagPattern.firstMatch(tag);
    if (tagMatch == null) return null;

    final versionName = tagMatch.group(1)!;
    final versionCode = int.parse(tagMatch.group(2)!);
    if (versionCode <= installedVersionCode) return null;

    final assets = release['assets'];
    if (assets is! List) return null;
    for (final asset in assets) {
      if (asset is! Map) continue;
      final name = asset['name'];
      final size = asset['size'];
      final digest = asset['digest'];
      final downloadUrl = asset['browser_download_url'];
      if (name is! String || !name.toLowerCase().endsWith('.apk')) continue;
      if (size is! int || size <= 0) continue;
      if (digest is! String) continue;
      if (downloadUrl is! String) continue;

      final digestMatch = _digestPattern.firstMatch(digest);
      final uri = Uri.tryParse(downloadUrl);
      if (digestMatch == null || uri == null) continue;

      return AppUpdate(
        versionName: versionName,
        versionCode: versionCode,
        apkUri: uri,
        apkSize: size,
        sha256: digestMatch.group(1)!.toLowerCase(),
      );
    }
    return null;
  }
}
