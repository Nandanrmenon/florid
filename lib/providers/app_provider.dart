import 'package:flutter/foundation.dart';
import 'package:installed_apps/app_info.dart' as installed;
import 'package:installed_apps/installed_apps.dart';

import '../models/fdroid_app.dart';
import '../services/fdroid_api_service.dart';

enum LoadingState { idle, loading, success, error }

// Simple app info model for basic functionality
class AppInfo {
  final String packageName;
  final String? versionName;
  final int? versionCode;
  final String appName;

  const AppInfo({
    required this.packageName,
    this.versionName,
    this.versionCode,
    required this.appName,
  });
}

class AppProvider extends ChangeNotifier {
  final FDroidApiService _apiService;

  AppProvider(this._apiService);

  // Latest apps state
  List<FDroidApp> _latestApps = [];
  LoadingState _latestAppsState = LoadingState.idle;
  String? _latestAppsError;

  // Categories state
  List<String> _categories = [];
  LoadingState _categoriesState = LoadingState.idle;
  String? _categoriesError;

  // Search state
  List<FDroidApp> _searchResults = [];
  LoadingState _searchState = LoadingState.idle;
  String? _searchError;
  String _searchQuery = '';

  // Category apps state
  final Map<String, List<FDroidApp>> _categoryApps = {};
  LoadingState _categoryAppsState = LoadingState.idle;
  String? _categoryAppsError;

  // Installed apps state
  List<AppInfo> _installedApps = [];
  LoadingState _installedAppsState = LoadingState.idle;

  // Repository state
  FDroidRepository? _repository;

  // Getters
  List<FDroidApp> get latestApps => _latestApps;
  LoadingState get latestAppsState => _latestAppsState;
  String? get latestAppsError => _latestAppsError;

  List<String> get categories => _categories;
  LoadingState get categoriesState => _categoriesState;
  String? get categoriesError => _categoriesError;

  List<FDroidApp> get searchResults => _searchResults;
  LoadingState get searchState => _searchState;
  String? get searchError => _searchError;
  String get searchQuery => _searchQuery;

  Map<String, List<FDroidApp>> get categoryApps => _categoryApps;
  LoadingState get categoryAppsState => _categoryAppsState;
  String? get categoryAppsError => _categoryAppsError;

  List<AppInfo> get installedApps => _installedApps;
  LoadingState get installedAppsState => _installedAppsState;

  FDroidRepository? get repository => _repository;

  /// Fetches the complete repository (cached for performance)
  Future<void> fetchRepository() async {
    if (_repository != null) return; // Use cached version

    try {
      _repository = await _apiService.fetchRepository();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching repository: $e');
    }
  }

  /// Fetches latest apps from F-Droid
  Future<void> fetchLatestApps() async {
    _latestAppsState = LoadingState.loading;
    _latestAppsError = null;
    notifyListeners();

    try {
      _latestApps = await _apiService.fetchLatestApps();
      _latestAppsState = LoadingState.success;
    } catch (e) {
      _latestAppsError = e.toString();
      _latestAppsState = LoadingState.error;
    }
    notifyListeners();
  }

  /// Fetches categories from F-Droid
  Future<void> fetchCategories() async {
    _categoriesState = LoadingState.loading;
    _categoriesError = null;
    notifyListeners();

    try {
      _categories = await _apiService.fetchCategories();
      _categoriesState = LoadingState.success;
    } catch (e) {
      _categoriesError = e.toString();
      _categoriesState = LoadingState.error;
    }
    notifyListeners();
  }

  /// Fetches apps by category
  Future<void> fetchAppsByCategory(String category) async {
    if (_categoryApps.containsKey(category)) return; // Use cached version

    _categoryAppsState = LoadingState.loading;
    _categoryAppsError = null;
    notifyListeners();

    try {
      final apps = await _apiService.fetchAppsByCategory(category);
      _categoryApps[category] = apps;
      _categoryAppsState = LoadingState.success;
    } catch (e) {
      _categoryAppsError = e.toString();
      _categoryAppsState = LoadingState.error;
    }
    notifyListeners();
  }

  /// Searches for apps
  Future<void> searchApps(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      _searchQuery = '';
      notifyListeners();
      return;
    }

    _searchQuery = query;
    _searchState = LoadingState.loading;
    _searchError = null;
    notifyListeners();

    try {
      _searchResults = await _apiService.searchApps(query);
      _searchState = LoadingState.success;
    } catch (e) {
      _searchError = e.toString();
      _searchState = LoadingState.error;
    }
    notifyListeners();
  }

  /// Clears search results
  void clearSearch() {
    _searchResults = [];
    _searchQuery = '';
    _searchState = LoadingState.idle;
    _searchError = null;
    notifyListeners();
  }

  /// Fetches installed apps from device (simplified version)
  Future<void> fetchInstalledApps() async {
    _installedAppsState = LoadingState.loading;
    notifyListeners();

    try {
      final apps = await InstalledApps.getInstalledApps();

      _installedApps = apps
          .where((app) => app.packageName.isNotEmpty)
          .map(
            (installed.AppInfo app) => AppInfo(
              packageName: app.packageName,
              appName: app.name,
              versionName: app.versionName,
              versionCode: app.versionCode,
            ),
          )
          .toList();

      _installedAppsState = LoadingState.success;
    } catch (e) {
      debugPrint('Error fetching installed apps: $e');
      _installedAppsState = LoadingState.error;
    }
    notifyListeners();
  }

  /// Gets apps that have updates available
  List<FDroidApp> getUpdatableApps() {
    if (_repository == null || _installedApps.isEmpty) {
      return [];
    }

    final updatableApps = <FDroidApp>[];

    for (final installedApp in _installedApps) {
      // Check if the app exists in F-Droid repository
      final fdroidApp = _repository!.apps[installedApp.packageName];
      if (fdroidApp == null) continue;

      // Check if F-Droid app has a latest version
      if (fdroidApp.latestVersion == null) continue;

      // Check if installed app has version info
      if (installedApp.versionCode == null) continue;

      // Compare version codes - if F-Droid has a newer version, it's updatable
      if (fdroidApp.latestVersion!.versionCode > installedApp.versionCode!) {
        updatableApps.add(fdroidApp);
      }
    }

    // Sort by app name for consistent ordering
    updatableApps.sort((a, b) => a.name.compareTo(b.name));

    return updatableApps;
  }

  /// Checks if an app is installed (simplified version)
  bool isAppInstalled(String packageName) {
    return _installedApps.any((app) => app.packageName == packageName);
  }

  /// Gets the installed version of an app (simplified version)
  AppInfo? getInstalledApp(String packageName) {
    try {
      return _installedApps.firstWhere((app) => app.packageName == packageName);
    } catch (_) {
      return null;
    }
  }

  /// Attempts to launch an installed app by package name
  Future<bool> openInstalledApp(String packageName) async {
    try {
      final result = await InstalledApps.startApp(packageName);
      if (result is bool) return result;
      return true;
    } catch (e) {
      debugPrint('Error opening app $packageName: $e');
      return false;
    }
  }

  /// Refreshes all data
  Future<void> refreshAll() async {
    // Clear cached data
    _repository = null;
    _categoryApps.clear();

    // Reload data
    await Future.wait([
      fetchRepository(),
      fetchLatestApps(),
      fetchCategories(),
      fetchInstalledApps(),
    ]);
  }

  /// Gets screenshots for an app package
  Future<List<String>> getScreenshots(String packageName) async {
    return await _apiService.getScreenshots(packageName);
  }
}
