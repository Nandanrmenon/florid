import 'package:crowdin_sdk/crowdin_sdk.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_localizations.dart';

class CrowdinLocalization extends AppLocalizations {
  final AppLocalizations _fallbackTexts;

  CrowdinLocalization(super.locale, AppLocalizations fallbackTexts)
    : _fallbackTexts = fallbackTexts;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _CrowdinLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  static const List<Locale> supportedLocales =
      AppLocalizations.supportedLocales;

  @override
  String get app_name =>
      Crowdin.getText(localeName, 'app_name') ?? _fallbackTexts.app_name;

  @override
  String get welcome =>
      Crowdin.getText(localeName, 'welcome') ?? _fallbackTexts.welcome;

  @override
  String get search =>
      Crowdin.getText(localeName, 'search') ?? _fallbackTexts.search;

  @override
  String get settings =>
      Crowdin.getText(localeName, 'settings') ?? _fallbackTexts.settings;

  @override
  String get home => Crowdin.getText(localeName, 'home') ?? _fallbackTexts.home;

  @override
  String get categories =>
      Crowdin.getText(localeName, 'categories') ?? _fallbackTexts.categories;

  @override
  String get updates =>
      Crowdin.getText(localeName, 'updates') ?? _fallbackTexts.updates;

  @override
  String get installed =>
      Crowdin.getText(localeName, 'installed') ?? _fallbackTexts.installed;

  @override
  String get download =>
      Crowdin.getText(localeName, 'download') ?? _fallbackTexts.download;

  @override
  String get install =>
      Crowdin.getText(localeName, 'install') ?? _fallbackTexts.install;

  @override
  String get uninstall =>
      Crowdin.getText(localeName, 'uninstall') ?? _fallbackTexts.uninstall;

  @override
  String get open => Crowdin.getText(localeName, 'open') ?? _fallbackTexts.open;

  @override
  String get cancel =>
      Crowdin.getText(localeName, 'cancel') ?? _fallbackTexts.cancel;

  @override
  String get update_available =>
      Crowdin.getText(localeName, 'update_available') ??
      _fallbackTexts.update_available;

  @override
  String get downloading =>
      Crowdin.getText(localeName, 'downloading') ?? _fallbackTexts.downloading;

  @override
  String get install_permission_required =>
      Crowdin.getText(localeName, 'install_permission_required') ??
      _fallbackTexts.install_permission_required;

  @override
  String get storage_permission_required =>
      Crowdin.getText(localeName, 'storage_permission_required') ??
      _fallbackTexts.storage_permission_required;

  @override
  String get cancel_download =>
      Crowdin.getText(localeName, 'cancel_download') ??
      _fallbackTexts.cancel_download;

  @override
  String get version =>
      Crowdin.getText(localeName, 'version') ?? _fallbackTexts.version;

  @override
  String get size => Crowdin.getText(localeName, 'size') ?? _fallbackTexts.size;

  @override
  String get description =>
      Crowdin.getText(localeName, 'description') ?? _fallbackTexts.description;

  @override
  String get permissions =>
      Crowdin.getText(localeName, 'permissions') ?? _fallbackTexts.permissions;

  @override
  String get screenshots =>
      Crowdin.getText(localeName, 'screenshots') ?? _fallbackTexts.screenshots;

  @override
  String get no_version_available =>
      Crowdin.getText(localeName, 'no_version_available') ??
      _fallbackTexts.no_version_available;

  @override
  String get app_information =>
      Crowdin.getText(localeName, 'app_information') ??
      _fallbackTexts.app_information;

  @override
  String get package_name =>
      Crowdin.getText(localeName, 'package_name') ??
      _fallbackTexts.package_name;

  @override
  String get license =>
      Crowdin.getText(localeName, 'license') ?? _fallbackTexts.license;

  @override
  String get added =>
      Crowdin.getText(localeName, 'added') ?? _fallbackTexts.added;

  @override
  String get last_updated =>
      Crowdin.getText(localeName, 'last_updated') ??
      _fallbackTexts.last_updated;

  @override
  String get version_information =>
      Crowdin.getText(localeName, 'version_information') ??
      _fallbackTexts.version_information;

  @override
  String get version_name =>
      Crowdin.getText(localeName, 'version_name') ??
      _fallbackTexts.version_name;

  @override
  String get version_code =>
      Crowdin.getText(localeName, 'version_code') ??
      _fallbackTexts.version_code;

  @override
  String get min_sdk =>
      Crowdin.getText(localeName, 'min_sdk') ?? _fallbackTexts.min_sdk;

  @override
  String get target_sdk =>
      Crowdin.getText(localeName, 'target_sdk') ?? _fallbackTexts.target_sdk;

  @override
  String get all_versions =>
      Crowdin.getText(localeName, 'all_versions') ??
      _fallbackTexts.all_versions;

  @override
  String get latest =>
      Crowdin.getText(localeName, 'latest') ?? _fallbackTexts.latest;

  @override
  String get released =>
      Crowdin.getText(localeName, 'released') ?? _fallbackTexts.released;

  @override
  String get loading =>
      Crowdin.getText(localeName, 'loading') ?? _fallbackTexts.loading;

  @override
  String get error =>
      Crowdin.getText(localeName, 'error') ?? _fallbackTexts.error;

  @override
  String get retry =>
      Crowdin.getText(localeName, 'retry') ?? _fallbackTexts.retry;

  @override
  String get share =>
      Crowdin.getText(localeName, 'share') ?? _fallbackTexts.share;

  @override
  String get website =>
      Crowdin.getText(localeName, 'website') ?? _fallbackTexts.website;

  @override
  String get source_code =>
      Crowdin.getText(localeName, 'source_code') ?? _fallbackTexts.source_code;

  @override
  String get issue_tracker =>
      Crowdin.getText(localeName, 'issue_tracker') ??
      _fallbackTexts.issue_tracker;

  @override
  String get whats_new =>
      Crowdin.getText(localeName, 'whats_new') ?? _fallbackTexts.whats_new;

  @override
  String get show_more =>
      Crowdin.getText(localeName, 'show_more') ?? _fallbackTexts.show_more;

  @override
  String get show_less =>
      Crowdin.getText(localeName, 'show_less') ?? _fallbackTexts.show_less;

  @override
  String get downloads_stats =>
      Crowdin.getText(localeName, 'downloads_stats') ??
      _fallbackTexts.downloads_stats;

  @override
  String get last_day =>
      Crowdin.getText(localeName, 'last_day') ?? _fallbackTexts.last_day;

  @override
  String get last_30_days =>
      Crowdin.getText(localeName, 'last_30_days') ??
      _fallbackTexts.last_30_days;

  @override
  String get last_365_days =>
      Crowdin.getText(localeName, 'last_365_days') ??
      _fallbackTexts.last_365_days;

  @override
  String get not_available =>
      Crowdin.getText(localeName, 'not_available') ??
      _fallbackTexts.not_available;

  @override
  String get download_failed =>
      Crowdin.getText(localeName, 'download_failed') ??
      _fallbackTexts.download_failed;

  @override
  String get installation_failed =>
      Crowdin.getText(localeName, 'installation_failed') ??
      _fallbackTexts.installation_failed;

  @override
  String get uninstall_failed =>
      Crowdin.getText(localeName, 'uninstall_failed') ??
      _fallbackTexts.uninstall_failed;

  @override
  String get open_failed =>
      Crowdin.getText(localeName, 'open_failed') ?? _fallbackTexts.open_failed;

  @override
  String get device =>
      Crowdin.getText(localeName, 'device') ?? _fallbackTexts.device;

  @override
  String get recently_updated =>
      Crowdin.getText(localeName, 'recently_updated') ??
      _fallbackTexts.recently_updated;

  @override
  String get refresh =>
      Crowdin.getText(localeName, 'refresh') ?? _fallbackTexts.refresh;

  @override
  String get about =>
      Crowdin.getText(localeName, 'about') ?? _fallbackTexts.about;

  @override
  String get refreshing_data =>
      Crowdin.getText(localeName, 'refreshing_data') ??
      _fallbackTexts.refreshing_data;

  @override
  String get data_refreshed =>
      Crowdin.getText(localeName, 'data_refreshed') ??
      _fallbackTexts.data_refreshed;

  @override
  String get refresh_failed =>
      Crowdin.getText(localeName, 'refresh_failed') ??
      _fallbackTexts.refresh_failed;

  @override
  String get loading_latest_apps =>
      Crowdin.getText(localeName, 'loading_latest_apps') ??
      _fallbackTexts.loading_latest_apps;

  @override
  String get latest_apps =>
      Crowdin.getText(localeName, 'latest_apps') ?? _fallbackTexts.latest_apps;

  @override
  String get no_apps_found =>
      Crowdin.getText(localeName, 'no_apps_found') ??
      _fallbackTexts.no_apps_found;

  @override
  String get searching =>
      Crowdin.getText(localeName, 'searching') ?? _fallbackTexts.searching;

  @override
  String get setup_failed =>
      Crowdin.getText(localeName, 'setup_failed') ??
      _fallbackTexts.setup_failed;

  @override
  String get back => Crowdin.getText(localeName, 'back') ?? _fallbackTexts.back;

  @override
  String get allow =>
      Crowdin.getText(localeName, 'allow') ?? _fallbackTexts.allow;

  @override
  String get manage_repositories =>
      Crowdin.getText(localeName, 'manage_repositories') ??
      _fallbackTexts.manage_repositories;

  @override
  String get enable_disable =>
      Crowdin.getText(localeName, 'enable_disable') ??
      _fallbackTexts.enable_disable;

  @override
  String get edit => Crowdin.getText(localeName, 'edit') ?? _fallbackTexts.edit;

  @override
  String get delete =>
      Crowdin.getText(localeName, 'delete') ?? _fallbackTexts.delete;

  @override
  String get delete_repository =>
      Crowdin.getText(localeName, 'delete_repository') ??
      _fallbackTexts.delete_repository;

  @override
  String delete_repository_confirm(Object name, Object repo) =>
      Crowdin.getText(localeName, 'delete_repository_confirm', {
        'name': name,
        'repo': repo,
      }) ??
      _fallbackTexts.delete_repository_confirm(name, repo);

  @override
  String get updating_repository =>
      Crowdin.getText(localeName, 'updating_repository') ??
      _fallbackTexts.updating_repository;

  @override
  String get touch_grass_message =>
      Crowdin.getText(localeName, 'touch_grass_message') ??
      _fallbackTexts.touch_grass_message;

  @override
  String get add_repository =>
      Crowdin.getText(localeName, 'add_repository') ??
      _fallbackTexts.add_repository;

  @override
  String get add => Crowdin.getText(localeName, 'add') ?? _fallbackTexts.add;

  @override
  String get save => Crowdin.getText(localeName, 'save') ?? _fallbackTexts.save;

  @override
  String get enter_repository_name =>
      Crowdin.getText(localeName, 'enter_repository_name') ??
      _fallbackTexts.enter_repository_name;

  @override
  String get enter_repository_url =>
      Crowdin.getText(localeName, 'enter_repository_url') ??
      _fallbackTexts.enter_repository_url;

  @override
  String get edit_repository =>
      Crowdin.getText(localeName, 'edit_repository') ??
      _fallbackTexts.edit_repository;

  @override
  String get loading_apps =>
      Crowdin.getText(localeName, 'loading_apps') ??
      _fallbackTexts.loading_apps;

  @override
  String no_apps_in_category(Object category) =>
      Crowdin.getText(localeName, 'no_apps_in_category', {
        'category': category,
      }) ??
      _fallbackTexts.no_apps_in_category(category);

  @override
  String get loading_categories =>
      Crowdin.getText(localeName, 'loading_categories') ??
      _fallbackTexts.loading_categories;

  @override
  String get no_categories_found =>
      Crowdin.getText(localeName, 'no_categories_found') ??
      _fallbackTexts.no_categories_found;
}

class _CrowdinLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _CrowdinLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) => AppLocalizations.delegate
      .load(locale)
      .then((fallback) => CrowdinLocalization(locale.toString(), fallback));

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.contains(locale);

  @override
  bool shouldReload(_CrowdinLocalizationsDelegate old) => false;
}
