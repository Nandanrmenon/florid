import 'package:shared_preferences/shared_preferences.dart';

/// Service for tracking which repository each app was downloaded from
class InstallationTrackingService {
  static const String _keyPrefix = 'app_source_';

  /// Saves the repository URL that an app was downloaded from
  Future<void> setAppSource(String packageName, String repositoryUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_keyPrefix$packageName', repositoryUrl);
  }

  /// Gets the repository URL that an app was downloaded from
  Future<String?> getAppSource(String packageName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_keyPrefix$packageName');
  }

  /// Removes the tracking data for an app (call when app is uninstalled)
  Future<void> removeAppSource(String packageName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_keyPrefix$packageName');
  }

  /// Gets all tracked app sources
  Future<Map<String, String>> getAllAppSources() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_keyPrefix));
    final Map<String, String> sources = {};
    
    for (final key in keys) {
      final packageName = key.substring(_keyPrefix.length);
      final source = prefs.getString(key);
      if (source != null) {
        sources[packageName] = source;
      }
    }
    
    return sources;
  }
}
