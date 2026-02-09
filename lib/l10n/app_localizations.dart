import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_cs.dart';
import 'app_localizations_de.dart';
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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('cs'),
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @app_name.
  ///
  /// In en, this message translates to:
  /// **'Florid'**
  String get app_name;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Florid'**
  String get welcome;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @updates.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get updates;

  /// No description provided for @installed.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get installed;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @install.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get install;

  /// No description provided for @uninstall.
  ///
  /// In en, this message translates to:
  /// **'Uninstall'**
  String get uninstall;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @update_available.
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get update_available;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading...'**
  String get downloading;

  /// No description provided for @install_permission_required.
  ///
  /// In en, this message translates to:
  /// **'Install permission is required'**
  String get install_permission_required;

  /// No description provided for @storage_permission_required.
  ///
  /// In en, this message translates to:
  /// **'Storage permission is required'**
  String get storage_permission_required;

  /// No description provided for @cancel_download.
  ///
  /// In en, this message translates to:
  /// **'Cancel Download'**
  String get cancel_download;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @permissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissions;

  /// No description provided for @screenshots.
  ///
  /// In en, this message translates to:
  /// **'Screenshots'**
  String get screenshots;

  /// No description provided for @no_version_available.
  ///
  /// In en, this message translates to:
  /// **'No Version Available'**
  String get no_version_available;

  /// No description provided for @app_information.
  ///
  /// In en, this message translates to:
  /// **'App Information'**
  String get app_information;

  /// No description provided for @package_name.
  ///
  /// In en, this message translates to:
  /// **'Package Name'**
  String get package_name;

  /// No description provided for @license.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get license;

  /// No description provided for @added.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get added;

  /// No description provided for @last_updated.
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get last_updated;

  /// No description provided for @version_information.
  ///
  /// In en, this message translates to:
  /// **'Version Information'**
  String get version_information;

  /// No description provided for @version_name.
  ///
  /// In en, this message translates to:
  /// **'Version Name'**
  String get version_name;

  /// No description provided for @version_code.
  ///
  /// In en, this message translates to:
  /// **'Version Code'**
  String get version_code;

  /// No description provided for @min_sdk.
  ///
  /// In en, this message translates to:
  /// **'Min SDK'**
  String get min_sdk;

  /// No description provided for @target_sdk.
  ///
  /// In en, this message translates to:
  /// **'Target SDK'**
  String get target_sdk;

  /// No description provided for @all_versions.
  ///
  /// In en, this message translates to:
  /// **'All Versions'**
  String get all_versions;

  /// No description provided for @latest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get latest;

  /// No description provided for @released.
  ///
  /// In en, this message translates to:
  /// **'Released'**
  String get released;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @source_code.
  ///
  /// In en, this message translates to:
  /// **'Source Code'**
  String get source_code;

  /// No description provided for @issue_tracker.
  ///
  /// In en, this message translates to:
  /// **'Issue Tracker'**
  String get issue_tracker;

  /// No description provided for @whats_new.
  ///
  /// In en, this message translates to:
  /// **'What\'s New'**
  String get whats_new;

  /// No description provided for @show_more.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get show_more;

  /// No description provided for @show_less.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get show_less;

  /// No description provided for @downloads_stats.
  ///
  /// In en, this message translates to:
  /// **'Downloads stats'**
  String get downloads_stats;

  /// No description provided for @last_day.
  ///
  /// In en, this message translates to:
  /// **'Last day'**
  String get last_day;

  /// No description provided for @last_30_days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get last_30_days;

  /// No description provided for @last_365_days.
  ///
  /// In en, this message translates to:
  /// **'Last 365 days'**
  String get last_365_days;

  /// No description provided for @not_available.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get not_available;

  /// No description provided for @download_failed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get download_failed;

  /// No description provided for @installation_failed.
  ///
  /// In en, this message translates to:
  /// **'Installation failed'**
  String get installation_failed;

  /// No description provided for @uninstall_failed.
  ///
  /// In en, this message translates to:
  /// **'Uninstall failed'**
  String get uninstall_failed;

  /// No description provided for @open_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open'**
  String get open_failed;

  /// No description provided for @device.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get device;

  /// No description provided for @recently_updated.
  ///
  /// In en, this message translates to:
  /// **'Recently Updated'**
  String get recently_updated;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @refreshing_data.
  ///
  /// In en, this message translates to:
  /// **'Refreshing data...'**
  String get refreshing_data;

  /// No description provided for @data_refreshed.
  ///
  /// In en, this message translates to:
  /// **'Data refreshed'**
  String get data_refreshed;

  /// No description provided for @refresh_failed.
  ///
  /// In en, this message translates to:
  /// **'Refresh failed'**
  String get refresh_failed;

  /// No description provided for @loading_latest_apps.
  ///
  /// In en, this message translates to:
  /// **'Loading latest apps...'**
  String get loading_latest_apps;

  /// No description provided for @latest_apps.
  ///
  /// In en, this message translates to:
  /// **'Latest Apps'**
  String get latest_apps;

  /// No description provided for @no_apps_found.
  ///
  /// In en, this message translates to:
  /// **'No apps found'**
  String get no_apps_found;

  /// No description provided for @searching.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searching;

  /// No description provided for @setup_failed.
  ///
  /// In en, this message translates to:
  /// **'Setup failed'**
  String get setup_failed;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @manage_repositories.
  ///
  /// In en, this message translates to:
  /// **'Manage Repositories'**
  String get manage_repositories;

  /// No description provided for @enable_disable.
  ///
  /// In en, this message translates to:
  /// **'Enable/Disable'**
  String get enable_disable;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @delete_repository.
  ///
  /// In en, this message translates to:
  /// **'Delete Repository'**
  String get delete_repository;

  /// Confirmation message for deleting a repository. {name} is the repository name.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove \"{name}\"?'**
  String delete_repository_confirm(Object name, Object repository);

  /// No description provided for @updating_repository.
  ///
  /// In en, this message translates to:
  /// **'Updating Repository'**
  String get updating_repository;

  /// No description provided for @touch_grass_message.
  ///
  /// In en, this message translates to:
  /// **'Now is a great time to touch grass!'**
  String get touch_grass_message;

  /// No description provided for @add_repository.
  ///
  /// In en, this message translates to:
  /// **'Add Repository'**
  String get add_repository;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @enter_repository_name.
  ///
  /// In en, this message translates to:
  /// **'Please enter a repository name'**
  String get enter_repository_name;

  /// No description provided for @enter_repository_url.
  ///
  /// In en, this message translates to:
  /// **'Please enter a repository URL'**
  String get enter_repository_url;

  /// No description provided for @edit_repository.
  ///
  /// In en, this message translates to:
  /// **'Edit Repository'**
  String get edit_repository;

  /// No description provided for @loading_apps.
  ///
  /// In en, this message translates to:
  /// **'Loading apps...'**
  String get loading_apps;

  /// Message shown when no apps are found in a category. {category} is the category name.
  ///
  /// In en, this message translates to:
  /// **'No apps found in {category}'**
  String no_apps_in_category(Object category);

  /// No description provided for @loading_categories.
  ///
  /// In en, this message translates to:
  /// **'Loading categories...'**
  String get loading_categories;

  /// No description provided for @no_categories_found.
  ///
  /// In en, this message translates to:
  /// **'No categories found'**
  String get no_categories_found;
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
      <String>['cs', 'de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'cs':
      return AppLocalizationsCs();
    case 'de':
      return AppLocalizationsDe();
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
