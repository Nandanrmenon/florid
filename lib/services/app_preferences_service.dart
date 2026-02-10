import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing per-app preferences and favorites.
class AppPreferencesService {
  static const String _unstableKeyPrefix = 'app_unstable_';
  static const String _favoritesKey = 'favorite_apps';

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
    final keys = prefs.getKeys().where(
      (key) => key.startsWith(_unstableKeyPrefix),
    );
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

  Future<Set<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_favoritesKey) ?? <String>[];
    return favorites.toSet();
  }

  Future<void> setFavorites(Set<String> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, favorites.toList());
  }

  Future<void> addFavorite(String packageName) async {
    final favorites = await getFavorites();
    favorites.add(packageName);
    await setFavorites(favorites);
  }

  Future<void> removeFavorite(String packageName) async {
    final favorites = await getFavorites();
    favorites.remove(packageName);
    await setFavorites(favorites);
  }
}
