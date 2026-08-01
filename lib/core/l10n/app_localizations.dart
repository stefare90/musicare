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

  /// No description provided for @pluginErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred: {details}'**
  String pluginErrorUnknown(String details);
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
