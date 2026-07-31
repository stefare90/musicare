// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MusicAre';

  @override
  String get setupTitle => 'MusicAre Setup';

  @override
  String get welcomeTitle => 'Welcome to MusicAre';

  @override
  String get selectProviderSubtitle =>
      'Select a music metadata provider to get started';

  @override
  String get communityPluginsHeader => 'Community Plugins (GitHub)';

  @override
  String get installAndActivate => 'Install & Activate';

  @override
  String get installingPlugin => 'Installing and initializing plugin...';

  @override
  String get noPluginsFound =>
      'No plugins found on GitHub tagged with \"musicare-plugin\".';

  @override
  String get retry => 'Retry';

  @override
  String failedToFetchPlugins(String error) {
    return 'Failed to fetch online plugins: $error';
  }

  @override
  String get homeTab => 'Home';

  @override
  String get searchTab => 'Search';

  @override
  String get libraryTab => 'Library';
}
