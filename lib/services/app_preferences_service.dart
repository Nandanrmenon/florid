import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing per-app preferences like unstable version opt-in
/// These preferences are only kept for installed apps
class AppPreferencesService {
  static const String _unstableKeyPrefix = 'app_unstable_';

  /// Gets whether unstable versions should be included for a specific app
  /// Returns false by default (only stable versions)
  Future<bool> getIncludeUnstable(String packageName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_unstableKeyPrefix$packageName') ?? false;
  }

  /// Sets whether unstable versions should be included for a specific app
  /// This should only be called for installed apps
  Future<void> setIncludeUnstable(String packageName, bool include) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_unstableKeyPrefix$packageName', include);
  }

  /// Removes the unstable preference for an app (call when app is uninstalled)
  Future<void> removeIncludeUnstable(String packageName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_unstableKeyPrefix$packageName');
  }

  /// Gets all apps that have unstable version preferences set
  Future<Set<String>> getAllAppsWithUnstablePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_unstableKeyPrefix));
    return keys.map((key) => key.substring(_unstableKeyPrefix.length)).toSet();
  }

  /// Cleans up preferences for apps that are no longer installed
  Future<void> cleanupUninstalledApps(Set<String> installedPackages) async {
    final appsWithPrefs = await getAllAppsWithUnstablePreference();
    for (final packageName in appsWithPrefs) {
      if (!installedPackages.contains(packageName)) {
        await removeIncludeUnstable(packageName);
      }
    }
  }
}
