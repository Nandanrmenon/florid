import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_cs.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

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
    Locale('zh'),
    Locale('zh', 'CN'),
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

  /// No description provided for @on_device.
  ///
  /// In en, this message translates to:
  /// **'On Device'**
  String get on_device;

  /// No description provided for @favourites.
  ///
  /// In en, this message translates to:
  /// **'Favourites'**
  String get favourites;

  /// No description provided for @loading_repository.
  ///
  /// In en, this message translates to:
  /// **'Loading repository…'**
  String get loading_repository;

  /// No description provided for @unable_to_load_repository.
  ///
  /// In en, this message translates to:
  /// **'Unable to load repository'**
  String get unable_to_load_repository;

  /// No description provided for @repository_loading_error_descrption.
  ///
  /// In en, this message translates to:
  /// **'Check your connection or repository settings, then try again.'**
  String get repository_loading_error_descrption;

  /// No description provided for @appUpdateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get appUpdateAvailable;

  /// No description provided for @releaseNotes.
  ///
  /// In en, this message translates to:
  /// **'Release Notes'**
  String get releaseNotes;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @viewOnGithub.
  ///
  /// In en, this message translates to:
  /// **'View on GitHub'**
  String get viewOnGithub;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @installing.
  ///
  /// In en, this message translates to:
  /// **'Installing...'**
  String get installing;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to download APK'**
  String get downloadFailed;

  /// No description provided for @remove_from_favourites.
  ///
  /// In en, this message translates to:
  /// **'Remove from Favourites'**
  String get remove_from_favourites;

  /// No description provided for @add_to_favourites.
  ///
  /// In en, this message translates to:
  /// **'Add to Favourites'**
  String get add_to_favourites;

  /// No description provided for @view_details.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get view_details;

  /// No description provided for @installation_started.
  ///
  /// In en, this message translates to:
  /// **'{appName} installation started!'**
  String installation_started(Object appName);

  /// No description provided for @installation_failed_with_error.
  ///
  /// In en, this message translates to:
  /// **'Installation failed: {error}'**
  String installation_failed_with_error(Object error);

  /// No description provided for @download_started.
  ///
  /// In en, this message translates to:
  /// **'{appName} download started!'**
  String download_started(Object appName);

  /// No description provided for @download_failed_with_error.
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String download_failed_with_error(Object error);

  /// No description provided for @start_setup.
  ///
  /// In en, this message translates to:
  /// **'Start Setup'**
  String get start_setup;

  /// No description provided for @continue_text.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continue_text;

  /// No description provided for @loading_changelog.
  ///
  /// In en, this message translates to:
  /// **'Loading changelog...'**
  String get loading_changelog;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @theme_mode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get theme_mode;

  /// No description provided for @follow_system_theme.
  ///
  /// In en, this message translates to:
  /// **'Follow system theme'**
  String get follow_system_theme;

  /// No description provided for @light_theme.
  ///
  /// In en, this message translates to:
  /// **'Light theme'**
  String get light_theme;

  /// No description provided for @dark_theme.
  ///
  /// In en, this message translates to:
  /// **'Dark theme'**
  String get dark_theme;

  /// No description provided for @dynamic_color.
  ///
  /// In en, this message translates to:
  /// **'Dynamic Color'**
  String get dynamic_color;

  /// No description provided for @material_you_dynamic.
  ///
  /// In en, this message translates to:
  /// **'Material You Dynamic'**
  String get material_you_dynamic;

  /// No description provided for @use_system_colors_supported_android.
  ///
  /// In en, this message translates to:
  /// **'Use system colors on supported Android devices'**
  String get use_system_colors_supported_android;

  /// No description provided for @theme_style.
  ///
  /// In en, this message translates to:
  /// **'Theme Style'**
  String get theme_style;

  /// No description provided for @material_style.
  ///
  /// In en, this message translates to:
  /// **'Material style'**
  String get material_style;

  /// No description provided for @dark_knight.
  ///
  /// In en, this message translates to:
  /// **'Dark Knight'**
  String get dark_knight;

  /// No description provided for @dark_knight_subtitle.
  ///
  /// In en, this message translates to:
  /// **'A dark, high-contrast Florid-inspired theme'**
  String get dark_knight_subtitle;

  /// No description provided for @florid_style.
  ///
  /// In en, this message translates to:
  /// **'Florid style'**
  String get florid_style;

  /// No description provided for @beta.
  ///
  /// In en, this message translates to:
  /// **'Beta'**
  String get beta;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @show_whats_new.
  ///
  /// In en, this message translates to:
  /// **'Show What\'s New'**
  String get show_whats_new;

  /// No description provided for @show_monthly_top_apps.
  ///
  /// In en, this message translates to:
  /// **'Show Monthly Top Apps'**
  String get show_monthly_top_apps;

  /// No description provided for @feedback_on_florid_theme.
  ///
  /// In en, this message translates to:
  /// **'Feedback on Florid theme'**
  String get feedback_on_florid_theme;

  /// No description provided for @help_improve_florid_theme_feedback.
  ///
  /// In en, this message translates to:
  /// **'Help improve the Florid theme by providing feedback'**
  String get help_improve_florid_theme_feedback;

  /// No description provided for @system_installer.
  ///
  /// In en, this message translates to:
  /// **'System installer'**
  String get system_installer;

  /// No description provided for @shizuku.
  ///
  /// In en, this message translates to:
  /// **'Shizuku'**
  String get shizuku;

  /// No description provided for @installation_method.
  ///
  /// In en, this message translates to:
  /// **'Installation method'**
  String get installation_method;

  /// No description provided for @requires_shizuku_running.
  ///
  /// In en, this message translates to:
  /// **'Requires Shizuku to be running'**
  String get requires_shizuku_running;

  /// No description provided for @uses_standard_system_installer.
  ///
  /// In en, this message translates to:
  /// **'Uses the standard system installer'**
  String get uses_standard_system_installer;

  /// No description provided for @open_shizuku.
  ///
  /// In en, this message translates to:
  /// **'Open Shizuku'**
  String get open_shizuku;

  /// No description provided for @use_system_installer.
  ///
  /// In en, this message translates to:
  /// **'Use System Installer'**
  String get use_system_installer;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @wifi_only.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi only'**
  String get wifi_only;

  /// No description provided for @wifi_and_charging.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi + charging'**
  String get wifi_and_charging;

  /// No description provided for @mobile_data_or_wifi.
  ///
  /// In en, this message translates to:
  /// **'Mobile data or Wi-Fi'**
  String get mobile_data_or_wifi;

  /// No description provided for @every_1_hour.
  ///
  /// In en, this message translates to:
  /// **'Every 1 hour'**
  String get every_1_hour;

  /// No description provided for @every_2_hours.
  ///
  /// In en, this message translates to:
  /// **'Every 2 hours'**
  String get every_2_hours;

  /// No description provided for @every_3_hours.
  ///
  /// In en, this message translates to:
  /// **'Every 3 hours'**
  String get every_3_hours;

  /// No description provided for @every_6_hours.
  ///
  /// In en, this message translates to:
  /// **'Every 6 hours'**
  String get every_6_hours;

  /// No description provided for @every_12_hours.
  ///
  /// In en, this message translates to:
  /// **'Every 12 hours'**
  String get every_12_hours;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @every_hours.
  ///
  /// In en, this message translates to:
  /// **'Every {hours} hours'**
  String every_hours(int hours);

  /// No description provided for @update_network.
  ///
  /// In en, this message translates to:
  /// **'Update network'**
  String get update_network;

  /// No description provided for @update_interval.
  ///
  /// In en, this message translates to:
  /// **'Update interval'**
  String get update_interval;

  /// No description provided for @app_management.
  ///
  /// In en, this message translates to:
  /// **'App Management'**
  String get app_management;

  /// No description provided for @alpha.
  ///
  /// In en, this message translates to:
  /// **'Alpha'**
  String get alpha;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @opt_out_of_telemetry.
  ///
  /// In en, this message translates to:
  /// **'Opt out of telemetry'**
  String get opt_out_of_telemetry;

  /// No description provided for @opt_out_of_telemetry_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Helps us know how many users (annoymous) are active'**
  String get opt_out_of_telemetry_subtitle;

  /// No description provided for @downloads_and_storage.
  ///
  /// In en, this message translates to:
  /// **'Downloads & Storage'**
  String get downloads_and_storage;

  /// No description provided for @auto_install_after_download.
  ///
  /// In en, this message translates to:
  /// **'Auto-install after download'**
  String get auto_install_after_download;

  /// No description provided for @auto_install_after_download_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Install APKs automatically once download finishes'**
  String get auto_install_after_download_subtitle;

  /// No description provided for @delete_apk_after_install.
  ///
  /// In en, this message translates to:
  /// **'Delete APK after install'**
  String get delete_apk_after_install;

  /// No description provided for @delete_apk_after_install_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Remove installer files after successful installation'**
  String get delete_apk_after_install_subtitle;

  /// No description provided for @background_updates.
  ///
  /// In en, this message translates to:
  /// **'Background updates'**
  String get background_updates;

  /// No description provided for @check_updates_in_background.
  ///
  /// In en, this message translates to:
  /// **'Check for updates in background'**
  String get check_updates_in_background;

  /// No description provided for @notify_when_updates_available.
  ///
  /// In en, this message translates to:
  /// **'Notify when updates are available'**
  String get notify_when_updates_available;

  /// No description provided for @reliability.
  ///
  /// In en, this message translates to:
  /// **'Reliability'**
  String get reliability;

  /// No description provided for @disable_battery_optimization.
  ///
  /// In en, this message translates to:
  /// **'Disable battery optimization'**
  String get disable_battery_optimization;

  /// No description provided for @allow_background_checks_reliably.
  ///
  /// In en, this message translates to:
  /// **'Allow background checks to run reliably'**
  String get allow_background_checks_reliably;

  /// No description provided for @run_debug_check_10s.
  ///
  /// In en, this message translates to:
  /// **'Run debug check in 10s'**
  String get run_debug_check_10s;

  /// No description provided for @run_debug_check_10s_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Shows a test notification and runs after 10s'**
  String get run_debug_check_10s_subtitle;

  /// No description provided for @debug_check_scheduled.
  ///
  /// In en, this message translates to:
  /// **'Debug check scheduled'**
  String get debug_check_scheduled;

  /// No description provided for @debug_update_check_runs_10s.
  ///
  /// In en, this message translates to:
  /// **'Debug update check will run in 10 seconds'**
  String get debug_update_check_runs_10s;

  /// No description provided for @no_recently_updated_apps.
  ///
  /// In en, this message translates to:
  /// **'No recently updated apps'**
  String get no_recently_updated_apps;

  /// No description provided for @no_new_apps.
  ///
  /// In en, this message translates to:
  /// **'No new apps'**
  String get no_new_apps;

  /// No description provided for @monthly_top_apps.
  ///
  /// In en, this message translates to:
  /// **'Monthly Top Apps'**
  String get monthly_top_apps;

  /// No description provided for @from_izzyondroid.
  ///
  /// In en, this message translates to:
  /// **'from IzzyOnDroid'**
  String get from_izzyondroid;

  /// No description provided for @sync_required.
  ///
  /// In en, this message translates to:
  /// **'Sync Required'**
  String get sync_required;

  /// No description provided for @izzyondroid_sync_required_message.
  ///
  /// In en, this message translates to:
  /// **'IzzyOnDroid repository needs to be synced to show top apps.'**
  String get izzyondroid_sync_required_message;

  /// No description provided for @go_to_settings.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings'**
  String get go_to_settings;

  /// No description provided for @keep_android_open.
  ///
  /// In en, this message translates to:
  /// **'Keep Android Open'**
  String get keep_android_open;

  /// No description provided for @keep_android_open_message.
  ///
  /// In en, this message translates to:
  /// **'From 2026/2027 onward, Google will require developer verification for all Android apps on certified devices, including those installed outside of the Play Store.'**
  String get keep_android_open_message;

  /// No description provided for @ignore.
  ///
  /// In en, this message translates to:
  /// **'Ignore'**
  String get ignore;

  /// No description provided for @learn_more.
  ///
  /// In en, this message translates to:
  /// **'Learn More'**
  String get learn_more;

  /// No description provided for @search_fdroid_apps.
  ///
  /// In en, this message translates to:
  /// **'Search F-Droid apps...'**
  String get search_fdroid_apps;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @search_apps.
  ///
  /// In en, this message translates to:
  /// **'Search Apps'**
  String get search_apps;

  /// No description provided for @search_failed.
  ///
  /// In en, this message translates to:
  /// **'Search failed'**
  String get search_failed;

  /// No description provided for @unknown_error_occurred.
  ///
  /// In en, this message translates to:
  /// **'Unknown error occurred'**
  String get unknown_error_occurred;

  /// No description provided for @try_different_keywords.
  ///
  /// In en, this message translates to:
  /// **'Try different keywords or check spelling'**
  String get try_different_keywords;

  /// No description provided for @popular_searches.
  ///
  /// In en, this message translates to:
  /// **'Popular searches:'**
  String get popular_searches;

  /// No description provided for @clear_all.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clear_all;

  /// No description provided for @sort_by.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sort_by;

  /// No description provided for @relevance.
  ///
  /// In en, this message translates to:
  /// **'Relevance'**
  String get relevance;

  /// No description provided for @name_az.
  ///
  /// In en, this message translates to:
  /// **'Name (A-Z)'**
  String get name_az;

  /// No description provided for @name_za.
  ///
  /// In en, this message translates to:
  /// **'Name (Z-A)'**
  String get name_za;

  /// No description provided for @recently_added.
  ///
  /// In en, this message translates to:
  /// **'Recently Added'**
  String get recently_added;

  /// No description provided for @no_categories_available.
  ///
  /// In en, this message translates to:
  /// **'No categories available'**
  String get no_categories_available;

  /// No description provided for @repositories.
  ///
  /// In en, this message translates to:
  /// **'Repositories'**
  String get repositories;

  /// No description provided for @apply_filters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get apply_filters;

  /// No description provided for @search_results_for_query.
  ///
  /// In en, this message translates to:
  /// **'{count} results for \"{query}\"'**
  String search_results_for_query(int count, Object query);

  /// No description provided for @loading_top_apps.
  ///
  /// In en, this message translates to:
  /// **'Loading top apps...'**
  String get loading_top_apps;

  /// No description provided for @failed_to_load_apps.
  ///
  /// In en, this message translates to:
  /// **'Failed to load apps'**
  String get failed_to_load_apps;

  /// No description provided for @try_again.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get try_again;

  /// No description provided for @no_apps_from_izzyondroid.
  ///
  /// In en, this message translates to:
  /// **'No apps from IzzyOnDroid'**
  String get no_apps_from_izzyondroid;

  /// No description provided for @no_favourites_yet.
  ///
  /// In en, this message translates to:
  /// **'No favourites yet'**
  String get no_favourites_yet;

  /// No description provided for @tap_star_to_save.
  ///
  /// In en, this message translates to:
  /// **'Tap the star on any app to save it here'**
  String get tap_star_to_save;

  /// No description provided for @update_failed_with_error.
  ///
  /// In en, this message translates to:
  /// **'Update failed: {error}'**
  String update_failed_with_error(Object error);

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @auto_install_failed_with_error.
  ///
  /// In en, this message translates to:
  /// **'Auto-install failed: {error}'**
  String auto_install_failed_with_error(Object error);

  /// No description provided for @installing_app.
  ///
  /// In en, this message translates to:
  /// **'Installing {appName}...'**
  String installing_app(Object appName);

  /// No description provided for @install_from_repository.
  ///
  /// In en, this message translates to:
  /// **'Install from Repository'**
  String get install_from_repository;

  /// No description provided for @download_from_repository.
  ///
  /// In en, this message translates to:
  /// **'Download from Repository'**
  String get download_from_repository;

  /// No description provided for @choose_repository_for_action.
  ///
  /// In en, this message translates to:
  /// **'You can choose which repository to use to {action} this app.'**
  String choose_repository_for_action(Object action);

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @previously_installed_from.
  ///
  /// In en, this message translates to:
  /// **'Previously installed from: {repositoryName}'**
  String previously_installed_from(Object repositoryName);

  /// No description provided for @previously_installed_from_here.
  ///
  /// In en, this message translates to:
  /// **'Previously installed from here'**
  String get previously_installed_from_here;

  /// No description provided for @default_repository.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get default_repository;

  /// No description provided for @by_author.
  ///
  /// In en, this message translates to:
  /// **'by {author}'**
  String by_author(Object author);

  /// No description provided for @check_out_on_fdroid.
  ///
  /// In en, this message translates to:
  /// **'Check out {appName} on F-Droid: https://f-droid.org/packages/{packageName}/'**
  String check_out_on_fdroid(Object appName, Object packageName);

  /// No description provided for @rebuild_repositories.
  ///
  /// In en, this message translates to:
  /// **'Rebuild repositories'**
  String get rebuild_repositories;

  /// No description provided for @preset.
  ///
  /// In en, this message translates to:
  /// **'Preset'**
  String get preset;

  /// No description provided for @your_repositories.
  ///
  /// In en, this message translates to:
  /// **'Your Repositories'**
  String get your_repositories;

  /// No description provided for @no_custom_repositories.
  ///
  /// In en, this message translates to:
  /// **'No custom repositories added'**
  String get no_custom_repositories;

  /// No description provided for @add_custom_repository_to_start.
  ///
  /// In en, this message translates to:
  /// **'Add a custom F-Droid repository to get started'**
  String get add_custom_repository_to_start;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @point_camera_qr.
  ///
  /// In en, this message translates to:
  /// **'Point camera at QR code'**
  String get point_camera_qr;

  /// No description provided for @tap_keyboard_enter_url.
  ///
  /// In en, this message translates to:
  /// **'Tap keyboard to enter URL manually'**
  String get tap_keyboard_enter_url;

  /// No description provided for @loading_repository_configuration.
  ///
  /// In en, this message translates to:
  /// **'Loading repository configuration...'**
  String get loading_repository_configuration;

  /// No description provided for @adding_selected_repositories.
  ///
  /// In en, this message translates to:
  /// **'Adding selected repositories...'**
  String get adding_selected_repositories;

  /// No description provided for @fetching_fdroid_repository_index.
  ///
  /// In en, this message translates to:
  /// **'Fetching F-Droid repository index...'**
  String get fetching_fdroid_repository_index;

  /// No description provided for @importing_apps_to_database.
  ///
  /// In en, this message translates to:
  /// **'Importing apps to database...'**
  String get importing_apps_to_database;

  /// No description provided for @importing_apps_to_database_seconds.
  ///
  /// In en, this message translates to:
  /// **'Importing apps to database... ({seconds}s)'**
  String importing_apps_to_database_seconds(int seconds);

  /// No description provided for @loading_custom_repositories.
  ///
  /// In en, this message translates to:
  /// **'Loading custom repositories...'**
  String get loading_custom_repositories;

  /// No description provided for @setup_complete.
  ///
  /// In en, this message translates to:
  /// **'Setup complete!'**
  String get setup_complete;

  /// No description provided for @welcome_to.
  ///
  /// In en, this message translates to:
  /// **'Welcome to'**
  String get welcome_to;

  /// No description provided for @onboarding_intro_subtitle.
  ///
  /// In en, this message translates to:
  /// **'A modern F-Droid client to browse, search, and download open-source Android apps with ease.'**
  String get onboarding_intro_subtitle;

  /// No description provided for @curated_open_source_apps.
  ///
  /// In en, this message translates to:
  /// **'Curated open-source apps'**
  String get curated_open_source_apps;

  /// No description provided for @safe_downloads.
  ///
  /// In en, this message translates to:
  /// **'Safe downloads'**
  String get safe_downloads;

  /// No description provided for @updates_and_notifications.
  ///
  /// In en, this message translates to:
  /// **'Updates & notifications'**
  String get updates_and_notifications;

  /// No description provided for @add_extra_repositories.
  ///
  /// In en, this message translates to:
  /// **'Add extra repositories'**
  String get add_extra_repositories;

  /// No description provided for @repos_step_description.
  ///
  /// In en, this message translates to:
  /// **'Florid ships with the official F-Droid repo. You can also include trusted community repos to get more apps.'**
  String get repos_step_description;

  /// No description provided for @available_repositories.
  ///
  /// In en, this message translates to:
  /// **'Available Repositories'**
  String get available_repositories;

  /// No description provided for @manage_repositories_anytime.
  ///
  /// In en, this message translates to:
  /// **'You can add or remove repositories anytime in Settings.'**
  String get manage_repositories_anytime;

  /// No description provided for @request_permissions.
  ///
  /// In en, this message translates to:
  /// **'Request Permissions'**
  String get request_permissions;

  /// No description provided for @permissions_step_description.
  ///
  /// In en, this message translates to:
  /// **'Florid needs a few permissions to provide you with the best experience.'**
  String get permissions_step_description;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @get_notified_updates.
  ///
  /// In en, this message translates to:
  /// **'Get notified when apps are updated'**
  String get get_notified_updates;

  /// No description provided for @app_installation.
  ///
  /// In en, this message translates to:
  /// **'App Installation'**
  String get app_installation;

  /// No description provided for @allow_florid_install_apps.
  ///
  /// In en, this message translates to:
  /// **'Allow Florid to install downloaded apps'**
  String get allow_florid_install_apps;

  /// No description provided for @enable_permissions_anytime.
  ///
  /// In en, this message translates to:
  /// **'You can enable these permissions anytime in Settings.'**
  String get enable_permissions_anytime;

  /// No description provided for @setting_up_florid.
  ///
  /// In en, this message translates to:
  /// **'Setting up Florid'**
  String get setting_up_florid;

  /// No description provided for @no_antifeature_listed.
  ///
  /// In en, this message translates to:
  /// **'No anti-features listed'**
  String get no_antifeature_listed;

  /// No description provided for @open_link.
  ///
  /// In en, this message translates to:
  /// **'Open link'**
  String get open_link;

  /// No description provided for @loading_recently_updated_apps.
  ///
  /// In en, this message translates to:
  /// **'Loading recently updated apps...'**
  String get loading_recently_updated_apps;

  /// No description provided for @checking_for_updates.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates'**
  String get checking_for_updates;

  /// No description provided for @import_favourites.
  ///
  /// In en, this message translates to:
  /// **'Import favourites'**
  String get import_favourites;

  /// No description provided for @merge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get merge;

  /// No description provided for @update_all.
  ///
  /// In en, this message translates to:
  /// **'Update All'**
  String get update_all;

  /// No description provided for @apps.
  ///
  /// In en, this message translates to:
  /// **'Apps'**
  String get apps;

  /// No description provided for @troubleshooting.
  ///
  /// In en, this message translates to:
  /// **'Troubleshooting'**
  String get troubleshooting;

  /// No description provided for @replace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// No description provided for @your_name.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get your_name;

  /// No description provided for @enter_your_name.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enter_your_name;

  /// No description provided for @top_apps.
  ///
  /// In en, this message translates to:
  /// **'Top Apps'**
  String get top_apps;

  /// No description provided for @games.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get games;

  /// No description provided for @auth_all_apps.
  ///
  /// In en, this message translates to:
  /// **'All Apps'**
  String get auth_all_apps;

  /// No description provided for @auth_all_apps_desc.
  ///
  /// In en, this message translates to:
  /// **'Require authentication for all installations'**
  String get auth_all_apps_desc;

  /// No description provided for @auth_all_apps_w_anti_feat.
  ///
  /// In en, this message translates to:
  /// **'Apps with Anti-Features'**
  String get auth_all_apps_w_anti_feat;

  /// No description provided for @auth_all_apps_w_anti_feat_desc.
  ///
  /// In en, this message translates to:
  /// **'Require authentication only for apps that have anti-features.'**
  String get auth_all_apps_w_anti_feat_desc;

  /// No description provided for @support_the_developer.
  ///
  /// In en, this message translates to:
  /// **'Support the Developer'**
  String get support_the_developer;

  /// Label showing the primary repository name for an app.
  ///
  /// In en, this message translates to:
  /// **'Available on: {repositoryName}'**
  String available_on_repository(Object repositoryName);

  /// Label listing additional repository names where the app is available.
  ///
  /// In en, this message translates to:
  /// **'Also available from: {repositoryNames}'**
  String also_available_from_repositories(Object repositoryNames);
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
      <String>['cs', 'de', 'en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'CN':
            return AppLocalizationsZhCn();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'cs':
      return AppLocalizationsCs();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
