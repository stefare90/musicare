import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'MusicAre'**
  String get appTitle;

  /// No description provided for @appSlogan.
  ///
  /// In en, this message translates to:
  /// **'Music are the plugins. We are the player.'**
  String get appSlogan;

  /// No description provided for @setupTitle.
  ///
  /// In en, this message translates to:
  /// **'MusicAre Setup'**
  String get setupTitle;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to MusicAre'**
  String get welcomeTitle;

  /// No description provided for @communityPluginsHeader.
  ///
  /// In en, this message translates to:
  /// **'Community Plugins (GitHub)'**
  String get communityPluginsHeader;

  /// No description provided for @installAndActivate.
  ///
  /// In en, this message translates to:
  /// **'Install & Activate'**
  String get installAndActivate;

  /// No description provided for @installingPlugin.
  ///
  /// In en, this message translates to:
  /// **'Installing and initializing plugin...'**
  String get installingPlugin;

  /// No description provided for @noPluginsFound.
  ///
  /// In en, this message translates to:
  /// **'No plugins found on GitHub tagged with \"musicare-plugin\".'**
  String get noPluginsFound;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @authFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authFormTitle;

  /// No description provided for @authFormSubmit.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authFormSubmit;

  /// No description provided for @authFormHelpAction.
  ///
  /// In en, this message translates to:
  /// **'Where do I find it?'**
  String get authFormHelpAction;

  /// No description provided for @authFormHelpFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link. Please try again.'**
  String get authFormHelpFailed;

  /// No description provided for @authSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Metadata sign-in failed. Please check your details and try again.'**
  String get authSignInFailed;

  /// No description provided for @accountTooltip.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTooltip;

  /// No description provided for @accountNotSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get accountNotSignedIn;

  /// No description provided for @accountSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get accountSignIn;

  /// No description provided for @accountSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get accountSignedIn;

  /// No description provided for @accountSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountSignOut;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsPluginsSection.
  ///
  /// In en, this message translates to:
  /// **'Plugins'**
  String get settingsPluginsSection;

  /// No description provided for @settingsNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get settingsNotConfigured;

  /// No description provided for @pluginTypeMetadata.
  ///
  /// In en, this message translates to:
  /// **'Metadata'**
  String get pluginTypeMetadata;

  /// No description provided for @pluginTypeAudioSource.
  ///
  /// In en, this message translates to:
  /// **'Audio source'**
  String get pluginTypeAudioSource;

  /// No description provided for @pluginVersionSection.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get pluginVersionSection;

  /// No description provided for @pluginVersionInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed version'**
  String get pluginVersionInstalled;

  /// No description provided for @pluginVersionSdk.
  ///
  /// In en, this message translates to:
  /// **'Plugin SDK'**
  String get pluginVersionSdk;

  /// No description provided for @pluginAccountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get pluginAccountSection;

  /// No description provided for @libraryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing saved yet'**
  String get libraryEmptyTitle;

  /// No description provided for @libraryEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Tracks, albums, artists and playlists you save will appear here.'**
  String get libraryEmptyMessage;

  /// No description provided for @homeTab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTab;

  /// No description provided for @searchTab.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTab;

  /// No description provided for @libraryTab.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libraryTab;

  /// No description provided for @persistentPlayerArea.
  ///
  /// In en, this message translates to:
  /// **'Persistent Mini Player Area'**
  String get persistentPlayerArea;

  /// No description provided for @tooltipFavorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get tooltipFavorite;

  /// No description provided for @tooltipMoreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get tooltipMoreOptions;

  /// No description provided for @tooltipOptions.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get tooltipOptions;

  /// No description provided for @savePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Save Playlist'**
  String get savePlaylist;

  /// No description provided for @sharePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Share Playlist'**
  String get sharePlaylist;

  /// No description provided for @deletePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Delete Playlist'**
  String get deletePlaylist;

  /// No description provided for @saveAlbum.
  ///
  /// In en, this message translates to:
  /// **'Save Album'**
  String get saveAlbum;

  /// No description provided for @shareAlbum.
  ///
  /// In en, this message translates to:
  /// **'Share Album'**
  String get shareAlbum;

  /// No description provided for @addToQueue.
  ///
  /// In en, this message translates to:
  /// **'Add to Queue'**
  String get addToQueue;

  /// No description provided for @saveToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Save to Favorites'**
  String get saveToFavorites;

  /// No description provided for @goToAlbum.
  ///
  /// In en, this message translates to:
  /// **'Go to Album'**
  String get goToAlbum;

  /// No description provided for @goToArtist.
  ///
  /// In en, this message translates to:
  /// **'Go to Artist'**
  String get goToArtist;

  /// No description provided for @unknownTitle.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownTitle;

  /// No description provided for @failedToFetchPlugins.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch online plugins: {error}'**
  String failedToFetchPlugins(Object error);

  /// No description provided for @pluginErrorIncompatibleSdkVersion.
  ///
  /// In en, this message translates to:
  /// **'The plugin is incompatible with this version of MusicAre.'**
  String get pluginErrorIncompatibleSdkVersion;

  /// No description provided for @pluginErrorInvalidType.
  ///
  /// In en, this message translates to:
  /// **'Plugin type is invalid.'**
  String get pluginErrorInvalidType;

  /// No description provided for @pluginErrorInvalidArchive.
  ///
  /// In en, this message translates to:
  /// **'The plugin archive is corrupt or missing required files.'**
  String get pluginErrorInvalidArchive;

  /// No description provided for @pluginErrorNotFound.
  ///
  /// In en, this message translates to:
  /// **'Plugin files were not found on local disk.'**
  String get pluginErrorNotFound;

  /// No description provided for @pluginErrorResourceNotFound.
  ///
  /// In en, this message translates to:
  /// **'The requested item was not found.'**
  String get pluginErrorResourceNotFound;

  /// No description provided for @pluginErrorNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'No active metadata plugin is loaded.'**
  String get pluginErrorNotLoaded;

  /// No description provided for @pluginErrorDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to download the plugin file.'**
  String get pluginErrorDownloadFailed;

  /// No description provided for @pluginErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error occurred. Please check your connection.'**
  String get pluginErrorNetwork;

  /// No description provided for @pluginErrorTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connection timed out. Please try again.'**
  String get pluginErrorTimeout;

  /// No description provided for @pluginErrorNoContext.
  ///
  /// In en, this message translates to:
  /// **'Navigation context is unavailable.'**
  String get pluginErrorNoContext;

  /// No description provided for @pluginErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred: {details}'**
  String pluginErrorUnknown(Object details);

  /// No description provided for @pluginErrorStreamResolution.
  ///
  /// In en, this message translates to:
  /// **'No playable audio stream could be found for this track.'**
  String get pluginErrorStreamResolution;

  /// No description provided for @pluginErrorAuthRequired.
  ///
  /// In en, this message translates to:
  /// **'Metadata sign-in required.'**
  String get pluginErrorAuthRequired;

  /// No description provided for @noSectionsFound.
  ///
  /// In en, this message translates to:
  /// **'No browse sections found.'**
  String get noSectionsFound;

  /// No description provided for @noContentTitle.
  ///
  /// In en, this message translates to:
  /// **'No Content Available'**
  String get noContentTitle;

  /// No description provided for @noContentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your active music provider did not return any browse sections. Try refreshing.'**
  String get noContentSubtitle;

  /// No description provided for @mediaTypePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get mediaTypePlaylist;

  /// No description provided for @mediaTypeAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get mediaTypeAlbum;

  /// No description provided for @mediaTypeSingle.
  ///
  /// In en, this message translates to:
  /// **'Single'**
  String get mediaTypeSingle;

  /// No description provided for @mediaTypeCompilation.
  ///
  /// In en, this message translates to:
  /// **'Compilation'**
  String get mediaTypeCompilation;

  /// No description provided for @mediaTypeTrack.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get mediaTypeTrack;

  /// No description provided for @mediaTypeArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get mediaTypeArtist;

  /// No description provided for @copyError.
  ///
  /// In en, this message translates to:
  /// **'Copy full Error'**
  String get copyError;

  /// No description provided for @moreTracks.
  ///
  /// In en, this message translates to:
  /// **'More tracks'**
  String get moreTracks;

  /// No description provided for @errorCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Error copied to clipboard!'**
  String get errorCopiedToClipboard;

  /// No description provided for @mediaTypeUnknown.
  ///
  /// In en, this message translates to:
  /// **''**
  String get mediaTypeUnknown;

  /// No description provided for @actionRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Action Required'**
  String get actionRequiredTitle;

  /// No description provided for @obsoleteProviderLabel.
  ///
  /// In en, this message translates to:
  /// **'Obsolete Provider'**
  String get obsoleteProviderLabel;

  /// No description provided for @installedVersion.
  ///
  /// In en, this message translates to:
  /// **'Installed version: v{version}'**
  String installedVersion(Object version);

  /// No description provided for @providerIncompatibleMessage.
  ///
  /// In en, this message translates to:
  /// **'This provider is no longer compatible with the current version of MusicAre and must be updated to continue.'**
  String get providerIncompatibleMessage;

  /// No description provided for @activeProviderName.
  ///
  /// In en, this message translates to:
  /// **'Active Provider: {name}'**
  String activeProviderName(Object name);

  /// No description provided for @providerVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String providerVersion(Object version);

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @updateAndActivate.
  ///
  /// In en, this message translates to:
  /// **'Update & Activate'**
  String get updateAndActivate;

  /// No description provided for @activeProvider.
  ///
  /// In en, this message translates to:
  /// **'Active Provider'**
  String get activeProvider;

  /// No description provided for @byAuthor.
  ///
  /// In en, this message translates to:
  /// **'By {author}'**
  String byAuthor(Object author);

  /// No description provided for @updateRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Update required for this version of MusicAre'**
  String get updateRequiredMessage;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @popularTracks.
  ///
  /// In en, this message translates to:
  /// **'Popular Tracks'**
  String get popularTracks;

  /// No description provided for @discography.
  ///
  /// In en, this message translates to:
  /// **'Discography'**
  String get discography;

  /// No description provided for @fansAlsoLike.
  ///
  /// In en, this message translates to:
  /// **'Fans Also Like'**
  String get fansAlsoLike;

  /// No description provided for @viewLog.
  ///
  /// In en, this message translates to:
  /// **'View Log'**
  String get viewLog;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @logErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'{title} - Log'**
  String logErrorTitle(Object title);

  /// No description provided for @selectMetadataProvider.
  ///
  /// In en, this message translates to:
  /// **'Select Metadata Provider'**
  String get selectMetadataProvider;

  /// No description provided for @continueToAudioSource.
  ///
  /// In en, this message translates to:
  /// **'Continue to Audio Source'**
  String get continueToAudioSource;

  /// No description provided for @finishSetup.
  ///
  /// In en, this message translates to:
  /// **'Finish Setup'**
  String get finishSetup;

  /// No description provided for @welcomeSetupHint.
  ///
  /// In en, this message translates to:
  /// **'Configure your music catalog and audio stream providers in two quick steps to get started.'**
  String get welcomeSetupHint;

  /// No description provided for @onboardingStepMetadata.
  ///
  /// In en, this message translates to:
  /// **'Metadata Provider'**
  String get onboardingStepMetadata;

  /// No description provided for @onboardingStepAudioSource.
  ///
  /// In en, this message translates to:
  /// **'Audio Stream Provider'**
  String get onboardingStepAudioSource;

  /// No description provided for @selectProviderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select a music catalog provider to discover albums, artists, and playlists'**
  String get selectProviderSubtitle;

  /// No description provided for @selectAudioSourceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select an audio stream provider to enable music playback'**
  String get selectAudioSourceSubtitle;

  /// No description provided for @activeLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeLabel;

  /// No description provided for @playbackQueue.
  ///
  /// In en, this message translates to:
  /// **'Playback Queue'**
  String get playbackQueue;

  /// No description provided for @queueEmpty.
  ///
  /// In en, this message translates to:
  /// **'Queue is empty'**
  String get queueEmpty;

  /// No description provided for @audioStreamCandidates.
  ///
  /// In en, this message translates to:
  /// **'Audio Stream Candidates'**
  String get audioStreamCandidates;

  /// No description provided for @availableStreamsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} available stream(s)'**
  String availableStreamsCount(Object count);

  /// No description provided for @candidateStreamTitle.
  ///
  /// In en, this message translates to:
  /// **'Candidate #{index} ({codec} • {bitrate})'**
  String candidateStreamTitle(Object bitrate, Object codec, Object index);

  /// No description provided for @lyricsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Lyrics coming soon'**
  String get lyricsComingSoon;

  /// No description provided for @downloadComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Download coming soon'**
  String get downloadComingSoon;

  /// No description provided for @selectArtistTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Artist'**
  String get selectArtistTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search songs, albums, artists...'**
  String get searchHint;

  /// No description provided for @searchEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Search Music'**
  String get searchEmptyTitle;

  /// No description provided for @searchEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Type above to search songs, albums, artists, and playlists.'**
  String get searchEmptySubtitle;

  /// No description provided for @searchNoResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No Results Found'**
  String get searchNoResultsTitle;

  /// No description provided for @searchNoResultsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try searching for a different keyword or check your spelling.'**
  String get searchNoResultsSubtitle;

  /// No description provided for @searchAllChip.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get searchAllChip;

  /// No description provided for @searchTracksHeader.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get searchTracksHeader;

  /// No description provided for @searchAlbumsHeader.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get searchAlbumsHeader;

  /// No description provided for @searchArtistsHeader.
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get searchArtistsHeader;

  /// No description provided for @searchPlaylistsHeader.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get searchPlaylistsHeader;

  /// No description provided for @likedSongs.
  ///
  /// In en, this message translates to:
  /// **'Liked Songs'**
  String get likedSongs;

  /// No description provided for @libraryPlaylistsTab.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get libraryPlaylistsTab;

  /// No description provided for @libraryAlbumsTab.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get libraryAlbumsTab;

  /// No description provided for @libraryArtistsTab.
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get libraryArtistsTab;

  /// No description provided for @librarySignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see your library'**
  String get librarySignInTitle;

  /// No description provided for @librarySignInMessage.
  ///
  /// In en, this message translates to:
  /// **'Your liked songs, playlists, albums and artists will appear here.'**
  String get librarySignInMessage;

  /// No description provided for @libraryAlbumsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved albums'**
  String get libraryAlbumsEmpty;

  /// No description provided for @libraryAlbumsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Albums you save will appear here.'**
  String get libraryAlbumsEmptyMessage;

  /// No description provided for @libraryArtistsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved artists'**
  String get libraryArtistsEmpty;

  /// No description provided for @libraryArtistsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Artists you follow will appear here.'**
  String get libraryArtistsEmptyMessage;

  /// No description provided for @likedSongsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No liked songs yet'**
  String get likedSongsEmptyTitle;

  /// No description provided for @likedSongsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Songs you like will appear here.'**
  String get likedSongsEmptyMessage;

  /// No description provided for @downloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// No description provided for @downloadsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No downloads yet'**
  String get downloadsEmptyTitle;

  /// No description provided for @downloadsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Tracks and playlists you download will appear here.'**
  String get downloadsEmptyMessage;

  /// No description provided for @removeAlbum.
  ///
  /// In en, this message translates to:
  /// **'Remove Album'**
  String get removeAlbum;

  /// No description provided for @removePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Remove Playlist'**
  String get removePlaylist;

  /// No description provided for @removeArtist.
  ///
  /// In en, this message translates to:
  /// **'Remove Artist'**
  String get removeArtist;

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from Favorites'**
  String get removeFromFavorites;

  /// No description provided for @addToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add to Playlist'**
  String get addToPlaylist;

  /// No description provided for @newPlaylist.
  ///
  /// In en, this message translates to:
  /// **'New playlist'**
  String get newPlaylist;

  /// No description provided for @playlistNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get playlistNameLabel;

  /// No description provided for @playlistDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get playlistDescriptionLabel;

  /// No description provided for @playlistPublicLabel.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get playlistPublicLabel;

  /// No description provided for @playlistPrivateLabel.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get playlistPrivateLabel;

  /// No description provided for @createPlaylistAction.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createPlaylistAction;

  /// No description provided for @playlistCreated.
  ///
  /// In en, this message translates to:
  /// **'Playlist created'**
  String get playlistCreated;

  /// No description provided for @playlistCreatedAndTrackAdded.
  ///
  /// In en, this message translates to:
  /// **'Playlist created and track added'**
  String get playlistCreatedAndTrackAdded;

  /// No description provided for @playlistCreatedTrackNotAdded.
  ///
  /// In en, this message translates to:
  /// **'Playlist created, but the track could not be added'**
  String get playlistCreatedTrackNotAdded;

  /// No description provided for @addedToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Added to {playlist}'**
  String addedToPlaylist(Object playlist);

  /// No description provided for @removedFromPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Removed from {playlist}'**
  String removedFromPlaylist(Object playlist);

  /// No description provided for @addedToQueue.
  ///
  /// In en, this message translates to:
  /// **'Added to queue'**
  String get addedToQueue;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @removeFromPlaylistTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove from playlist?'**
  String get removeFromPlaylistTitle;

  /// No description provided for @removeFromPlaylistMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{track}\" from this playlist?'**
  String removeFromPlaylistMessage(Object track);

  /// No description provided for @deletePlaylistTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete playlist?'**
  String get deletePlaylistTitle;

  /// No description provided for @deletePlaylistMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{playlist}\"? This can\'t be undone.'**
  String deletePlaylistMessage(Object playlist);

  /// No description provided for @noPlaylistsYet.
  ///
  /// In en, this message translates to:
  /// **'No playlists yet'**
  String get noPlaylistsYet;

  /// No description provided for @noPlaylistsYetMessage.
  ///
  /// In en, this message translates to:
  /// **'Create a playlist to start collecting tracks.'**
  String get noPlaylistsYetMessage;

  /// No description provided for @playlistsSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to add tracks to playlists'**
  String get playlistsSignInTitle;

  /// No description provided for @pluginErrorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'The provider is limiting requests. Please try again shortly.'**
  String get pluginErrorRateLimited;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
