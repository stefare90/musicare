import 'package:pub_semver/pub_semver.dart';

/// Null when either side is not valid SemVer, so a malformed manifest can
/// never win a "newer version" comparison.
int? comparePluginVersions(String a, String b) {
  try {
    return Version.parse(a).compareTo(Version.parse(b));
  } catch (_) {
    return null;
  }
}
