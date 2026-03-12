import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:installed_apps/app_info.dart' as installed;
import 'package:installed_apps/installed_apps.dart';

import '../models/fdroid_app.dart';
import '../models/repository.dart';
import '../models/search_filters.dart';
import '../services/app_preferences_service.dart';
import '../services/fdroid_api_service.dart';
import '../services/izzy_stats_service.dart';
import 'repositories_provider.dart';
import 'settings_provider.dart';

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
  final IzzyStatsService _izzyStatsService = IzzyStatsService();
  SettingsProvider? _settingsProvider;
  final AppPreferencesService _preferencesService = AppPreferencesService();

  AppProvider(this._apiService, [this._settingsProvider]) {
    _loadFavorites();
  }

  void updateSettings(SettingsProvider settings) {
    _settingsProvider = settings;
    notifyListeners();
  }

  // Latest apps state
  List<FDroidApp> _latestApps = [];
  LoadingState _latestAppsState = LoadingState.idle;
  String? _latestAppsError;

  // Recently updated apps state
  List<FDroidApp> _recentlyUpdatedApps = [];
  LoadingState _recentlyUpdatedAppsState = LoadingState.idle;
  String? _recentlyUpdatedAppsError;

  // Top apps state (from IzzyOnDroid)
  List<FDroidApp> _topApps = [];
  LoadingState _topAppsState = LoadingState.idle;
  String? _topAppsError;
  Map<String, int> _topAppsDownloads = {};

  // Top apps all-time state (from IzzyOnDroid)
  List<FDroidApp> _topAppsAllTime = [];
  LoadingState _topAppsAllTimeState = LoadingState.idle;
  String? _topAppsAllTimeError;
  Map<String, int> _topAppsAllTimeDownloads = {};

  // Categories state
  List<String> _categories = [];
  LoadingState _categoriesState = LoadingState.idle;
  String? _categoriesError;

  // Search state
  List<FDroidApp> _searchResults = [];
  List<FDroidApp> _allSearchResults = [];
  LoadingState _searchState = LoadingState.idle;
  LoadingState _searchLoadMoreState = LoadingState.idle;
  String? _searchError;
  String _searchQuery = '';
  static const int _searchPageSize = 10;
  int _searchCurrentPage = 0;

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

  // Favorites state
  Set<String> _favoritePackages = {};

  // Cached device ABI list
  List<String>? _supportedAbis;

  // Prevent duplicate ABI debug logs on repeated rebuild-driven calls.
  final Map<String, String> _lastAbiSelectionLogByPackage = {};

  // Getters
  List<FDroidApp> get latestApps => _latestApps;
  LoadingState get latestAppsState => _latestAppsState;
  String? get latestAppsError => _latestAppsError;

  List<FDroidApp> get recentlyUpdatedApps => _recentlyUpdatedApps;
  LoadingState get recentlyUpdatedAppsState => _recentlyUpdatedAppsState;
  String? get recentlyUpdatedAppsError => _recentlyUpdatedAppsError;

  List<FDroidApp> get topApps => _topApps;
  LoadingState get topAppsState => _topAppsState;
  String? get topAppsError => _topAppsError;
  Map<String, int> get topAppsDownloads => _topAppsDownloads;

  List<FDroidApp> get topAppsAllTime => _topAppsAllTime;
  LoadingState get topAppsAllTimeState => _topAppsAllTimeState;
  String? get topAppsAllTimeError => _topAppsAllTimeError;
  Map<String, int> get topAppsAllTimeDownloads => _topAppsAllTimeDownloads;

  List<String> get categories => _categories;
  LoadingState get categoriesState => _categoriesState;
  String? get categoriesError => _categoriesError;

  List<FDroidApp> get searchResults => _searchResults;
  LoadingState get searchState => _searchState;
  LoadingState get searchLoadMoreState => _searchLoadMoreState;
  String? get searchError => _searchError;
  String get searchQuery => _searchQuery;
  int get totalSearchResults => _allSearchResults.length;

  Map<String, List<FDroidApp>> get categoryApps => _categoryApps;
  LoadingState get categoryAppsState => _categoryAppsState;
  String? get categoryAppsError => _categoryAppsError;

  List<AppInfo> get installedApps => _installedApps;
  LoadingState get installedAppsState => _installedAppsState;

  FDroidRepository? get repository => _repository;
  LoadingState get repositoryState => _repositoryState;
  String? get repositoryError => _repositoryError;

  Set<String> get favoritePackages => _favoritePackages;
  bool isFavorite(String packageName) =>
      _favoritePackages.contains(packageName);

  List<FDroidApp> getFavoriteApps() {
    if (_repository == null || _favoritePackages.isEmpty) {
      return <FDroidApp>[];
    }

    final favorites = _favoritePackages
        .map((packageName) => _repository!.apps[packageName])
        .whereType<FDroidApp>()
        .toList();
    favorites.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return favorites;
  }

  Future<void> toggleFavorite(String packageName) async {
    if (_favoritePackages.contains(packageName)) {
      _favoritePackages.remove(packageName);
    } else {
      _favoritePackages.add(packageName);
    }
    await _preferencesService.setFavorites(_favoritePackages);
    notifyListeners();
  }

  Future<void> setFavorites(Set<String> favorites, {bool merge = false}) async {
    if (merge) {
      _favoritePackages = {..._favoritePackages, ...favorites};
    } else {
      _favoritePackages = {...favorites};
    }
    await _preferencesService.setFavorites(_favoritePackages);
    if (_repository == null && _repositoryState != LoadingState.loading) {
      await fetchRepository();
    }
    notifyListeners();
  }

  Future<void> _loadFavorites() async {
    _favoritePackages = await _preferencesService.getFavorites();
    notifyListeners();
  }

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

      // Fetch all repositories concurrently, handling errors per URL
      final futures = urls.map((url) async {
        try {
          final repo = await _apiService.fetchRepositoryFromUrl(url);

          // Also import to database for future searches
          // Get the repository ID from the repositories table by URL
          try {
            final repoId = await _apiService.getRepositoryIdByUrl(url);
            if (repoId != null) {
              await _apiService.importRepositoryToDatabase(
                repo,
                repositoryId: repoId,
              );
            } else {
              debugPrint('⚠️ No repository ID found for URL: $url');
            }
          } catch (e) {
            debugPrint('Error importing custom repo to database: $e');
            // Continue even if import fails
          }
          return repo;
        } catch (e) {
          debugPrint('Failed to fetch repository from $url: $e');
          // Continue with other URLs if one fails
          return null;
        }
      });

      final results = await Future.wait(futures);
      repositories.addAll(results.whereType<FDroidRepository>());

      if (repositories.isEmpty) {
        throw Exception('Failed to fetch from any repository');
      }

      // Merge all repositories into one
      final mergedRepo = _mergeRepositories(repositories);
      _repository = mergedRepo;
      _repositoryState = LoadingState.success;
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
              RepositorySource(name: repo.name, url: app.repositoryUrl),
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
        final originalRepo = enabledRepos
            .where((r) => r.url == app.repositoryUrl)
            .firstOrNull;
        if (originalRepo != null) {
          availableReposList.add(
            RepositorySource(name: originalRepo.name, url: app.repositoryUrl),
          );
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
              allowNetworkFallback: false,
            );

            // If found in this repository, return the source
            if (results.any((a) => a.packageName == app.packageName)) {
              return RepositorySource(name: repo.name, url: repo.url);
            }
          } catch (e) {
            debugPrint(
              'Error checking repo ${repo.name} for ${app.packageName}: $e',
            );
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
      // First ensure custom repo models are loaded locally
      if (repositoriesProvider != null &&
          repositoriesProvider.repositories.isEmpty &&
          !repositoriesProvider.isLoading) {
        await repositoriesProvider.loadRepositories();
      }

      // Fetch all apps from the robust database service, which caches them centrally
      final allLatestApps = await _apiService.fetchLatestApps(limit: limit * 2);

      if (repositoriesProvider != null) {
        final customRepos = repositoriesProvider.enabledRepositories;
        final enabledUrls = customRepos.map((r) => r.url).toSet();

        // If they have standard repo vs not standard etc.
        // We only retain apps coming from the valid, enabled URLs or the main official repo
        // which defaults to "https://f-droid.org/repo"
        enabledUrls.add('https://f-droid.org/repo');

        final filteredApps = allLatestApps.where((app) {
          return enabledUrls.contains(app.repositoryUrl);
        }).toList();

        _latestApps = filteredApps.take(limit).toList();
      } else {
        _latestApps = allLatestApps.take(limit).toList();
      }

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
      // First ensure custom repo models are loaded locally
      if (repositoriesProvider != null &&
          repositoriesProvider.repositories.isEmpty &&
          !repositoriesProvider.isLoading) {
        await repositoriesProvider.loadRepositories();
      }

      // Fetch all apps from the robust database service, which caches them centrally
      // Increase limit slightly since we'll filter out disabled ones
      final allApps = await _apiService.fetchApps(limit: limit * 4);
      allApps.sort((a, b) {
        final aUpdated = a.lastUpdated?.millisecondsSinceEpoch ?? 0;
        final bUpdated = b.lastUpdated?.millisecondsSinceEpoch ?? 0;
        return bUpdated.compareTo(aUpdated);
      });

      if (repositoriesProvider != null) {
        final customRepos = repositoriesProvider.enabledRepositories;
        final enabledUrls = customRepos.map((r) => r.url).toSet();

        // Valid fallback original URL
        enabledUrls.add('https://f-droid.org/repo');

        final filteredApps = allApps.where((app) {
          return enabledUrls.contains(app.repositoryUrl);
        }).toList();

        _recentlyUpdatedApps = filteredApps.take(limit).toList();
      } else {
        _recentlyUpdatedApps = allApps.take(limit).toList();
      }

      _recentlyUpdatedAppsState = LoadingState.success;
    } catch (e) {
      _recentlyUpdatedAppsError = e.toString();
      _recentlyUpdatedAppsState = LoadingState.error;
    }
    notifyListeners();
  }

  /// Fetches top downloaded apps from IzzyOnDroid repository
  Future<void> fetchTopApps({
    RepositoriesProvider? repositoriesProvider,
    int limit = 50,
  }) async {
    _topAppsState = LoadingState.loading;
    _topAppsError = null;
    notifyListeners();

    try {
      // First ensure custom repo models are loaded locally
      if (repositoriesProvider != null) {
        // If repositories are currently loading, wait for them
        if (repositoriesProvider.isLoading) {
          // Wait a bit for loading to complete
          await Future.delayed(Duration(milliseconds: 200));
        }
        // If still empty after waiting, load them
        if (repositoriesProvider.repositories.isEmpty) {
          debugPrint('🔄 Fetching top apps: repositories empty, loading...');
          await repositoriesProvider.loadRepositories();
        }
      }

      // Find IzzyOnDroid repository
      Repository? izzyRepo;
      if (repositoriesProvider != null) {
        debugPrint(
          '🔍 Looking for IzzyOnDroid in ${repositoriesProvider.repositories.length} repositories',
        );
        for (final repo in repositoriesProvider.repositories) {
          debugPrint(
            '   - ${repo.name}: ${repo.url} (enabled: ${repo.isEnabled})',
          );
        }
        try {
          izzyRepo = repositoriesProvider.repositories.firstWhere(
            (r) => r.name == 'IzzyOnDroid' && r.isEnabled,
          );
          debugPrint('✅ Found IzzyOnDroid: ${izzyRepo.url}');
        } catch (e) {
          debugPrint('❌ IzzyOnDroid not found: $e');
          izzyRepo = null;
        }
      }

      if (izzyRepo == null) {
        debugPrint('⚠️ Top apps: IzzyOnDroid repository not available');
        _topApps = [];
        _topAppsState = LoadingState.success;
        notifyListeners();
        return;
      }

      // Fetch all apps from IzzyOnDroid repository
      debugPrint('🔗 Fetching from IzzyOnDroid URL directly: ${izzyRepo.url}');
      final izzyRepository = await _apiService.fetchRepositoryFromUrl(
        izzyRepo.url,
      );
      final izzyApps = izzyRepository.apps.values.toList();

      debugPrint(
        '🔍 Got ${izzyApps.length} apps directly from IzzyOnDroid (${izzyRepo.url})',
      );

      if (izzyApps.isEmpty) {
        debugPrint('⚠️ No apps found from IzzyOnDroid, returning empty list');
        _topApps = [];
        _topAppsState = LoadingState.success;
        notifyListeners();
        return;
      }

      // Create a map to store download counts with apps
      final appStats = <FDroidApp, int>{};

      // Fetch download stats for each app
      for (final app in izzyApps) {
        try {
          final stats = await _izzyStatsService.fetchStatsForPackage(
            app.packageName,
          );
          // Use last 30 days downloads only (monthly)
          final downloads = stats.last30Days ?? 0;
          if (downloads > 0) {
            appStats[app] = downloads;
          }
        } catch (e) {
          // If we fail to get stats, skip this app (don't use it)
        }
      }

      // Sort apps by download count (highest first)
      final sortedApps = appStats.entries.toList();
      sortedApps.sort((a, b) => b.value.compareTo(a.value));

      _topApps = sortedApps.take(limit).map((e) => e.key).toList();

      // Store download counts for UI display
      _topAppsDownloads = {};
      for (final entry in sortedApps.take(limit)) {
        _topAppsDownloads[entry.key.packageName] = entry.value;
      }

      _topAppsState = LoadingState.success;
    } catch (e) {
      debugPrint('❌ Error in fetchTopApps: $e');
      _topAppsError = e.toString();
      _topAppsState = LoadingState.error;
    }
    notifyListeners();
  }

  /// Fetches top apps using yearly stats (all-time proxy) from IzzyOnDroid.
  Future<void> fetchTopAppsAllTime({
    RepositoriesProvider? repositoriesProvider,
    int limit = 50,
  }) async {
    _topAppsAllTimeState = LoadingState.loading;
    _topAppsAllTimeError = null;
    notifyListeners();

    try {
      if (repositoriesProvider != null) {
        if (repositoriesProvider.isLoading) {
          await Future.delayed(Duration(milliseconds: 200));
        }
        if (repositoriesProvider.repositories.isEmpty) {
          debugPrint(
            '🔄 Fetching all-time top apps: repositories empty, loading...',
          );
          await repositoriesProvider.loadRepositories();
        }
      }

      Repository? izzyRepo;
      if (repositoriesProvider != null) {
        try {
          izzyRepo = repositoriesProvider.repositories.firstWhere(
            (r) => r.name == 'IzzyOnDroid' && r.isEnabled,
          );
        } catch (_) {
          izzyRepo = null;
        }
      }

      if (izzyRepo == null) {
        _topAppsAllTime = [];
        _topAppsAllTimeState = LoadingState.success;
        notifyListeners();
        return;
      }

      final izzyRepository = await _apiService.fetchRepositoryFromUrl(
        izzyRepo.url,
      );
      final izzyApps = izzyRepository.apps.values.toList();

      if (izzyApps.isEmpty) {
        _topAppsAllTime = [];
        _topAppsAllTimeState = LoadingState.success;
        notifyListeners();
        return;
      }

      final appStats = <FDroidApp, int>{};

      for (final app in izzyApps) {
        try {
          final stats = await _izzyStatsService.fetchStatsForPackage(
            app.packageName,
          );
          final downloads = stats.last365Days ?? 0;
          if (downloads > 0) {
            appStats[app] = downloads;
          }
        } catch (_) {}
      }

      final sortedApps = appStats.entries.toList();
      sortedApps.sort((a, b) => b.value.compareTo(a.value));

      _topAppsAllTime = sortedApps.take(limit).map((e) => e.key).toList();
      _topAppsAllTimeDownloads = {};
      for (final entry in sortedApps.take(limit)) {
        _topAppsAllTimeDownloads[entry.key.packageName] = entry.value;
      }

      _topAppsAllTimeState = LoadingState.success;
    } catch (e) {
      _topAppsAllTimeError = e.toString();
      _topAppsAllTimeState = LoadingState.error;
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

  /// Fetches apps by author name
  Future<List<FDroidApp>> fetchAppsByAuthor(String authorName) async {
    try {
      return await _apiService.fetchAppsByAuthor(authorName);
    } catch (e) {
      throw Exception('Error fetching apps by author: $e');
    }
  }

  /// Searches for apps
  Future<void> searchApps(
    String query, {
    RepositoriesProvider? repositoriesProvider,
    SearchFilters filters = const SearchFilters(),
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      _searchResults = [];
      _searchQuery = '';
      notifyListeners();
      return;
    }

    // Prevent duplicate searches for the same query
    if (_searchQuery == trimmedQuery && _searchState == LoadingState.loading) {
      return;
    }

    _searchQuery = trimmedQuery;
    _searchState = LoadingState.loading;
    _searchError = null;
    notifyListeners();

    try {
      final enabledRepoUrls = <String>{};
      if (repositoriesProvider != null) {
        if (repositoriesProvider.repositories.isEmpty &&
            !repositoriesProvider.isLoading) {
          await repositoriesProvider.loadRepositories();
        }

        enabledRepoUrls.addAll(
          repositoriesProvider.enabledRepositories.map((repo) => repo.url),
        );
      }

      final dbResults = await _apiService.searchAppsDatabaseOnly(trimmedQuery);

      var filteredResults = dbResults.where((app) {
        // Filter by repository
        if (enabledRepoUrls.isEmpty) {
          return true;
        }

        final repoUrl = app.repositoryUrl ?? '';
        if (repoUrl == 'https://f-droid.org/repo') {
          return true;
        }

        return enabledRepoUrls.contains(repoUrl);
      }).toList();

      // Apply category filter
      if (filters.categories.isNotEmpty) {
        filteredResults = filteredResults.where((app) {
          final appCategories = app.categories;
          if (appCategories == null || appCategories.isEmpty) return false;
          return appCategories.any((cat) => filters.categories.contains(cat));
        }).toList();
      }

      // Apply repository filter
      if (filters.repositories.isNotEmpty) {
        filteredResults = filteredResults.where((app) {
          final repoUrl = app.repositoryUrl ?? '';
          return filters.repositories.contains(repoUrl);
        }).toList();
      }

      // Apply sorting
      switch (filters.sortBy) {
        case SortOption.nameAsc:
          filteredResults.sort((a, b) => a.name.compareTo(b.name));
          break;
        case SortOption.nameDesc:
          filteredResults.sort((a, b) => b.name.compareTo(a.name));
          break;
        case SortOption.dateAddedDesc:
          filteredResults.sort((a, b) {
            final dateA = a.added ?? DateTime(1970);
            final dateB = b.added ?? DateTime(1970);
            return dateB.compareTo(dateA);
          });
          break;
        case SortOption.dateUpdatedDesc:
          filteredResults.sort((a, b) {
            final dateA = a.lastUpdated ?? DateTime(1970);
            final dateB = b.lastUpdated ?? DateTime(1970);
            return dateB.compareTo(dateA);
          });
          break;
        case SortOption.relevance:
          // Keep search relevance order (default from API)
          break;
      }

      _allSearchResults = filteredResults;
      _searchCurrentPage = 0;
      _searchLoadMoreState = LoadingState.idle;
      _loadSearchResultsPage();
      _searchState = LoadingState.success;
    } catch (e) {
      _searchError = e.toString();
      _searchState = LoadingState.error;
    }
    notifyListeners();
  }

  /// Loads the current page of search results
  void _loadSearchResultsPage() {
    final startIndex = _searchCurrentPage * _searchPageSize;
    final endIndex = startIndex + _searchPageSize;

    if (startIndex >= _allSearchResults.length) {
      return;
    }

    final pageResults = _allSearchResults.sublist(
      startIndex,
      endIndex.clamp(0, _allSearchResults.length),
    );

    _searchResults.addAll(pageResults);
  }

  /// Loads more search results when scrolling
  Future<void> loadMoreSearchResults() async {
    if (_searchLoadMoreState == LoadingState.loading) {
      return;
    }

    final nextStartIndex = (_searchCurrentPage + 1) * _searchPageSize;
    if (nextStartIndex >= _allSearchResults.length) {
      return;
    }

    _searchLoadMoreState = LoadingState.loading;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 300));

      _searchCurrentPage++;
      _loadSearchResultsPage();
      _searchLoadMoreState = LoadingState.idle;
    } catch (e) {
      _searchLoadMoreState = LoadingState.error;
    }
    notifyListeners();
  }

  /// Clears search results
  void clearSearch() {
    _searchResults = [];
    _allSearchResults = [];
    _searchQuery = '';
    _searchState = LoadingState.idle;
    _searchLoadMoreState = LoadingState.idle;
    _searchError = null;
    _searchCurrentPage = 0;
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

      // Clean up preferences for uninstalled apps
      final installedPackages = _installedApps
          .map((app) => app.packageName)
          .toSet();
      await _preferencesService.cleanupUninstalledApps(installedPackages);

      _installedAppsState = LoadingState.success;
    } catch (e) {
      debugPrint('Error fetching installed apps: $e');
      _installedAppsState = LoadingState.error;
    }
    notifyListeners();
  }

  /// Gets apps that have updates available
  Future<List<FDroidApp>> getUpdatableApps() async {
    if (_repository == null || _installedApps.isEmpty) {
      return [];
    }

    final updatableApps = <FDroidApp>[];

    for (final installedApp in _installedApps) {
      // Check if the app exists in F-Droid repository
      final fdroidApp = _repository!.apps[installedApp.packageName];
      if (fdroidApp == null) continue;

      // Get the latest version based on per-app unstable preference
      final includeUnstable = await _preferencesService.getIncludeUnstable(
        installedApp.packageName,
      );
      final latestVersion = fdroidApp.getLatestVersion(
        includeUnstable: includeUnstable,
      );

      // Check if F-Droid app has a latest version
      if (latestVersion == null) continue;

      // Check if installed app has version info
      if (installedApp.versionCode == null) continue;

      // Compare version codes - if F-Droid has a newer version, it's updatable
      if (latestVersion.versionCode > installedApp.versionCode!) {
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

  /// Gets the latest version for an app based on per-app unstable preference
  Future<FDroidVersion?> getLatestVersion(FDroidApp app) async {
    final includeUnstable = await _preferencesService.getIncludeUnstable(
      app.packageName,
    );
    return _selectBestVersionForDevice(app, includeUnstable: includeUnstable);
  }

  /// Gets whether unstable versions should be included for a specific app
  Future<bool> getIncludeUnstable(String packageName) async {
    return await _preferencesService.getIncludeUnstable(packageName);
  }

  /// Sets whether unstable versions should be included for a specific app
  /// This should only be called for installed apps
  Future<void> setIncludeUnstable(String packageName, bool include) async {
    await _preferencesService.setIncludeUnstable(packageName, include);
    notifyListeners();
  }

  Future<List<String>> _getSupportedAbis() async {
    if (_supportedAbis != null) return _supportedAbis!;

    if (!Platform.isAndroid) {
      _supportedAbis = const [];
      return _supportedAbis!;
    }

    try {
      final info = await DeviceInfoPlugin().androidInfo;
      final rawAbis =
          info.supportedAbis ??
          info.supported64BitAbis ??
          info.supported32BitAbis ??
          const <String>[];
      final abis = rawAbis.where((abi) => abi.isNotEmpty).toList();
      if (abis.isNotEmpty) {
        _supportedAbis = abis;
        return abis;
      }
    } catch (e) {
      debugPrint('[AppProvider] Failed to read supported ABIs: $e');
    }

    _supportedAbis = const [];
    return _supportedAbis!;
  }

  Future<List<String>> getSupportedAbis() => _getSupportedAbis();

  Future<FDroidVersion?> _selectBestVersionForDevice(
    FDroidApp app, {
    required bool includeUnstable,
  }) async {
    if (app.packages == null || app.packages!.isEmpty) return null;

    var versions = app.packages!.values.toList();
    if (!includeUnstable) {
      versions = versions.where((v) => !v.isUnstable).toList();
      if (versions.isEmpty) return null;
    }

    final abis = await _getSupportedAbis();

    bool isUniversal(FDroidVersion v) =>
        v.nativecode == null || v.nativecode!.isEmpty;

    bool supportsDevice(FDroidVersion v) {
      if (isUniversal(v)) return true;
      if (abis.isEmpty) return true;
      return v.nativecode!.any((abi) => abis.contains(abi));
    }

    final compatible = versions.where(supportsDevice).toList();
    final candidates = compatible.isNotEmpty ? compatible : versions;

    int abiRank(FDroidVersion v) {
      if (isUniversal(v)) return abis.length + 1;
      final matches = v.nativecode!
          .map((abi) => abis.indexOf(abi))
          .where((idx) => idx >= 0)
          .toList();
      return matches.isEmpty
          ? abis.length + 2
          : matches.reduce((a, b) => a < b ? a : b);
    }

    candidates.sort((a, b) {
      final versionCompare = b.versionCode.compareTo(a.versionCode);
      if (versionCompare != 0) return versionCompare;
      if (abis.isEmpty) return 0;
      return abiRank(a).compareTo(abiRank(b));
    });

    final chosen = candidates.first;
    if (kDebugMode) {
      final native = chosen.nativecode?.join(',') ?? 'universal';
      final signature =
          '${chosen.versionCode}|${chosen.versionName}|${chosen.apkName}|$native|${abis.join(',')}';
      if (_lastAbiSelectionLogByPackage[app.packageName] != signature) {
        _lastAbiSelectionLogByPackage[app.packageName] = signature;
        debugPrint(
          '[AppProvider] ABI selection for ${app.packageName}: chosen ${chosen.versionName} (${chosen.apkName}), deviceAbis=$abis, native=${chosen.nativecode}',
        );
      }
    }
    return chosen;
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

  /// Polls until an app shows up as installed or timeout is reached.
  Future<bool> waitForInstalled(
    String packageName, {
    Duration timeout = const Duration(seconds: 20),
    Duration interval = const Duration(milliseconds: 800),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await fetchInstalledApps();
      if (isAppInstalled(packageName)) {
        return true;
      }
      await Future.delayed(interval);
    }
    return isAppInstalled(packageName);
  }

  /// Refreshes all data
  Future<void> refreshAll({
    RepositoriesProvider? repositoriesProvider,
    bool forceRepositoryRefresh = false,
  }) async {
    // Re-resolve locale at refresh time so system-language changes are honored
    // even when SettingsProvider is set to `system` and hasn't emitted a change.
    final settings = _settingsProvider;
    if (settings != null) {
      _apiService.setLocale(settings.effectiveLocale);
    }

    // Clear cached data
    _repository = null;
    _repositoryState = LoadingState.idle;
    _repositoryError = null;
    _categoryApps.clear();
    _topApps = [];
    _topAppsDownloads = {};

    // If we have enabled repositories, fetch from all of them
    if (repositoriesProvider != null) {
      if (repositoriesProvider.repositories.isEmpty &&
          !repositoriesProvider.isLoading) {
        await repositoriesProvider.loadRepositories();
      }

      final enabledRepos = repositoriesProvider.enabledRepositories;
      if (enabledRepos.isNotEmpty) {
        debugPrint('🔄 Refreshing ${enabledRepos.length} enabled repositories');
        final urls = enabledRepos.map((r) => r.url).toList();

        // Fetch from all enabled repositories
        await fetchRepositoriesFromUrls(urls);
      } else {
        // No custom repos, fetch default
        if (forceRepositoryRefresh) {
          _repositoryState = LoadingState.loading;
          notifyListeners();
          _repository = await _apiService.refreshRepository();
          _repositoryState = LoadingState.success;
          notifyListeners();
        } else {
          await fetchRepository();
        }
      }
    } else {
      // No repository provider, fetch default
      if (forceRepositoryRefresh) {
        _repositoryState = LoadingState.loading;
        notifyListeners();
        _repository = await _apiService.refreshRepository();
        _repositoryState = LoadingState.success;
        notifyListeners();
      } else {
        await fetchRepository();
      }
    }

    // Must reload repositories provider FIRST to ensure it's up-to-date
    // before fetchTopApps tries to find IzzyOnDroid
    if (repositoriesProvider != null) {
      debugPrint('📚 Reloading repositories provider...');
      await repositoriesProvider.loadRepositories();
      debugPrint(
        '📚 Repositories reloaded: ${repositoriesProvider.repositories.length} total',
      );
    }

    // NOW reload other data - topApps can safely lookup repositories now
    debugPrint(
      '🔄 Refreshing app data (latest, recently updated, top apps, categories, installed)',
    );
    await Future.wait([
      fetchLatestApps(repositoriesProvider: repositoriesProvider),
      fetchRecentlyUpdatedApps(repositoriesProvider: repositoriesProvider),
      fetchTopApps(repositoriesProvider: repositoriesProvider),
      fetchCategories(),
      fetchInstalledApps(),
    ]);
    debugPrint('✅ All app data refreshed');
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
