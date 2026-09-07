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
  String failedToFetchPlugins(String error) {
    return 'Failed to fetch online plugins: $error';
  }

  @override
  String get pluginErrorIncompatibleSdkVersion =>
      'The plugin is incompatible with this version of MusicAre.';

  @override
  String get pluginErrorInvalidType => 'Plugin type is invalid.';

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
  String pluginErrorUnknown(String details) {
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
  String get copyError => 'Copy full Error';

  @override
  String get moreTracks => 'More tracks';

  @override
  String get errorCopiedToClipboard => 'Error copied to clipboard!';

  @override
  String get mediaTypeUnknown => '';

  @override
  String get actionRequiredTitle => 'Action Required';

  @override
  String get obsoleteProviderLabel => 'Obsolete Provider';

  @override
  String installedVersion(String version) {
    return 'Installed version: v$version';
  }

  @override
  String get providerIncompatibleMessage =>
      'This provider is no longer compatible with the current version of MusicAre and must be updated to continue.';

  @override
  String activeProviderName(String name) {
    return 'Active Provider: $name';
  }

  @override
  String providerVersion(String version) {
    return 'Version $version';
  }

  @override
  String get disconnect => 'Disconnect';

  @override
  String get updateAndActivate => 'Update & Activate';

  @override
  String get activeProvider => 'Active Provider';

  @override
  String byAuthor(String author) {
    return 'By $author';
  }

  @override
  String get updateRequiredMessage =>
      'Update required for this version of MusicAre';

  @override
  String get ok => 'OK';

  @override
  String get error => 'Error';

  @override
  String get popularTracks => 'Popular Tracks';

  @override
  String get discography => 'Discography';

  @override
  String get fansAlsoLike => 'Fans Also Like';

  @override
  String get viewLog => 'View Log';

  @override
  String get refresh => 'Refresh';

  @override
  String logErrorTitle(String title) {
    return '$title - Log';
  }

  @override
  String get selectMetadataProvider => 'Select Metadata Provider';

  @override
  String get continueToAudioSource => 'Continue to Audio Source';

  @override
  String get finishSetup => 'Finish Setup';

  @override
  String get welcomeSetupHint =>
      'Configure your music catalog and audio stream providers in two quick steps to get started.';

  @override
  String get onboardingStepMetadata => 'Metadata Provider';

  @override
  String get onboardingStepAudioSource => 'Audio Stream Provider';

  @override
  String get selectProviderSubtitle =>
      'Select a music catalog provider to discover albums, artists, and playlists';

  @override
  String get selectAudioSourceSubtitle =>
      'Select an audio stream provider to enable music playback';

  @override
  String get activeLabel => 'Active';
}
