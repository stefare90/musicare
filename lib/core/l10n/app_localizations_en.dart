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
  String get appSlogan => 'Music are the plugins. We are the player.';

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
  String get confirm => 'Confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String get homeTab => 'Home';

  @override
  String get searchTab => 'Search';

  @override
  String get libraryTab => 'Library';

  @override
  String get persistentPlayerArea => 'Persistent Mini Player Area';

  @override
  String get tooltipFavorite => 'Favorite';

  @override
  String get tooltipMoreOptions => 'More options';

  @override
  String get tooltipOptions => 'Options';

  @override
  String get savePlaylist => 'Save Playlist';

  @override
  String get sharePlaylist => 'Share Playlist';

  @override
  String get deletePlaylist => 'Delete Playlist';

  @override
  String get saveAlbum => 'Save Album';

  @override
  String get shareAlbum => 'Share Album';

  @override
  String get addToQueue => 'Add to Queue';

  @override
  String get saveToFavorites => 'Save to Favorites';

  @override
  String get goToAlbum => 'Go to Album';

  @override
  String get goToArtist => 'Go to Artist';

  @override
  String get unknownTitle => 'Unknown';

  @override
  String failedToFetchPlugins(Object error) {
    return 'Failed to fetch online plugins: $error';
  }

  @override
  String get pluginErrorIncompatibleSdkVersion =>
      'The plugin is incompatible with this version of MusicAre.';

  @override
  String get pluginErrorInvalidArchive =>
      'The plugin archive is corrupt or missing required files.';

  @override
  String get pluginErrorNotFound =>
      'Plugin files were not found on local disk.';

  @override
  String get pluginErrorNotLoaded => 'No active metadata plugin is loaded.';

  @override
  String get pluginErrorDownloadFailed => 'Failed to download the plugin file.';

  @override
  String get pluginErrorNetwork =>
      'Network error occurred. Please check your connection.';

  @override
  String get pluginErrorTimeout => 'Connection timed out. Please try again.';

  @override
  String get pluginErrorNoContext => 'Navigation context is unavailable.';

  @override
  String pluginErrorUnknown(Object details) {
    return 'An unexpected error occurred: $details';
  }

  @override
  String get noSectionsFound => 'No browse sections found.';

  @override
  String get noContentTitle => 'No Content Available';

  @override
  String get noContentSubtitle =>
      'Your active music provider did not return any browse sections. Try refreshing.';

  @override
  String get mediaTypePlaylist => 'Playlist';

  @override
  String get mediaTypeAlbum => 'Album';

  @override
  String get mediaTypeSingle => 'Single';

  @override
  String get mediaTypeCompilation => 'Compilation';

  @override
  String get mediaTypeTrack => 'Track';

  @override
  String get mediaTypeArtist => 'Artist';

  @override
  String get mediaTypeUnknown => '';
}
