import 'package:crowdin_sdk/crowdin_sdk.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeStyle { material, florid }

class SettingsProvider extends ChangeNotifier {
  static const _themeModeKey = 'theme_mode';
  static const _themeStyleKey = 'theme_style';
  static const _autoInstallKey = 'auto_install_apk';
  static const _autoDeleteKey = 'auto_delete_apk';
  static const _localeKey = 'locale';
  static const _onboardingCompleteKey = 'onboarding_complete';
  static const _sniBypassKey = 'sni_bypass_enabled';
  static const _includeUnstableKey = 'include_unstable_versions';

  ThemeMode _themeMode = ThemeMode.system;
  ThemeStyle _themeStyle = ThemeStyle.florid;
  bool _autoInstallApk = true;
  bool _autoDeleteApk = true;
  String _locale = 'en-US';
  bool _onboardingComplete = false;
  bool _sniBypassEnabled = true;
  bool _includeUnstableVersions = false;
  bool _loaded = false;

  SettingsProvider() {
    _load();
  }

  bool get isLoaded => _loaded;
  ThemeMode get themeMode => _themeMode;
  ThemeStyle get themeStyle => _themeStyle;
  bool get autoInstallApk => _autoInstallApk;
  bool get autoDeleteApk => _autoDeleteApk;
  String get locale => _locale;
  bool get onboardingComplete => _onboardingComplete;
  bool get sniBypassEnabled => _sniBypassEnabled;
  bool get includeUnstableVersions => _includeUnstableVersions;

  /// Available locales for F-Droid repository data
  static const List<String> availableLocales = [
    'en-US',
    'en',
    'de-DE',
    'es-ES',
    'fr-FR',
    'it-IT',
    'ja-JP',
    'ko-KR',
    'pt-BR',
    'ru-RU',
    'zh-CN',
  ];

  /// Get locale display name
  static String getLocaleDisplayName(String locale) {
    switch (locale) {
      case 'en-US':
        return 'English (US)';
      case 'en':
        return 'English';
      case 'de-DE':
        return 'Deutsch';
      case 'es-ES':
        return 'Español';
      case 'fr-FR':
        return 'Français';
      case 'it-IT':
        return 'Italiano';
      case 'ja-JP':
        return '日本語';
      case 'ko-KR':
        return '한국어';
      case 'pt-BR':
        return 'Português (Brasil)';
      case 'ru-RU':
        return 'Русский';
      case 'zh-CN':
        return '简体中文';
      default:
        return locale;
    }
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeModeKey);
    if (themeIndex != null &&
        themeIndex >= 0 &&
        themeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[themeIndex];
    }
    final themeStyleIndex =
        prefs.getInt(_themeStyleKey) ?? 1; // Default to Florid
    if (themeStyleIndex >= 0 && themeStyleIndex < ThemeStyle.values.length) {
      _themeStyle = ThemeStyle.values[themeStyleIndex];
    }
    _autoInstallApk = prefs.getBool(_autoInstallKey) ?? true;
    _autoDeleteApk = prefs.getBool(_autoDeleteKey) ?? true;
    _locale = prefs.getString(_localeKey) ?? 'en-US';
    _onboardingComplete = prefs.getBool(_onboardingCompleteKey) ?? false;
    _sniBypassEnabled = prefs.getBool(_sniBypassKey) ?? true;
    _includeUnstableVersions = prefs.getBool(_includeUnstableKey) ?? false;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
  }

  Future<void> setThemeStyle(ThemeStyle style) async {
    _themeStyle = style;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeStyleKey, style.index);
  }

  Future<void> setAutoInstallApk(bool value) async {
    _autoInstallApk = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoInstallKey, value);
  }

  Future<void> setAutoDeleteApk(bool value) async {
    _autoDeleteApk = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoDeleteKey, value);
  }

  Future<void> setLocale(String locale) async {
    if (!availableLocales.contains(locale)) {
      throw ArgumentError('Unsupported locale: $locale');
    }
    // Load translations from Crowdin for the specified locale
    final localeObj = _parseLocale(locale);
    await Crowdin.loadTranslations(localeObj);
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale);
  }

  /// Helper to parse a locale string like 'en-US' or 'en' to a Locale object
  Locale _parseLocale(String locale) {
    final parts = locale.split('-');
    if (parts.length == 2) {
      return Locale(parts[0], parts[1]);
    } else {
      return Locale(locale);
    }
  }

  Future<void> setOnboardingComplete([bool value = true]) async {
    _onboardingComplete = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, value);
  }

  Future<void> setSniBypassEnabled(bool value) async {
    _sniBypassEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sniBypassKey, value);
  }

  Future<void> setIncludeUnstableVersions(bool value) async {
    _includeUnstableVersions = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_includeUnstableKey, value);
  }
}
