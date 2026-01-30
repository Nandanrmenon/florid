import 'package:flutter/foundation.dart';
import 'package:installed_apps/app_info.dart' as installed;
import 'package:installed_apps/installed_apps.dart';

import '../models/fdroid_app.dart';
import '../services/fdroid_api_service.dart';
import 'repositories_provider.dart';

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

  // Recently updated apps state
  List<FDroidApp> _recentlyUpdatedApps = [];
  LoadingState _recentlyUpdatedAppsState = LoadingState.idle;
  String? _recentlyUpdatedAppsError;

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
  LoadingState _repositoryState = LoadingState.idle;
  String? _repositoryError;

  // Getters
  List<FDroidApp> get latestApps => _latestApps;
  LoadingState get latestAppsState => _latestAppsState;
  String? get latestAppsError => _latestAppsError;

  List<FDroidApp> get recentlyUpdatedApps => _recentlyUpdatedApps;
  LoadingState get recentlyUpdatedAppsState => _recentlyUpdatedAppsState;
  String? get recentlyUpdatedAppsError => _recentlyUpdatedAppsError;

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
  LoadingState get repositoryState => _repositoryState;
  String? get repositoryError => _repositoryError;

  /// Fetches the complete repository (cached for performance)
  Future<void> fetchRepository() async {
    if (_repository != null) return; // Use cached version

    _repositoryState = LoadingState.loading;
    _repositoryError = null;
    notifyListeners();

    try {
      _repository = await _apiService.fetchRepository();
      _repositoryState = LoadingState.success;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching repository: $e');
      _repositoryError = e.toString();
      _repositoryState = LoadingState.error;
      notifyListeners();
    }
  }

  /// Fetches and merges repositories from multiple URLs
  Future<FDroidRepository?> fetchRepositoriesFromUrls(List<String> urls) async {
    if (urls.isEmpty) return null;

    try {
      debugPrint('Fetching from ${urls.length} repository URLs');

      final repositories = <FDroidRepository>[];

      // Fetch all repositories, handling errors per URL
      for (final url in urls) {
        try {
          final repo = await _apiService.fetchRepositoryFromUrl(url);
          repositories.add(repo);

          // Also import to database for future searches
          // Get the repository ID from the repositories table by URL
          try {
            final repoId = await _apiService.getRepositoryIdByUrl(url);
            if (repoId != null) {
              await _apiService.importRepositoryToDatabase(
                repo,
                repositoryId: repoId,
              );
            }
          } catch (e) {
            debugPrint('Error importing custom repo to database: $e');
            // Continue even if import fails
          }

          debugPrint('Successfully fetched repository from $url');
        } catch (e) {
          debugPrint('Failed to fetch repository from $url: $e');
          // Continue with other URLs if one fails
        }
      }

      if (repositories.isEmpty) {
        throw Exception('Failed to fetch from any repository');
      }

      // Merge all repositories into one
      final mergedRepo = _mergeRepositories(repositories);
      notifyListeners();
      return mergedRepo;
    } catch (e) {
      debugPrint('Error fetching from multiple repositories: $e');
      return null;
    }
  }

  /// Merges multiple repositories into one, tracking all available sources
  FDroidRepository _mergeRepositories(List<FDroidRepository> repos) {
    final mergedApps = <String, FDroidApp>{};

    // Merge all apps from all repositories
    for (final repo in repos) {
      for (final entry in repo.apps.entries) {
        final packageName = entry.key;
        final app = entry.value;
        
        if (mergedApps.containsKey(packageName)) {
          // App already exists, add this repository to the available sources
          final existing = mergedApps[packageName]!;
          final repoSource = RepositorySource(
            name: repo.name,
            url: app.repositoryUrl,
          );
          
          // Add the new repository if it's not already in the list
          final availableRepos = existing.availableRepositories ?? [];
          if (!availableRepos.contains(repoSource)) {
            // Create new list with the additional repository
            final updatedRepos = [...availableRepos, repoSource];
            
            // Keep the existing app but update available repositories
            mergedApps[packageName] = existing.copyWith(
              availableRepositories: updatedRepos,
            );
          }
        } else {
          // First time seeing this app, add it with its repository as a source
          mergedApps[packageName] = app.copyWith(
            availableRepositories: [
              RepositorySource(
                name: repo.name,
                url: app.repositoryUrl,
              ),
            ],
          );
        }
      }
    }

    // Use the first repo's metadata
    return FDroidRepository(
      name: 'Merged Repositories',
      description: 'Merged from ${repos.length} repositories',
      icon: repos.first.icon,
      timestamp: repos.first.timestamp,
      version: repos.first.version,
      maxage: repos.first.maxage,
      apps: mergedApps,
    );
  }

  /// Enriches a single app with repository information from all enabled repositories
  /// This is useful when displaying app details to show which repositories host the app
  Future<FDroidApp> enrichAppWithRepositories(
    FDroidApp app,
    RepositoriesProvider? repositoriesProvider,
  ) async {
    if (repositoriesProvider == null) {
      return app;
    }

    try {
      // Ensure repositories are loaded
      if (repositoriesProvider.repositories.isEmpty) {
        if (!repositoriesProvider.isLoading) {
          await repositoriesProvider.loadRepositories();
        } else {
          // Wait a bit for loading to complete
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      final enabledRepos = repositoriesProvider.enabledRepositories;
      if (enabledRepos.isEmpty) {
        return app;
      }

      // Start with original repository source if not null
      final availableReposList = <RepositorySource>[];
      if (app.repositoryUrl.isNotEmpty) {
        // Find the repo name for the original URL
        final originalRepo = enabledRepos.where((r) => r.url == app.repositoryUrl).firstOrNull;
        if (originalRepo != null) {
          availableReposList.add(RepositorySource(
            name: originalRepo.name,
            url: app.repositoryUrl,
          ));
        }
      }

      // Query all repositories in parallel for better performance
      final repoChecks = await Future.wait(
        enabledRepos.map((repo) async {
          try {
            // Skip if already added as original
            if (repo.url == app.repositoryUrl) {
              return null;
            }
            
            // Try to find the app in this repository via database
            final results = await _apiService.searchAppsFromRepositoryUrl(
              app.packageName, // Use exact package name for lookup
              repo.url,
            );
            
            // If found in this repository, return the source
            if (results.any((a) => a.packageName == app.packageName)) {
              return RepositorySource(name: repo.name, url: repo.url);
            }
          } catch (e) {
            debugPrint('Error checking repo ${repo.name} for ${app.packageName}: $e');
          }
          return null;
        }),
      );

      // Filter out nulls and add to available repos
      availableReposList.addAll(repoChecks.whereType<RepositorySource>());

      // If we found the app in repositories, update it
      if (availableReposList.isNotEmpty) {
        return app.copyWith(availableRepositories: availableReposList);
      }

      return app;
    } catch (e) {
      debugPrint('Error enriching app with repositories: $e');
      return app;
    }
  }

  /// Fetches latest apps from F-Droid and custom repositories
  Future<void> fetchLatestApps({
    RepositoriesProvider? repositoriesProvider,
    int limit = 50,
  }) async {
    _latestAppsState = LoadingState.loading;
    _latestAppsError = null;
    notifyListeners();

    try {
      List<FDroidApp> apps = [];

      // Try to fetch from custom repositories if available
      if (repositoriesProvider != null) {
        // Ensure repositories are loaded before checking enabled ones
        if (repositoriesProvider.repositories.isEmpty &&
            !repositoriesProvider.isLoading) {
          await repositoriesProvider.loadRepositories();
        }

        final customRepos = repositoriesProvider.enabledRepositories;
        if (customRepos.isNotEmpty) {
          final customUrls = customRepos.map((r) => r.url).toList();
          final mergedRepo = await fetchRepositoriesFromUrls(customUrls);
          if (mergedRepo != null) {
            // Get latest apps from merged repository
            final latestApps = mergedRepo.apps.values.toList();
            latestApps.sort((a, b) {
              final aAdded = a.added?.millisecondsSinceEpoch ?? 0;
              final bAdded = b.added?.millisecondsSinceEpoch ?? 0;
              return bAdded.compareTo(aAdded); // Latest first
            });
            apps = latestApps.take(limit).toList();
            _latestApps = apps;
            _latestAppsState = LoadingState.success;
            notifyListeners();
            return;
          }
        }
      }

      // Fall back to official F-Droid
      _latestApps = await _apiService.fetchLatestApps(limit: limit);
      _latestAppsState = LoadingState.success;
    } catch (e) {
      _latestAppsError = e.toString();
      _latestAppsState = LoadingState.error;
    }
    notifyListeners();
  }

  /// Fetches recently updated apps from F-Droid and custom repositories
  Future<void> fetchRecentlyUpdatedApps({
    RepositoriesProvider? repositoriesProvider,
    int limit = 50,
  }) async {
    _recentlyUpdatedAppsState = LoadingState.loading;
    _recentlyUpdatedAppsError = null;
    notifyListeners();

    try {
      List<FDroidApp> apps = [];

      // Try to fetch from custom repositories if available
      if (repositoriesProvider != null) {
        // Ensure repositories are loaded before checking enabled ones
        if (repositoriesProvider.repositories.isEmpty &&
            !repositoriesProvider.isLoading) {
          await repositoriesProvider.loadRepositories();
        }

        final customRepos = repositoriesProvider.enabledRepositories;
        if (customRepos.isNotEmpty) {
          final customUrls = customRepos.map((r) => r.url).toList();
          final mergedRepo = await fetchRepositoriesFromUrls(customUrls);
          if (mergedRepo != null) {
            // Get recently updated apps from merged repository
            final recentlyUpdatedApps = mergedRepo.apps.values.toList();
            recentlyUpdatedApps.sort((a, b) {
              final aUpdated = a.lastUpdated?.millisecondsSinceEpoch ?? 0;
              final bUpdated = b.lastUpdated?.millisecondsSinceEpoch ?? 0;
              return bUpdated.compareTo(aUpdated); // Most recent first
            });
            apps = recentlyUpdatedApps.take(limit).toList();
            _recentlyUpdatedApps = apps;
            _recentlyUpdatedAppsState = LoadingState.success;
            notifyListeners();
            return;
          }
        }
      }

      // Fall back to official F-Droid
      final allApps = await _apiService.fetchApps(limit: limit * 2);
      allApps.sort((a, b) {
        final aUpdated = a.lastUpdated?.millisecondsSinceEpoch ?? 0;
        final bUpdated = b.lastUpdated?.millisecondsSinceEpoch ?? 0;
        return bUpdated.compareTo(aUpdated);
      });
      _recentlyUpdatedApps = allApps.take(limit).toList();
      _recentlyUpdatedAppsState = LoadingState.success;
    } catch (e) {
      _recentlyUpdatedAppsError = e.toString();
      _recentlyUpdatedAppsState = LoadingState.error;
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
  Future<void> searchApps(
    String query, {
    RepositoriesProvider? repositoriesProvider,
  }) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      _searchQuery = '';
      notifyListeners();
      return;
    }

    // Prevent duplicate searches for the same query
    if (_searchQuery == query && _searchState == LoadingState.loading) {
      return;
    }

    _searchQuery = query;
    _searchState = LoadingState.loading;
    _searchError = null;
    notifyListeners();

    try {
      final combined = <String, FDroidApp>{};

      // Search in custom repositories from database
      if (repositoriesProvider != null) {
        if (repositoriesProvider.repositories.isEmpty &&
            !repositoriesProvider.isLoading) {
          await repositoriesProvider.loadRepositories();
        }

        // For each enabled custom repo, search in database
        final customRepos = repositoriesProvider.enabledRepositories;
        if (customRepos.isNotEmpty) {
          // Search from database for custom repos (they should be imported there)
          for (final customRepo in customRepos) {
            try {
              // Search in database - results should be there if repo was previously imported
              final results = await _apiService.searchAppsFromRepositoryUrl(
                query,
                customRepo.url,
              );
              for (final app in results) {
                combined[app.packageName] = app;
              }
            } catch (e) {
              debugPrint('Error searching custom repo ${customRepo.name}: $e');
            }
          }
        }
      }

      // Official F-Droid search as fallback/merge
      final officialResults = await _apiService.searchApps(query);
      for (final app in officialResults) {
        combined.putIfAbsent(app.packageName, () => app);
      }

      // Sort results alphabetically for stability
      _searchResults = combined.values.toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
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
  Future<void> refreshAll({RepositoriesProvider? repositoriesProvider}) async {
    // Clear cached data
    _repository = null;
    _repositoryState = LoadingState.idle;
    _repositoryError = null;
    _categoryApps.clear();

    // Reload data
    await Future.wait([
      fetchRepository(),
      fetchLatestApps(repositoriesProvider: repositoriesProvider),
      fetchCategories(),
      fetchInstalledApps(),
    ]);
  }

  /// Gets screenshots for an app package
  Future<List<String>> getScreenshots(
    String packageName, {
    String? repositoryUrl,
  }) async {
    return await _apiService.getScreenshots(
      packageName,
      repositoryUrl: repositoryUrl,
    );
  }
}
