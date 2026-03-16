// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class AppLocalizationsCs extends AppLocalizations {
  AppLocalizationsCs([String locale = 'cs']) : super(locale);

  @override
  String get app_name => 'Florid';

  @override
  String get welcome => 'Vítejte ve Florid';

  @override
  String get search => 'Hledat';

  @override
  String get settings => 'Nastavení';

  @override
  String get home => 'Domů';

  @override
  String get categories => 'Kategorie';

  @override
  String get updates => 'Aktualizace';

  @override
  String get installed => 'Instalováno';

  @override
  String get download => 'Stáhnout';

  @override
  String get install => 'Instalovat';

  @override
  String get uninstall => 'Odinstalovat';

  @override
  String get open => 'Otevřít';

  @override
  String get cancel => 'Zrušit';

  @override
  String get update_available => 'Aktualizace k dispozici';

  @override
  String get downloading => 'Stahování...';

  @override
  String get install_permission_required =>
      'Je vyžadováno oprávnění k instalaci';

  @override
  String get storage_permission_required => 'Potřebné oprávnění k ukládání';

  @override
  String get cancel_download => 'Zrušit stahování';

  @override
  String get version => 'Verze';

  @override
  String get size => 'Velikost';

  @override
  String get description => 'Popis';

  @override
  String get permissions => 'Oprávnění';

  @override
  String get screenshots => 'Screenshoty';

  @override
  String get no_version_available => 'Žádná verze není k dispozici';

  @override
  String get app_information => 'Informace o aplikaci';

  @override
  String get package_name => 'Název balíčku';

  @override
  String get license => 'License';

  @override
  String get added => 'Přidáno';

  @override
  String get last_updated => 'Poslední aktualizace';

  @override
  String get version_information => 'Informace o verzi';

  @override
  String get version_name => 'Název verze';

  @override
  String get version_code => 'Kód verze';

  @override
  String get min_sdk => 'Minimální SDK';

  @override
  String get target_sdk => 'Cílové SDK';

  @override
  String get all_versions => 'Všechny verze';

  @override
  String get latest => 'Nejnovější';

  @override
  String get released => 'Vydáno';

  @override
  String get loading => 'Načítání...';

  @override
  String get error => 'Chyba';

  @override
  String get retry => 'Zkusit znovu';

  @override
  String get share => 'Sdílet';

  @override
  String get website => 'Webové stránky';

  @override
  String get source_code => 'Zdrojový kód';

  @override
  String get issue_tracker => 'Sledování problémů';

  @override
  String get whats_new => 'Novinky';

  @override
  String get show_more => 'Zobrazit více';

  @override
  String get show_less => 'Zobrazit méně';

  @override
  String get downloads_stats => 'Statistiky stahování';

  @override
  String get last_day => 'Poslední den';

  @override
  String get last_30_days => 'Posledních 30 dní';

  @override
  String get last_365_days => 'Posledních 365 dní';

  @override
  String get not_available => 'Není k dispozici';

  @override
  String get download_failed => 'Stažení se nezdařilo';

  @override
  String get installation_failed => 'Instalace se nezdařila';

  @override
  String get uninstall_failed => 'Odinstalace se nezdařila';

  @override
  String get open_failed => 'Nepodařilo se otevřít';

  @override
  String get device => 'Zařízení';

  @override
  String get recently_updated => 'Nedávno aktualizováno';

  @override
  String get refresh => 'Obnovit';

  @override
  String get about => 'O nás';

  @override
  String get refreshing_data => 'Aktualizace dat...';

  @override
  String get data_refreshed => 'Data aktualizována';

  @override
  String get refresh_failed => 'Obnovení se nezdařilo';

  @override
  String get loading_latest_apps => 'Načítání nejnovějších aplikací...';

  @override
  String get latest_apps => 'Nejnovější aplikace';

  @override
  String get no_apps_found => 'Nenalezeny žádné aplikace';

  @override
  String get searching => 'Hledání...';

  @override
  String get setup_failed => 'Nastavení se nezdařilo';

  @override
  String get back => 'Zpět';

  @override
  String get allow => 'Povolit';

  @override
  String get manage_repositories => 'Spravovat repozitáře';

  @override
  String get enable_disable => 'Povolit/Zakázat';

  @override
  String get edit => 'Upravit';

  @override
  String get delete => 'Odstranit';

  @override
  String get delete_repository => 'Odstranit úložiště';

  @override
  String delete_repository_confirm(Object name, Object repository) {
    return 'Opravdu chcete odstranit „$repository“?';
  }

  @override
  String get updating_repository => 'Aktualizace repozitáře';

  @override
  String get touch_grass_message =>
      'Teď je ten správný čas dotknout se zelené trávy!';

  @override
  String get add_repository => 'Přidat repozitář';

  @override
  String get add => 'Přidat';

  @override
  String get save => 'Uložit';

  @override
  String get enter_repository_name => 'Zadejte název repositáře';

  @override
  String get enter_repository_url => 'Zadejte adresu URL repositáře';

  @override
  String get edit_repository => 'Upravit Repository';

  @override
  String get loading_apps => 'Načítání aplikací...';

  @override
  String no_apps_in_category(Object category) {
    return 'Nenalezeny žádné aplikace v $category';
  }

  @override
  String get loading_categories => 'Načítání kategorií...';

  @override
  String get no_categories_found => 'Nebyly nalezeny žádné kategorie';

  @override
  String get on_device => 'On Device';

  @override
  String get favourites => 'Favourites';

  @override
  String get loading_repository => 'Loading repository…';

  @override
  String get unable_to_load_repository => 'Unable to load repository';

  @override
  String get repository_loading_error_descrption =>
      'Check your connection or repository settings, then try again.';

  @override
  String get appUpdateAvailable => 'Update Available';

  @override
  String get releaseNotes => 'Release Notes';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get viewOnGithub => 'View on GitHub';

  @override
  String get update => 'Update';

  @override
  String get installing => 'Installing...';

  @override
  String get downloadFailed => 'Failed to download APK';

  @override
  String get remove_from_favourites => 'Remove from Favourites';

  @override
  String get add_to_favourites => 'Add to Favourites';

  @override
  String get view_details => 'View Details';

  @override
  String installation_started(Object appName) {
    return '$appName installation started!';
  }

  @override
  String installation_failed_with_error(Object error) {
    return 'Installation failed: $error';
  }

  @override
  String download_started(Object appName) {
    return '$appName download started!';
  }

  @override
  String download_failed_with_error(Object error) {
    return 'Download failed: $error';
  }

  @override
  String get start_setup => 'Start Setup';

  @override
  String get continue_text => 'Continue';

  @override
  String get loading_changelog => 'Loading changelog...';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme_mode => 'Theme Mode';

  @override
  String get follow_system_theme => 'Follow system theme';

  @override
  String get light_theme => 'Light theme';

  @override
  String get dark_theme => 'Dark theme';

  @override
  String get dynamic_color => 'Dynamic Color';

  @override
  String get material_you_dynamic => 'Material You Dynamic';

  @override
  String get use_system_colors_supported_android =>
      'Use system colors on supported Android devices';

  @override
  String get theme_style => 'Theme Style';

  @override
  String get material_style => 'Material style';

  @override
  String get dark_knight => 'Dark Knight';

  @override
  String get dark_knight_subtitle =>
      'A dark, high-contrast Florid-inspired theme';

  @override
  String get florid_style => 'Florid style';

  @override
  String get beta => 'Beta';

  @override
  String get other => 'Other';

  @override
  String get show_whats_new => 'Show What\'s New';

  @override
  String get show_monthly_top_apps => 'Show Monthly Top Apps';

  @override
  String get feedback_on_florid_theme => 'Feedback on Florid theme';

  @override
  String get help_improve_florid_theme_feedback =>
      'Help improve the Florid theme by providing feedback';

  @override
  String get system_installer => 'System installer';

  @override
  String get shizuku => 'Shizuku';

  @override
  String get installation_method => 'Installation method';

  @override
  String get requires_shizuku_running => 'Requires Shizuku to be running';

  @override
  String get uses_standard_system_installer =>
      'Uses the standard system installer';

  @override
  String get open_shizuku => 'Open Shizuku';

  @override
  String get use_system_installer => 'Use System Installer';

  @override
  String get close => 'Close';

  @override
  String get wifi_only => 'Wi-Fi only';

  @override
  String get wifi_and_charging => 'Wi-Fi + charging';

  @override
  String get mobile_data_or_wifi => 'Mobile data or Wi-Fi';

  @override
  String get every_1_hour => 'Every 1 hour';

  @override
  String get every_2_hours => 'Every 2 hours';

  @override
  String get every_3_hours => 'Every 3 hours';

  @override
  String get every_6_hours => 'Every 6 hours';

  @override
  String get every_12_hours => 'Every 12 hours';

  @override
  String get daily => 'Daily';

  @override
  String every_hours(int hours) {
    return 'Every $hours hours';
  }

  @override
  String get update_network => 'Update network';

  @override
  String get update_interval => 'Update interval';

  @override
  String get app_management => 'App Management';

  @override
  String get alpha => 'Alpha';

  @override
  String get downloads_and_storage => 'Downloads & Storage';

  @override
  String get auto_install_after_download => 'Auto-install after download';

  @override
  String get auto_install_after_download_subtitle =>
      'Install APKs automatically once download finishes';

  @override
  String get delete_apk_after_install => 'Delete APK after install';

  @override
  String get delete_apk_after_install_subtitle =>
      'Remove installer files after successful installation';

  @override
  String get background_updates => 'Background updates';

  @override
  String get check_updates_in_background => 'Check for updates in background';

  @override
  String get notify_when_updates_available =>
      'Notify when updates are available';

  @override
  String get reliability => 'Reliability';

  @override
  String get disable_battery_optimization => 'Disable battery optimization';

  @override
  String get allow_background_checks_reliably =>
      'Allow background checks to run reliably';

  @override
  String get run_debug_check_10s => 'Run debug check in 10s';

  @override
  String get run_debug_check_10s_subtitle =>
      'Shows a test notification and runs after 10s';

  @override
  String get debug_check_scheduled => 'Debug check scheduled';

  @override
  String get debug_update_check_runs_10s =>
      'Debug update check will run in 10 seconds';

  @override
  String get no_recently_updated_apps => 'No recently updated apps';

  @override
  String get no_new_apps => 'No new apps';

  @override
  String get monthly_top_apps => 'Monthly Top Apps';

  @override
  String get from_izzyondroid => 'from IzzyOnDroid';

  @override
  String get sync_required => 'Sync Required';

  @override
  String get izzyondroid_sync_required_message =>
      'IzzyOnDroid repository needs to be synced to show top apps.';

  @override
  String get go_to_settings => 'Go to Settings';

  @override
  String get keep_android_open => 'Keep Android Open';

  @override
  String get keep_android_open_message =>
      'From 2026/2027 onward, Google will require developer verification for all Android apps on certified devices, including those installed outside of the Play Store.';

  @override
  String get ignore => 'Ignore';

  @override
  String get learn_more => 'Learn More';

  @override
  String get search_fdroid_apps => 'Search F-Droid apps...';

  @override
  String get filters => 'Filters';

  @override
  String get search_apps => 'Search Apps';

  @override
  String get search_failed => 'Search failed';

  @override
  String get unknown_error_occurred => 'Unknown error occurred';

  @override
  String get try_different_keywords =>
      'Try different keywords or check spelling';

  @override
  String get popular_searches => 'Popular searches:';

  @override
  String get clear_all => 'Clear all';

  @override
  String get sort_by => 'Sort by';

  @override
  String get relevance => 'Relevance';

  @override
  String get name_az => 'Name (A-Z)';

  @override
  String get name_za => 'Name (Z-A)';

  @override
  String get recently_added => 'Recently Added';

  @override
  String get no_categories_available => 'No categories available';

  @override
  String get repositories => 'Repositories';

  @override
  String get apply_filters => 'Apply Filters';

  @override
  String search_results_for_query(int count, Object query) {
    return '$count results for \"$query\"';
  }

  @override
  String get loading_top_apps => 'Loading top apps...';

  @override
  String get failed_to_load_apps => 'Failed to load apps';

  @override
  String get try_again => 'Try Again';

  @override
  String get no_apps_from_izzyondroid => 'No apps from IzzyOnDroid';

  @override
  String get no_favourites_yet => 'No favourites yet';

  @override
  String get tap_star_to_save => 'Tap the star on any app to save it here';

  @override
  String update_failed_with_error(Object error) {
    return 'Update failed: $error';
  }

  @override
  String get user => 'User';

  @override
  String auto_install_failed_with_error(Object error) {
    return 'Auto-install failed: $error';
  }

  @override
  String installing_app(Object appName) {
    return 'Installing $appName...';
  }

  @override
  String get install_from_repository => 'Install from Repository';

  @override
  String get download_from_repository => 'Download from Repository';

  @override
  String choose_repository_for_action(Object action) {
    return 'You can choose which repository to use to $action this app.';
  }

  @override
  String get unknown => 'Unknown';

  @override
  String previously_installed_from(Object repositoryName) {
    return 'Previously installed from: $repositoryName';
  }

  @override
  String get previously_installed_from_here => 'Previously installed from here';

  @override
  String get default_repository => 'Default';

  @override
  String by_author(Object author) {
    return 'by $author';
  }

  @override
  String check_out_on_fdroid(Object appName, Object packageName) {
    return 'Check out $appName on F-Droid: https://f-droid.org/packages/$packageName/';
  }

  @override
  String get rebuild_repositories => 'Rebuild repositories';

  @override
  String get preset => 'Preset';

  @override
  String get your_repositories => 'Your Repositories';

  @override
  String get no_custom_repositories => 'No custom repositories added';

  @override
  String get add_custom_repository_to_start =>
      'Add a custom F-Droid repository to get started';

  @override
  String get scan => 'Scan';

  @override
  String get point_camera_qr => 'Point camera at QR code';

  @override
  String get tap_keyboard_enter_url => 'Tap keyboard to enter URL manually';

  @override
  String get loading_repository_configuration =>
      'Loading repository configuration...';

  @override
  String get adding_selected_repositories => 'Adding selected repositories...';

  @override
  String get fetching_fdroid_repository_index =>
      'Fetching F-Droid repository index...';

  @override
  String get importing_apps_to_database => 'Importing apps to database...';

  @override
  String importing_apps_to_database_seconds(int seconds) {
    return 'Importing apps to database... (${seconds}s)';
  }

  @override
  String get loading_custom_repositories => 'Loading custom repositories...';

  @override
  String get setup_complete => 'Setup complete!';

  @override
  String get welcome_to => 'Welcome to';

  @override
  String get onboarding_intro_subtitle =>
      'A modern F-Droid client to browse, search, and download open-source Android apps with ease.';

  @override
  String get curated_open_source_apps => 'Curated open-source apps';

  @override
  String get safe_downloads => 'Safe downloads';

  @override
  String get updates_and_notifications => 'Updates & notifications';

  @override
  String get add_extra_repositories => 'Add extra repositories';

  @override
  String get repos_step_description =>
      'Florid ships with the official F-Droid repo. You can also include trusted community repos to get more apps.';

  @override
  String get available_repositories => 'Available Repositories';

  @override
  String get manage_repositories_anytime =>
      'You can add or remove repositories anytime in Settings.';

  @override
  String get request_permissions => 'Request Permissions';

  @override
  String get permissions_step_description =>
      'Florid needs a few permissions to provide you with the best experience.';

  @override
  String get notifications => 'Notifications';

  @override
  String get get_notified_updates => 'Get notified when apps are updated';

  @override
  String get app_installation => 'App Installation';

  @override
  String get allow_florid_install_apps =>
      'Allow Florid to install downloaded apps';

  @override
  String get enable_permissions_anytime =>
      'You can enable these permissions anytime in Settings.';

  @override
  String get setting_up_florid => 'Setting up Florid';

  @override
  String get no_antifeature_listed => 'No anti-features listed';

  @override
  String get open_link => 'Open link';

  @override
  String get loading_recently_updated_apps =>
      'Loading recently updated apps...';

  @override
  String get checking_for_updates => 'Checking for updates';

  @override
  String get import_favourites => 'Import favourites';

  @override
  String get merge => 'Merge';

  @override
  String get update_all => 'Update All';

  @override
  String get apps => 'Apps';

  @override
  String get troubleshooting => 'Troubleshooting';

  @override
  String get replace => 'Replace';

  @override
  String get your_name => 'Your name';

  @override
  String get enter_your_name => 'Enter your name';

  @override
  String get top_apps => 'Top Apps';

  @override
  String get games => 'Games';

  @override
  String get auth_all_apps => 'All Apps';

  @override
  String get auth_all_apps_desc =>
      'Require authentication for all installations';

  @override
  String get auth_all_apps_w_anti_feat => 'Apps with Anti-Features';

  @override
  String get auth_all_apps_w_anti_feat_desc =>
      'Require authentication only for apps that have anti-features.';

  @override
  String get support_the_developer => 'Support the Developer';
}
