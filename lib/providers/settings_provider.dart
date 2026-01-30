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
  
  // Web sync settings
  static const _webSyncEnabledKey = 'web_sync_enabled';
  static const _deviceIdKey = 'device_id';
  static const _userIdKey = 'user_id';
  static const _authTokenKey = 'auth_token';
  static const _deviceNameKey = 'device_name';

  ThemeMode _themeMode = ThemeMode.system;
  ThemeStyle _themeStyle = ThemeStyle.florid;
  bool _autoInstallApk = true;
  bool _autoDeleteApk = true;
  String _locale = 'en-US';
  bool _onboardingComplete = false;
  bool _loaded = false;
  
  // Web sync properties
  bool _webSyncEnabled = false;
  String? _deviceId;
  String? _userId;
  String? _authToken;
  String? _deviceName;

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
  
  // Web sync getters
  bool get webSyncEnabled => _webSyncEnabled;
  String? get deviceId => _deviceId;
  String? get userId => _userId;
  String? get authToken => _authToken;
  String? get deviceName => _deviceName;

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
        prefs.getInt(_themeStyleKey) ?? 0; // Default to Florid
    if (themeStyleIndex >= 0 && themeStyleIndex < ThemeStyle.values.length) {
      _themeStyle = ThemeStyle.values[themeStyleIndex];
    }
    _autoInstallApk = prefs.getBool(_autoInstallKey) ?? true;
    _autoDeleteApk = prefs.getBool(_autoDeleteKey) ?? true;
    _locale = prefs.getString(_localeKey) ?? 'en-US';
    _onboardingComplete = prefs.getBool(_onboardingCompleteKey) ?? false;
    
    // Load web sync settings
    _webSyncEnabled = prefs.getBool(_webSyncEnabledKey) ?? false;
    _deviceId = prefs.getString(_deviceIdKey);
    _userId = prefs.getString(_userIdKey);
    _authToken = prefs.getString(_authTokenKey);
    _deviceName = prefs.getString(_deviceNameKey);
    
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
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale);
  }

  Future<void> setOnboardingComplete([bool value = true]) async {
    _onboardingComplete = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, value);
  }

  /// Enable or disable web sync
  Future<void> setWebSyncEnabled(bool value) async {
    _webSyncEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_webSyncEnabledKey, value);
  }

  /// Save device pairing information
  Future<void> saveDevicePairing({
    required String deviceId,
    required String userId,
    required String authToken,
    String? deviceName,
  }) async {
    _deviceId = deviceId;
    _userId = userId;
    _authToken = authToken;
    _deviceName = deviceName;
    _webSyncEnabled = true;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deviceIdKey, deviceId);
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_authTokenKey, authToken);
    if (deviceName != null) {
      await prefs.setString(_deviceNameKey, deviceName);
    }
    await prefs.setBool(_webSyncEnabledKey, true);
    
    notifyListeners();
  }

  /// Clear device pairing information
  Future<void> clearDevicePairing() async {
    _deviceId = null;
    _userId = null;
    _authToken = null;
    _deviceName = null;
    _webSyncEnabled = false;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deviceIdKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_authTokenKey);
    await prefs.remove(_deviceNameKey);
    await prefs.setBool(_webSyncEnabledKey, false);
    
    notifyListeners();
  }

  /// Update device name
  Future<void> setDeviceName(String deviceName) async {
    _deviceName = deviceName;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deviceNameKey, deviceName);
  }
}
