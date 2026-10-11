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
  String get authFormTitle => 'Sign in';

  @override
  String get authFormSubmit => 'Sign in';

  @override
  String get authFormHelpAction => 'Where do I find it?';

  @override
  String get authFormHelpFailed => 'Could not open the link. Please try again.';

  @override
  String get authSignInFailed =>
      'Metadata sign-in failed. Please check your details and try again.';

  @override
  String get accountTooltip => 'Account';

  @override
  String get accountNotSignedIn => 'Not signed in';

  @override
  String get accountSignIn => 'Sign in';

  @override
  String get accountSignedIn => 'Signed in';

  @override
  String get accountSignOut => 'Sign out';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsPluginsSection => 'Plugins';

  @override
  String get settingsNotConfigured => 'Not configured';

  @override
  String get pluginTypeMetadata => 'Metadata';

  @override
  String get pluginTypeAudioSource => 'Audio source';

  @override
  String get pluginVersionSection => 'Version';

  @override
  String get pluginVersionInstalled => 'Installed version';

  @override
  String get pluginVersionSdk => 'Plugin SDK';

  @override
  String get pluginAccountSection => 'Account';

  @override
  String get libraryEmptyTitle => 'Nothing saved yet';

  @override
  String get libraryEmptyMessage =>
      'Tracks, albums, artists and playlists you save will appear here.';

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
  String get playNext => 'Play Next';

  @override
  String get addedToPlayNext => 'Will play next';

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
  String get pluginErrorInvalidType => 'Plugin type is invalid.';

  @override
  String get pluginErrorInvalidArchive =>
      'The plugin archive is corrupt or missing required files.';

  @override
  String get pluginErrorNotFound =>
      'Plugin files were not found on local disk.';

  @override
  String get pluginErrorResourceNotFound => 'The requested item was not found.';

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
  String get pluginErrorStreamResolution =>
      'No playable audio stream could be found for this track.';

  @override
  String get pluginErrorAuthRequired => 'Metadata sign-in required.';

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
  String installedVersion(Object version) {
    return 'Installed version: v$version';
  }

  @override
  String get providerIncompatibleMessage =>
      'This provider is no longer compatible with the current version of MusicAre and must be updated to continue.';

  @override
  String activeProviderName(Object name) {
    return 'Active Provider: $name';
  }

  @override
  String providerVersion(Object version) {
    return 'Version $version';
  }

  @override
  String get disconnect => 'Disconnect';

  @override
  String get updateAndActivate => 'Update & Activate';

  @override
  String get activeProvider => 'Active Provider';

  @override
  String byAuthor(Object author) {
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
  String logErrorTitle(Object title) {
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

  @override
  String get playbackQueue => 'Playback Queue';

  @override
  String get queueEmpty => 'Queue is empty';

  @override
  String get audioStreamCandidates => 'Audio Stream Candidates';

  @override
  String availableStreamsCount(Object count) {
    return '$count available stream(s)';
  }

  @override
  String candidateStreamTitle(Object bitrate, Object codec, Object index) {
    return 'Candidate #$index ($codec • $bitrate)';
  }

  @override
  String get lyricsComingSoon => 'Lyrics coming soon';

  @override
  String get downloadComingSoon => 'Download coming soon';

  @override
  String get selectArtistTitle => 'Select Artist';

  @override
  String get searchHint => 'Search songs, albums, artists...';

  @override
  String get searchEmptyTitle => 'Search Music';

  @override
  String get searchEmptySubtitle =>
      'Type above to search songs, albums, artists, and playlists.';

  @override
  String get searchNoResultsTitle => 'No Results Found';

  @override
  String get searchNoResultsSubtitle =>
      'Try searching for a different keyword or check your spelling.';

  @override
  String get searchAllChip => 'All';

  @override
  String get searchTracksHeader => 'Songs';

  @override
  String get searchAlbumsHeader => 'Albums';

  @override
  String get searchArtistsHeader => 'Artists';

  @override
  String get searchPlaylistsHeader => 'Playlists';

  @override
  String get likedSongs => 'Liked Songs';

  @override
  String get libraryPlaylistsTab => 'Playlists';

  @override
  String get libraryAlbumsTab => 'Albums';

  @override
  String get libraryArtistsTab => 'Artists';

  @override
  String get librarySignInTitle => 'Sign in to see your library';

  @override
  String get librarySignInMessage =>
      'Your liked songs, playlists, albums and artists will appear here.';

  @override
  String get libraryAlbumsEmpty => 'No saved albums';

  @override
  String get libraryAlbumsEmptyMessage => 'Albums you save will appear here.';

  @override
  String get libraryArtistsEmpty => 'No saved artists';

  @override
  String get libraryArtistsEmptyMessage =>
      'Artists you follow will appear here.';

  @override
  String get likedSongsEmptyTitle => 'No liked songs yet';

  @override
  String get likedSongsEmptyMessage => 'Songs you like will appear here.';

  @override
  String get downloads => 'Downloads';

  @override
  String get downloadsEmptyTitle => 'No downloads yet';

  @override
  String get downloadsEmptyMessage =>
      'Tracks and playlists you download will appear here.';

  @override
  String get removeAlbum => 'Remove Album';

  @override
  String get removePlaylist => 'Remove Playlist';

  @override
  String get removeArtist => 'Remove Artist';

  @override
  String get removeFromFavorites => 'Remove from Favorites';

  @override
  String get addToPlaylist => 'Add to Playlist';

  @override
  String get newPlaylist => 'New playlist';

  @override
  String get playlistNameLabel => 'Name';

  @override
  String get playlistDescriptionLabel => 'Description';

  @override
  String get playlistPublicLabel => 'Public';

  @override
  String get playlistPrivateLabel => 'Private';

  @override
  String get createPlaylistAction => 'Create';

  @override
  String get playlistCreated => 'Playlist created';

  @override
  String get playlistCreatedAndTrackAdded => 'Playlist created and track added';

  @override
  String get playlistCreatedTrackNotAdded =>
      'Playlist created, but the track could not be added';

  @override
  String addedToPlaylist(Object playlist) {
    return 'Added to $playlist';
  }

  @override
  String alreadyInPlaylist(Object playlist) {
    return 'Already in $playlist';
  }

  @override
  String removedFromPlaylist(Object playlist) {
    return 'Removed from $playlist';
  }

  @override
  String get addedToQueue => 'Added to queue';

  @override
  String get remove => 'Remove';

  @override
  String get removeFromPlaylistTitle => 'Remove from playlist?';

  @override
  String removeFromPlaylistMessage(Object track) {
    return 'Remove \"$track\" from this playlist?';
  }

  @override
  String get deletePlaylistTitle => 'Delete playlist?';

  @override
  String deletePlaylistMessage(Object playlist) {
    return 'Delete \"$playlist\"? This can\'t be undone.';
  }

  @override
  String get noPlaylistsYet => 'No playlists yet';

  @override
  String get noPlaylistsYetMessage =>
      'Create a playlist to start collecting tracks.';

  @override
  String get playlistsSignInTitle => 'Sign in to add tracks to playlists';

  @override
  String get pluginErrorRateLimited =>
      'The provider is limiting requests. Please try again shortly.';
}
