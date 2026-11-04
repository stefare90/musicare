/// Contract with the Android side (`MainActivity.kt`). The method names and
/// the channel name must match the Kotlin constants.
abstract class AppUpdateChannel {
  static const String name = 'com.musicare.app_update';
  static const String updatesDir = 'updatesDir';
  static const String signature = 'signature';
  static const String apkInfo = 'apkInfo';
  static const String install = 'install';
}
