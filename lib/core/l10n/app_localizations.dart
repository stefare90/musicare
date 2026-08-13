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

  /// No description provided for @selectProviderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select a music metadata provider to get started'**
  String get selectProviderSubtitle;

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
  String failedToFetchPlugins(String error);

  /// No description provided for @pluginErrorIncompatibleSdkVersion.
  ///
  /// In en, this message translates to:
  /// **'The plugin is incompatible with this version of MusicAre.'**
  String get pluginErrorIncompatibleSdkVersion;

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
  String pluginErrorUnknown(String details);

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
  String installedVersion(String version);

  /// No description provided for @providerIncompatibleMessage.
  ///
  /// In en, this message translates to:
  /// **'This provider is no longer compatible with the current version of MusicAre and must be updated to continue.'**
  String get providerIncompatibleMessage;

  /// No description provided for @activeProviderName.
  ///
  /// In en, this message translates to:
  /// **'Active Provider: {name}'**
  String activeProviderName(String name);

  /// No description provided for @providerVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String providerVersion(String version);

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
  String byAuthor(String author);

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
  /// **'\'Error'**
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
  String logErrorTitle(String title);
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
