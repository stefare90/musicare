import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:music_are/core/config/app_assets.dart';
import 'package:music_are/core/config/app_info.dart';

abstract class AppLicense {
  static const String spdx = 'BSD-3-Clause';

  /// Registers the repository LICENSE (bundled as an asset) so the standard
  /// Flutter license page lists it next to the package licenses.
  static void register() {
    LicenseRegistry.addLicense(() async* {
      final text = await rootBundle.loadString(AppAssets.license);
      yield LicenseEntryWithLineBreaks([AppInfo.name], text);
    });
  }
}
