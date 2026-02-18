import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeStyle { material, florid }

enum UpdateNetworkPolicy { any, wifiOnly, wifiAndCharging }

enum InstallMethod { system, shizuku }

class SettingsProvider extends ChangeNotifier {
  static const _themeModeKey = 'theme_mode';
  static const _themeStyleKey = 'theme_style';
  static const _autoInstallKey = 'auto_install_apk';
  static const _autoDeleteKey = 'auto_delete_apk';
  static const _installMethodKey = 'install_method';
  static const _localeKey = 'locale';
  static const _onboardingCompleteKey = 'onboarding_complete';
  static const _sniBypassKey = 'sni_bypass_enabled';
  static const _dynamicColorKey = 'dynamic_color_enabled';
  static const backgroundUpdatesKey = 'background_updates_enabled';
  static const updateIntervalHoursKey = 'background_update_interval_hours';
  static const updateNetworkPolicyKey = 'background_update_network_policy';
  static const _lastSeenVersionKey = 'last_seen_version';
  static const _userNameKey = 'user_name';
  static const _showKeepAndroidOpenCardKey = 'show_keep_android_open_card';

  ThemeMode _themeMode = ThemeMode.system;
  ThemeStyle _themeStyle = ThemeStyle.florid;
  bool _autoInstallApk = true;
  bool _autoDeleteApk = true;
  InstallMethod _installMethod = InstallMethod.system;
  String _locale = 'en-US';
  bool _onboardingComplete = false;
  bool _sniBypassEnabled = true;
  bool _dynamicColorEnabled = false;
  bool _backgroundUpdatesEnabled = true;
  bool _showKeepAndroidOpenCard = true;
  int _updateIntervalHours = 6;
  UpdateNetworkPolicy _updateNetworkPolicy = UpdateNetworkPolicy.any;
  bool _loaded = false;
  String _lastSeenVersion = '';
  String _userName = '';

  SettingsProvider() {
    _load();
  }

  bool get isLoaded => _loaded;
  ThemeMode get themeMode => _themeMode;
  ThemeStyle get themeStyle => _themeStyle;
  bool get autoInstallApk => _autoInstallApk;
  bool get autoDeleteApk => _autoDeleteApk;
  InstallMethod get installMethod => _installMethod;
  String get locale => _locale;
  bool get onboardingComplete => _onboardingComplete;
  bool get sniBypassEnabled => _sniBypassEnabled;
  bool get dynamicColorEnabled => _dynamicColorEnabled;
  bool get backgroundUpdatesEnabled => _backgroundUpdatesEnabled;
  int get updateIntervalHours => _updateIntervalHours;
  UpdateNetworkPolicy get updateNetworkPolicy => _updateNetworkPolicy;
  bool get showKeepAndroidOpenCard => _showKeepAndroidOpenCard;
  String get lastSeenVersion => _lastSeenVersion;
  String get userName => _userName;

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
    final installMethodIndex = prefs.getInt(_installMethodKey);
    if (installMethodIndex != null &&
        installMethodIndex >= 0 &&
        installMethodIndex < InstallMethod.values.length) {
      _installMethod = InstallMethod.values[installMethodIndex];
    }
    _locale = prefs.getString(_localeKey) ?? 'en-US';
    _onboardingComplete = prefs.getBool(_onboardingCompleteKey) ?? false;
    _sniBypassEnabled = prefs.getBool(_sniBypassKey) ?? true;
    _dynamicColorEnabled = prefs.getBool(_dynamicColorKey) ?? false;
    _backgroundUpdatesEnabled = prefs.getBool(backgroundUpdatesKey) ?? true;
    _showKeepAndroidOpenCard =
        prefs.getBool(_showKeepAndroidOpenCardKey) ?? true;
    _updateIntervalHours = prefs.getInt(updateIntervalHoursKey) ?? 6;
    final policyIndex =
        prefs.getInt(updateNetworkPolicyKey) ?? UpdateNetworkPolicy.any.index;
    if (policyIndex >= 0 && policyIndex < UpdateNetworkPolicy.values.length) {
      _updateNetworkPolicy = UpdateNetworkPolicy.values[policyIndex];
    }
    _lastSeenVersion = prefs.getString(_lastSeenVersionKey) ?? '';
    _userName = prefs.getString(_userNameKey) ?? '';
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

  Future<void> setInstallMethod(InstallMethod method) async {
    _installMethod = method;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_installMethodKey, method.index);
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

  Future<void> setSniBypassEnabled(bool value) async {
    _sniBypassEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sniBypassKey, value);
  }

  Future<void> setDynamicColorEnabled(bool value) async {
    _dynamicColorEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dynamicColorKey, value);
  }

  Future<void> setShowKeepAndroidOpenCard(bool value) async {
    _showKeepAndroidOpenCard = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showKeepAndroidOpenCardKey, value);
  }

  Future<void> setBackgroundUpdatesEnabled(bool value) async {
    _backgroundUpdatesEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(backgroundUpdatesKey, value);
  }

  Future<void> setUpdateIntervalHours(int hours) async {
    _updateIntervalHours = hours;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(updateIntervalHoursKey, hours);
  }

  Future<void> setUpdateNetworkPolicy(UpdateNetworkPolicy policy) async {
    _updateNetworkPolicy = policy;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(updateNetworkPolicyKey, policy.index);
  }

  Future<void> setLastSeenVersion(String version) async {
    _lastSeenVersion = version;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSeenVersionKey, version);
  }

  Future<void> setUserName(String name) async {
    _userName = name;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
  }
}
