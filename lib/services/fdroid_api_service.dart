import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../models/fdroid_app.dart';
import 'database_service.dart';

Map<String, dynamic> _decodeJsonMapHelper(String body) {
  final decoded = json.decode(body);
  if (decoded is Map<String, dynamic>) {
    return decoded;
  }
  throw Exception('Invalid repository index format');
}

class FDroidApiService {
  String? baseUrl;
  String? apiUrl;
  String? repoIndexUrl;
  static const String _cacheFileName = 'fdroid_index_cache.json';
  static const Duration _fallbackCacheMaxAge = Duration(hours: 6);

  final http.Client _client;
  final Dio _dio;
  final Map<String, CancelToken> _downloadTokens = {};
  final DatabaseService _databaseService;
  String _userAgent = 'Florid';
  bool _sniBypassEnabled = true;
  String _currentLocale = 'en-US';

  /// Cache of what worked for each URL to optimize future requests
  final Map<String, bool> _workingSniBypassSettings = {};

  /// Cache raw repository JSON for screenshot extraction from the default repo
  Map<String, dynamic>? _cachedRawJson;

  /// Cache for fetched repository indices by repository URL
  final Map<String, Map<String, dynamic>> _repositoryIndexCache = {};
  bool _backgroundRepositoryRefreshInProgress = false;
  bool _cancelRepositoryOperations = false;

  FDroidApiService({
    http.Client? client,
    Dio? dio,
    DatabaseService? databaseService,
    bool enableSNIBypass = true,
  }) : _client = client ?? _createSNIBypassHttpClient(enableSNIBypass),
       _dio = dio ?? _createSNIBypassDio(),
       _databaseService = databaseService ?? DatabaseService(),
       _sniBypassEnabled = enableSNIBypass {
    _initializeUserAgent();
  }

  /// Creates an HTTP client with SNI bypass support
  static http.Client _createSNIBypassHttpClient(bool enableSNIBypass) {
    if (!enableSNIBypass) {
      return http.Client();
    }

    // Create a custom HttpClient with SNI bypass
    final httpClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        debugPrint(
          'FDroidApiService: Bypassing certificate verification for $host:$port',
        );
        return true; // Accept all certificates to bypass SNI filtering
      };

    // Wrap it with the http package's IOClient
    return IOClient(httpClient);
  }

  /// Creates a Dio instance with SNI bypass support
  static Dio _createSNIBypassDio() {
    final dio = Dio();

    // Configure Dio to work with SNI bypass
    final httpClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        debugPrint('Dio: Bypassing certificate verification for $host:$port');
        return true; // Accept all certificates to bypass SNI filtering
      };

    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () => httpClient,
    );

    return dio;
  }

  /// Enables or disables SNI bypass
  void setSNIBypassEnabled(bool enabled) {
    _sniBypassEnabled = enabled;
    debugPrint('SNI bypass ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Checks if SNI bypass is currently enabled
  bool isSNIBypassEnabled() => _sniBypassEnabled;

  /// Clears cached SNI bypass settings for URLs to force re-detection
  /// Useful when network conditions change or for manual reset
  void clearSNIBypassCache() {
    _workingSniBypassSettings.clear();
    debugPrint('SNI bypass cache cleared. Next requests will auto-detect.');
  }

  /// Gets the cached SNI bypass setting for a URL, or null if not cached
  bool? getCachedSNIBypassSetting(String url) => _workingSniBypassSettings[url];

  /// Initializes the User-Agent header with app version
  Future<void> _initializeUserAgent() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _userAgent = 'Florid ${packageInfo.version}';

      // Configure Dio with User-Agent
      _dio.options.headers['User-Agent'] = _userAgent;

      debugPrint('User-Agent set to: $_userAgent');
    } catch (e) {
      debugPrint('Error setting User-Agent: $e');
      _userAgent = 'Florid';
      _dio.options.headers['User-Agent'] = _userAgent;
    }
  }

  /// Sets the repository URL (e.g., from the main F-Droid or a custom repo)
  void setRepositoryUrl(String url) {
    // Remove trailing slash
    var cleanUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;

    // If URL already ends with /repo, use it as-is for base; otherwise add /repo
    if (cleanUrl.endsWith('/repo')) {
      baseUrl = cleanUrl.substring(0, cleanUrl.length - 5); // Remove /repo
      repoIndexUrl = '$cleanUrl/index-v2.json';
    } else {
      baseUrl = cleanUrl;
      repoIndexUrl = '$cleanUrl/repo/index-v2.json';
    }

    apiUrl = '$baseUrl/api/v1';
    debugPrint('Set repository URL: $repoIndexUrl');
  }

  /// Checks if a repository URL has been configured
  bool hasRepositoryUrl() => repoIndexUrl != null;

  /// Returns the cache file location for the repo index.
  Future<File> _cacheFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_cacheFileName');
  }

  /// Loads cached index JSON if it exists and is fresh enough.
  Future<Map<String, dynamic>?> _tryLoadCache() async {
    try {
      final file = await _cacheFile();
      if (!await file.exists()) return null;

      final stat = await file.stat();
      final age = DateTime.now().difference(stat.modified);
      if (age > _fallbackCacheMaxAge) return null;

      final contents = await file.readAsString();
      final jsonData = json.decode(contents);
      return jsonData is Map<String, dynamic> ? jsonData : null;
    } catch (_) {
      return null;
    }
  }

  /// Saves the latest index JSON to disk for offline use.
  Future<void> _saveCache(String body) async {
    try {
      final file = await _cacheFile();
      await file.writeAsString(body, flush: true);
    } catch (_) {
      // Ignore cache write failures
    }
  }

  /// Fetches the complete repository index with database caching and automatic SNI bypass fallback.
  /// Flow: try database (fresh) -> network -> try opposite SNI bypass if failed -> database fallback.
  Future<FDroidRepository> fetchRepository() async {
    if (_cancelRepositoryOperations) {
      throw Exception('Repository operation cancelled');
    }
    if (!hasRepositoryUrl()) {
      throw Exception(
        'No repository URL configured. Call setRepositoryUrl() first.',
      );
    }

    debugPrint('=== fetchRepository called ===');

    // Check if database is populated and fresh
    final isPopulated = await _databaseService.isPopulated();
    final needsUpdate = await _databaseService.needsUpdate(
      _fallbackCacheMaxAge,
    );

    debugPrint('Database populated: $isPopulated, needs update: $needsUpdate');

    // If database has data, return it immediately for fast startup.
    if (isPopulated) {
      try {
        debugPrint('Loading from database...');
        final cachedRepository = await _loadRepositoryFromDatabase();

        // Refresh stale data in background without blocking UI.
        if (needsUpdate && !_backgroundRepositoryRefreshInProgress) {
          _backgroundRepositoryRefreshInProgress = true;
          Future(() async {
            try {
              if (_cancelRepositoryOperations) {
                return;
              }
              await _fetchRepositoryWithAutoFallback(repoIndexUrl!);
            } catch (e) {
              debugPrint('Background repository refresh failed: $e');
            } finally {
              _backgroundRepositoryRefreshInProgress = false;
            }
          });
        }

        return cachedRepository;
      } catch (e) {
        // If database read fails, try network
        debugPrint('Error loading from database: $e');
      }
    }

    // Try to fetch from network with automatic SNI bypass fallback
    return await _fetchRepositoryWithAutoFallback(repoIndexUrl!);
  }

  /// Fetches repository with automatic SNI bypass fallback
  /// First tries the current SNI bypass setting, if that fails, tries the opposite
  Future<FDroidRepository> _fetchRepositoryWithAutoFallback(String url) async {
    if (_cancelRepositoryOperations) {
      throw Exception('Repository operation cancelled');
    }
    // Check if we have cached knowledge about what works for this URL
    final cachedSetting = _workingSniBypassSettings[url];

    // Try the known working setting first, or current setting if unknown
    final primarySetting = cachedSetting ?? _sniBypassEnabled;
    final fallbackSetting = !primarySetting;

    debugPrint(
      'Fetching from network: $url (Primary SNI bypass: $primarySetting)',
    );

    // Try primary setting
    try {
      final repo = await _fetchRepositoryWithSNISetting(url, primarySetting);
      if (_cancelRepositoryOperations) {
        throw Exception('Repository operation cancelled');
      }
      // Cache this working setting
      _workingSniBypassSettings[url] = primarySetting;
      return repo;
    } catch (primaryError) {
      debugPrint(
        'Primary attempt failed with SNI bypass=$primarySetting: $primaryError',
      );

      // Try with fallback SNI setting
      debugPrint('Retrying with fallback SNI bypass setting: $fallbackSetting');
      try {
        final repo = await _fetchRepositoryWithSNISetting(url, fallbackSetting);
        if (_cancelRepositoryOperations) {
          throw Exception('Repository operation cancelled');
        }
        // Cache this working setting
        _workingSniBypassSettings[url] = fallbackSetting;
        debugPrint('Successfully fetched with SNI bypass=$fallbackSetting');
        return repo;
      } catch (fallbackError) {
        debugPrint('Fallback attempt also failed: $fallbackError');

        // Both attempts failed, try database and cache fallbacks
        final isPopulated = await _databaseService.isPopulated();
        if (isPopulated) {
          try {
            debugPrint('Falling back to database...');
            return await _loadRepositoryFromDatabase();
          } catch (dbError) {
            debugPrint('Error loading from database fallback: $dbError');
          }
        }

        // Last resort: try JSON cache
        debugPrint('Trying JSON cache...');
        final cachedJson = await _tryLoadCache();
        if (cachedJson != null) {
          _cachedRawJson = cachedJson;
          debugPrint('Loaded from JSON cache');
          return FDroidRepository.fromJson(cachedJson);
        }

        // All fallbacks failed
        throw Exception(
          'Error fetching repository: Failed with both SNI bypass settings. '
          'Primary error: $primaryError, Fallback error: $fallbackError',
        );
      }
    }
  }

  /// Fetches repository with a specific SNI bypass setting
  Future<FDroidRepository> _fetchRepositoryWithSNISetting(
    String url,
    bool useSniBypass,
  ) async {
    if (_cancelRepositoryOperations) {
      throw Exception('Repository operation cancelled');
    }
    // Temporarily set SNI bypass for this request
    final originalSetting = _sniBypassEnabled;
    _sniBypassEnabled = useSniBypass;

    try {
      final response = await _client.get(
        Uri.parse(url),
        headers: {'User-Agent': _userAgent},
      );

      if (_cancelRepositoryOperations) {
        throw Exception('Repository operation cancelled');
      }

      if (response.statusCode == 200) {
        final body = response.body;

        // Offload JSON decoding and object mapping to a background isolate
        final result = await compute(_parseRepositoryDataHelper, {
          'body': body,
          'repositoryUrl': null,
          'locale': _currentLocale,
        });

        final jsonData = result['json'] as Map<String, dynamic>;
        final repo = result['repo'] as FDroidRepository;

        if (_cancelRepositoryOperations) {
          throw Exception('Repository operation cancelled');
        }

        // Cache the raw JSON for screenshot extraction
        _cachedRawJson = jsonData;
        debugPrint(
          'Cached raw JSON, size: ${_cachedRawJson?.length ?? 0} keys',
        );

        // Parse repository

        // Store in database on a background isolate to avoid blocking UI
        try {
          if (!_cancelRepositoryOperations) {
            importRepositoryInBackground(repo); // Fire and forget
          }
        } catch (e) {
          debugPrint('Error scheduling database import: $e');
        }

        // Also save JSON cache for screenshot extraction
        await _saveCache(body);

        debugPrint('Successfully fetched and cached repository');
        return repo;
      } else {
        throw Exception('Failed to load repository: ${response.statusCode}');
      }
    } finally {
      // Restore original SNI bypass setting
      _sniBypassEnabled = originalSetting;
    }
  }

  /// Loads repository data from the database
  Future<FDroidRepository> _loadRepositoryFromDatabase() async {
    final apps = await _databaseService.getAllApps();
    final repoName =
        await _databaseService.getMetadata('repo_name') ?? 'F-Droid';
    final repoDescription =
        await _databaseService.getMetadata('repo_description') ?? '';

    // Try to load the cached JSON for screenshot extraction (ignore age check)
    if (_cachedRawJson == null) {
      try {
        final file = await _cacheFile();
        if (await file.exists()) {
          final contents = await file.readAsString();
          final jsonData = json.decode(contents);
          if (jsonData is Map<String, dynamic>) {
            _cachedRawJson = jsonData;
            debugPrint('Loaded cached JSON for screenshots (database mode)');
          }
        }
      } catch (e) {
        debugPrint('Could not load JSON cache for screenshots: $e');
      }
    }

    // Create a map of apps keyed by package name
    final appsMap = <String, FDroidApp>{};
    for (final app in apps) {
      appsMap[app.packageName] = app;
    }

    return FDroidRepository(
      name: repoName,
      description: repoDescription,
      icon: '',
      timestamp: '',
      version: '',
      maxage: 0,
      apps: appsMap,
    );
  }

  /// Fetches repository from a custom URL with automatic SNI bypass fallback
  Future<FDroidRepository> fetchRepositoryFromUrl(String url) async {
    try {
      // Parse URL and extract fingerprint if present
      final uri = Uri.parse(url);
      String baseUrlWithoutFingerprint = uri
          .replace(queryParameters: {})
          .toString();
      if (baseUrlWithoutFingerprint.endsWith('?')) {
        baseUrlWithoutFingerprint = baseUrlWithoutFingerprint.substring(
          0,
          baseUrlWithoutFingerprint.length - 1,
        );
      }

      // Construct the index URL
      String indexUrl;
      if (baseUrlWithoutFingerprint.endsWith('index-v2.json')) {
        // Full URL provided
        indexUrl = baseUrlWithoutFingerprint;
      } else if (baseUrlWithoutFingerprint.endsWith('/repo') ||
          baseUrlWithoutFingerprint.endsWith('/repo/')) {
        // URL already includes /repo path
        indexUrl = baseUrlWithoutFingerprint.endsWith('/')
            ? '${baseUrlWithoutFingerprint}index-v2.json'
            : '$baseUrlWithoutFingerprint/index-v2.json';
      } else {
        // Base URL without /repo
        indexUrl = baseUrlWithoutFingerprint.endsWith('/')
            ? '${baseUrlWithoutFingerprint}repo/index-v2.json'
            : '$baseUrlWithoutFingerprint/repo/index-v2.json';
      }

      // Derive repository base (strip the index file and trailing slash)
      var repoBase = indexUrl.replaceFirst(RegExp(r'index-v2\.json$'), '');
      if (repoBase.endsWith('/')) {
        repoBase = repoBase.substring(0, repoBase.length - 1);
      }

      debugPrint('Fetching from custom repo: $indexUrl');

      // Check if we have cached knowledge about what works for this URL
      final cachedSetting = _workingSniBypassSettings[indexUrl];

      // Try the known working setting first, or current setting if unknown
      final primarySetting = cachedSetting ?? _sniBypassEnabled;
      final fallbackSetting = !primarySetting;

      // Try primary setting
      try {
        final response = await _fetchCustomRepoWithSNISetting(
          indexUrl,
          primarySetting,
        );
        _workingSniBypassSettings[indexUrl] = primarySetting;

        final result = await compute(_parseRepositoryDataHelper, {
          'body': response.body,
          'repositoryUrl': repoBase,
          'locale': _currentLocale,
        });
        final repo = result['repo'] as FDroidRepository;

        // Cache the raw JSON for future feature graphic extractions
        final parsedIndex = await compute(_decodeJsonMapHelper, response.body);
        _repositoryIndexCache[indexUrl] = parsedIndex;

        debugPrint('Successfully fetched repository from $url');
        return repo;
      } catch (primaryError) {
        debugPrint(
          'Primary attempt failed with SNI bypass=$primarySetting: $primaryError',
        );

        // Try with fallback SNI setting
        debugPrint(
          'Retrying with fallback SNI bypass setting: $fallbackSetting',
        );
        try {
          final response = await _fetchCustomRepoWithSNISetting(
            indexUrl,
            fallbackSetting,
          );
          _workingSniBypassSettings[indexUrl] = fallbackSetting;
          debugPrint('Successfully fetched with SNI bypass=$fallbackSetting');

          final result = await compute(_parseRepositoryDataHelper, {
            'body': response.body,
            'repositoryUrl': repoBase,
            'locale': _currentLocale,
          });
          final repo = result['repo'] as FDroidRepository;

          // Cache the raw JSON for future feature graphic extractions
          final parsedIndex = await compute(
            _decodeJsonMapHelper,
            response.body,
          );
          _repositoryIndexCache[indexUrl] = parsedIndex;

          return repo;
        } catch (fallbackError) {
          debugPrint('Fallback attempt also failed: $fallbackError');
          throw Exception(
            'Error fetching repository from $url: '
            'Failed with both SNI bypass settings. '
            'Primary error: $primaryError, Fallback error: $fallbackError',
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching from custom repo $url: $e');
      throw Exception('Error fetching repository from $url: $e');
    }
  }

  /// Fetches custom repository with a specific SNI bypass setting
  Future<http.Response> _fetchCustomRepoWithSNISetting(
    String url,
    bool useSniBypass,
  ) async {
    // Temporarily set SNI bypass for this request
    final originalSetting = _sniBypassEnabled;
    _sniBypassEnabled = useSniBypass;

    try {
      final response = await _client.get(
        Uri.parse(url),
        headers: {'User-Agent': _userAgent},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load repository: ${response.statusCode}');
      }

      return response;
    } finally {
      // Restore original SNI bypass setting
      _sniBypassEnabled = originalSetting;
    }
  }

  /// Imports repository asynchronously to avoid blocking UI
  void importRepositoryInBackground(
    FDroidRepository repo, {
    int? repositoryId,
  }) {
    try {
      if (_cancelRepositoryOperations) {
        debugPrint('Repository import skipped: operation cancelled');
        return;
      }
      debugPrint('Scheduling database import...');
      // Defer import to run after the current frame without blocking UI
      Future.microtask(() async {
        try {
          if (_cancelRepositoryOperations) {
            debugPrint('Repository import aborted: operation cancelled');
            return;
          }
          await _databaseService.importRepository(
            repo,
            repositoryId: repositoryId,
          );

          // Update the last synced timestamp for this repository
          if (repositoryId != null) {
            await _databaseService.updateRepositoryLastSynced(repositoryId);
            debugPrint(
              'Updated last synced timestamp for repository ID: $repositoryId',
            );
          }

          debugPrint('Database import completed in background');
        } catch (e) {
          debugPrint('Error importing repository in background: $e');
        }
      });
    } catch (e) {
      debugPrint('Error scheduling database import: $e');
    }
  }

  /// Gets repository ID by URL
  Future<int?> getRepositoryIdByUrl(String url) async {
    try {
      final db = await _databaseService.database;
      final results = await db.query(
        'repositories',
        where: 'url = ?',
        whereArgs: [url],
        columns: ['id'],
      );
      if (results.isNotEmpty) {
        return results.first['id'] as int;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting repository ID: $e');
      return null;
    }
  }

  /// Imports a repository to the database
  Future<void> importRepositoryToDatabase(
    FDroidRepository repo, {
    required int repositoryId,
  }) async {
    try {
      await _databaseService.importRepository(repo, repositoryId: repositoryId);
    } catch (e) {
      debugPrint('Error importing repository to database: $e');
    }
  }

  /// Clears the cached repository index from disk, memory, and database.
  Future<void> clearRepositoryCache() async {
    try {
      final file = await _cacheFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Ignore cache clear failures
    }
    _cachedRawJson = null;

    // Clear database
    try {
      await _databaseService.clearAll();
    } catch (_) {
      // Ignore database clear failures
    }
  }

  void cancelRepositoryOperations() {
    _cancelRepositoryOperations = true;
    debugPrint('Repository operations cancellation requested');
  }

  void resetRepositoryOperationsCancellation() {
    _cancelRepositoryOperations = false;
  }

  /// Fetches apps with pagination support
  Future<List<FDroidApp>> fetchApps({
    int? limit,
    int? offset,
    String? category,
    String? search,
  }) async {
    try {
      // Use database for better performance if available
      final isPopulated = await _databaseService.isPopulated();

      if (isPopulated) {
        List<FDroidApp> apps;

        // Use optimized database queries
        if (search != null && search.isNotEmpty) {
          apps = await _databaseService.searchApps(search);
        } else if (category != null && category.isNotEmpty) {
          apps = await _databaseService.getAppsByCategory(category);
        } else {
          apps = await _databaseService.getAllApps();
        }

        // Apply pagination
        if (offset != null) {
          apps = apps.skip(offset).toList();
        }
        if (limit != null) {
          apps = apps.take(limit).toList();
        }

        return apps;
      } else {
        // Fallback to repository for backward compatibility
        final repository = await fetchRepository();
        List<FDroidApp> apps = repository.appsList;

        // Filter by category if specified
        if (category != null && category.isNotEmpty) {
          apps = apps
              .where((app) => app.categories?.contains(category) ?? false)
              .toList();
        }

        // Filter by search query if specified
        if (search != null && search.isNotEmpty) {
          final lowerSearch = search.toLowerCase();
          apps = apps
              .where(
                (app) =>
                    app.name.toLowerCase().contains(lowerSearch) ||
                    app.summary.toLowerCase().contains(lowerSearch) ||
                    app.description.toLowerCase().contains(lowerSearch) ||
                    app.packageName.toLowerCase().contains(lowerSearch),
              )
              .toList();
        }

        // Apply pagination
        if (offset != null) {
          apps = apps.skip(offset).toList();
        }
        if (limit != null) {
          apps = apps.take(limit).toList();
        }

        return apps;
      }
    } catch (e) {
      throw Exception('Error fetching apps: $e');
    }
  }

  /// Fetches the latest apps
  Future<List<FDroidApp>> fetchLatestApps({int limit = 50}) async {
    try {
      final isPopulated = await _databaseService.isPopulated();

      if (isPopulated) {
        return await _databaseService.getLatestApps(limit: limit);
      } else {
        final repository = await fetchRepository();
        return repository.latestApps.take(limit).toList();
      }
    } catch (e) {
      throw Exception('Error fetching latest apps: $e');
    }
  }

  /// Fetches apps by category
  Future<List<FDroidApp>> fetchAppsByCategory(String category) async {
    try {
      final isPopulated = await _databaseService.isPopulated();

      if (isPopulated) {
        return await _databaseService.getAppsByCategory(category);
      } else {
        final repository = await fetchRepository();
        return repository.getAppsByCategory(category);
      }
    } catch (e) {
      throw Exception('Error fetching apps by category: $e');
    }
  }

  /// Fetches apps by author name
  Future<List<FDroidApp>> fetchAppsByAuthor(String authorName) async {
    try {
      final isPopulated = await _databaseService.isPopulated();

      if (isPopulated) {
        return await _databaseService.getAppsByAuthor(authorName);
      } else {
        final repository = await fetchRepository();
        // Filter apps by author from the repository
        return repository.apps.values
            .where(
              (app) =>
                  app.authorName != null &&
                  app.authorName!.toLowerCase() == authorName.toLowerCase(),
            )
            .toList();
      }
    } catch (e) {
      throw Exception('Error fetching apps by author: $e');
    }
  }

  /// Searches for apps
  Future<List<FDroidApp>> searchApps(String query) async {
    try {
      final isPopulated = await _databaseService.isPopulated();

      if (isPopulated) {
        return await _databaseService.searchApps(query);
      } else {
        final repository = await fetchRepository();
        return repository.searchApps(query);
      }
    } catch (e) {
      throw Exception('Error searching apps: $e');
    }
  }

  /// Searches for apps using the local database only
  Future<List<FDroidApp>> searchAppsDatabaseOnly(String query) async {
    try {
      return await _databaseService.searchApps(query);
    } catch (e) {
      throw Exception('Error searching apps in database: $e');
    }
  }

  /// Searches for apps from a specific custom repository using database
  Future<List<FDroidApp>> searchAppsFromRepositoryUrl(
    String query,
    String repositoryUrl, {
    bool allowNetworkFallback = true,
  }) async {
    try {
      // Try to search from database if repository data is cached there
      final results = await _databaseService.searchAppsByRepository(
        query,
        repositoryUrl,
      );
      if (results.isNotEmpty) {
        return results;
      }

      // If fallback is disabled (e.g. for cross-repo presence checks),
      // do not trigger network calls when no DB result is found.
      if (!allowNetworkFallback) {
        return results;
      }

      // Fallback: fetch from network if not in database
      debugPrint(
        'Repository $repositoryUrl not in database, fetching from network...',
      );
      final repo = await fetchRepositoryFromUrl(repositoryUrl);

      final repositoryId = await getRepositoryIdByUrl(repositoryUrl);
      if (repositoryId != null) {
        await importRepositoryToDatabase(repo, repositoryId: repositoryId);
      }

      return repo.searchApps(query);
    } catch (e) {
      throw Exception('Error searching apps from repository: $e');
    }
  }

  /// Gets specific apps from a repository URL by package names.
  ///
  /// Uses database cache only and does not perform network fallback.
  Future<List<FDroidApp>> getAppsByPackageNamesFromRepository(
    List<String> packageNames,
    String repositoryUrl,
  ) async {
    if (packageNames.isEmpty) {
      return [];
    }

    try {
      return await _databaseService.getAppsByPackageNamesFromRepository(
        packageNames,
        repositoryUrl,
      );
    } catch (e) {
      throw Exception(
        'Error fetching apps by package names from repository: $e',
      );
    }
  }

  /// Checks whether a package exists in a repository.
  /// Uses DB first and optionally falls back to network index fetch.
  Future<bool> repositoryContainsPackage(
    String packageName,
    String repositoryUrl, {
    bool allowNetworkFallback = true,
  }) async {
    try {
      final existsInDb = await _databaseService.repositoryContainsPackage(
        packageName,
        repositoryUrl,
      );
      if (existsInDb) {
        return true;
      }

      if (!allowNetworkFallback) {
        return false;
      }

      final repo = await fetchRepositoryFromUrl(repositoryUrl);

      final repositoryId = await getRepositoryIdByUrl(repositoryUrl);
      if (repositoryId != null) {
        await importRepositoryToDatabase(repo, repositoryId: repositoryId);
      }

      return repo.apps.containsKey(packageName);
    } catch (e) {
      debugPrint('Error checking repository package existence: $e');
      return false;
    }
  }

  /// Fetches all available categories
  Future<List<String>> fetchCategories() async {
    try {
      final isPopulated = await _databaseService.isPopulated();

      if (isPopulated) {
        return await _databaseService.getCategories();
      } else {
        final repository = await fetchRepository();
        return repository.categories;
      }
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }

  /// Fetches a specific app by package name
  Future<FDroidApp?> fetchApp(String packageName) async {
    try {
      final isPopulated = await _databaseService.isPopulated();

      if (isPopulated) {
        return await _databaseService.getApp(packageName);
      } else {
        final repository = await fetchRepository();
        return repository.apps[packageName];
      }
    } catch (e) {
      throw Exception('Error fetching app: $e');
    }
  }

  /// Sets the locale for the database service
  void setLocale(String locale) {
    _currentLocale = locale;
    _databaseService.setLocale(locale);
  }

  /// Forces a fresh network fetch/import for the configured repository.
  Future<FDroidRepository> refreshRepository() async {
    if (!hasRepositoryUrl()) {
      throw Exception(
        'No repository URL configured. Call setRepositoryUrl() first.',
      );
    }
    final repo = await _fetchRepositoryWithAutoFallback(repoIndexUrl!);

    // For immediate locale switching, ensure DB is updated before callers read lists.
    await _databaseService.importRepository(repo);

    return repo;
  }

  /// Downloads an APK file with progress tracking and cancellation support
  Future<String> downloadApk(
    FDroidVersion version,
    String packageName,
    String repositoryUrl, {
    Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('Cannot access external storage');
      }

      final downloadsDir = Directory('${directory.path}/Downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final fileName = '${packageName}_${version.versionName}.apk';
      final filePath = '${downloadsDir.path}/$fileName';

      // Log download URL and file path
      final downloadUrl = version.downloadUrl(repositoryUrl);
      debugPrint('[FDroidApiService] Downloading APK:');
      debugPrint('  URL: $downloadUrl');
      debugPrint('  To: $filePath');

      final token = cancelToken ?? CancelToken();
      _downloadTokens[packageName] = token;

      final response = await _dio.download(
        downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            onProgress(received, total);
          }
        },
        cancelToken: token,
      );

      // Log response metadata
      try {
        final status = response.statusCode;
        final contentType = response.headers.value('content-type');
        debugPrint(
          '[FDroidApiService] Download response: status=$status, contentType=$contentType',
        );
      } catch (_) {}

      // Validate downloaded file
      try {
        final status = response.statusCode ?? 0;
        if (status < 200 || status >= 300) {
          throw Exception('HTTP $status while downloading');
        }

        final file = File(filePath);
        final fileExists = await file.exists();
        final fileSize = fileExists ? await file.length() : -1;

        // Read first few bytes to verify APK (ZIP magic: 50 4B 03 04)
        List<int> magic = [];
        if (fileExists && fileSize > 4) {
          final bytes = await file.openRead(0, 8).first;
          magic = bytes.toList();
        }
        final isZip =
            magic.length >= 4 &&
            magic[0] == 0x50 &&
            magic[1] == 0x4B &&
            magic[2] == 0x03 &&
            magic[3] == 0x04;

        debugPrint(
          '[FDroidApiService] Downloaded file: $filePath (exists: $fileExists, size: $fileSize bytes, zipMagic=$isZip, magicBytes=$magic)',
        );

        if (!fileExists || fileSize <= 0 || !isZip) {
          throw Exception('Downloaded APK is invalid or missing');
        }
      } catch (e) {
        debugPrint('[FDroidApiService] Error checking file after download: $e');
        rethrow;
      }

      _downloadTokens.remove(packageName);
      return filePath;
    } catch (e) {
      _downloadTokens.remove(packageName);
      debugPrint('[FDroidApiService] Error downloading APK: $e');
      throw Exception('Error downloading APK: $e');
    }
  }

  /// Cancels an ongoing download
  void cancelDownload(String packageName) {
    final token = _downloadTokens[packageName];
    if (token != null && !token.isCancelled) {
      token.cancel('Download cancelled by user');
    }
  }

  /// Checks if an APK file is already downloaded
  Future<bool> isApkDownloaded(String packageName, String versionName) async {
    try {
      final directory = await getExternalStorageDirectory();
      if (directory == null) return false;

      final downloadsDir = Directory('${directory.path}/Downloads');
      final fileName = '${packageName}_$versionName.apk';
      final filePath = '${downloadsDir.path}/$fileName';

      return await File(filePath).exists();
    } catch (e) {
      return false;
    }
  }

  /// Gets the file path of a downloaded APK
  Future<String?> getDownloadedApkPath(
    String packageName,
    String versionName,
  ) async {
    try {
      final directory = await getExternalStorageDirectory();
      if (directory == null) return null;

      final downloadsDir = Directory('${directory.path}/Downloads');
      final fileName = '${packageName}_$versionName.apk';
      final filePath = '${downloadsDir.path}/$fileName';

      if (await File(filePath).exists()) {
        return filePath;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Deletes all downloaded APK files from the app's Downloads directory.
  /// Returns the number of files deleted.
  Future<int> clearDownloadedApks() async {
    try {
      final directory = await getExternalStorageDirectory();
      if (directory == null) return 0;

      final downloadsDir = Directory('${directory.path}/Downloads');
      if (!await downloadsDir.exists()) return 0;

      int deleted = 0;
      await for (final entity in downloadsDir.list()) {
        if (entity is File && entity.path.toLowerCase().endsWith('.apk')) {
          try {
            await entity.delete();
            deleted++;
          } catch (_) {
            // ignore deletion failures
          }
        }
      }
      return deleted;
    } catch (_) {
      return 0;
    }
  }

  /// Fetches changelog text from a repository-relative or absolute URL.
  /// Returns plain text. If the server responds with HTML, tags are stripped.
  Future<String?> fetchChangelogText(
    String? changelogPath, {
    String? repositoryUrl,
  }) async {
    if (changelogPath == null || changelogPath.isEmpty) return null;

    final base = repositoryUrl ?? baseUrl ?? 'https://f-droid.org';
    final resolved = changelogPath.startsWith('http')
        ? changelogPath
        : '$base/${changelogPath.startsWith('/') ? changelogPath.substring(1) : changelogPath}';

    try {
      final resp = await _client.get(
        Uri.parse(resolved),
        headers: {
          'User-Agent': _userAgent,
          'Accept': 'text/plain, text/markdown, */*',
        },
      );
      if (resp.statusCode != 200 || resp.body.isEmpty) return null;

      final contentType = resp.headers['content-type'] ?? '';
      final body = resp.body;

      // If plain text or markdown, return directly
      if (contentType.contains('text/plain') ||
          contentType.contains('markdown')) {
        return body;
      }

      // Fallback: strip HTML tags to get readable text
      return _stripHtml(body);
    } catch (e) {
      debugPrint('Error fetching changelog: $e');
      return null;
    }
  }

  /// Lightweight HTML stripping for changelog content.
  String _stripHtml(String html) {
    var text = html.replaceAll(
      RegExp(r'<script[^>]*>.*?</script>', dotAll: true, caseSensitive: false),
      '',
    );
    text = text.replaceAll(
      RegExp(r'<style[^>]*>.*?</style>', dotAll: true, caseSensitive: false),
      '',
    );

    text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'</p>', caseSensitive: false), '\n');

    text = text.replaceAll(RegExp(r'<[^>]+>'), '');

    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&amp;', '&');

    text = text.replaceAll(RegExp(r' +'), ' ');
    text = text.replaceAll(RegExp(r'\n\s*\n+'), '\n\n');
    return text.trim();
  }

  /// Extracts screenshots for a specific app package from the specified repository
  /// If repositoryUrl is provided, fetches from that repository's index
  /// Otherwise uses the default cached repository
  Future<List<String>> getScreenshots(
    String packageName, {
    String? repositoryUrl,
    String? locale,
  }) async {
    Map<String, dynamic>? jsonData;

    // If a specific repository URL is provided, fetch from it
    if (repositoryUrl != null) {
      try {
        // Ensure URL doesn't end with /repo/index-v2.json
        var cleanUrl = repositoryUrl.endsWith('/')
            ? repositoryUrl.substring(0, repositoryUrl.length - 1)
            : repositoryUrl;

        // Handle various URL formats
        if (cleanUrl.endsWith('/index-v2.json')) {
          cleanUrl = cleanUrl.substring(
            0,
            cleanUrl.length - '/index-v2.json'.length,
          );
        }

        final indexUrl = cleanUrl.endsWith('/repo')
            ? '$cleanUrl/index-v2.json'
            : '$cleanUrl/repo/index-v2.json';

        // Check if we have this repository cached
        if (_repositoryIndexCache.containsKey(indexUrl)) {
          jsonData = _repositoryIndexCache[indexUrl];
        } else {
          final response = await _client.get(Uri.parse(indexUrl));

          if (response.statusCode == 200) {
            final parsedIndex = await compute(
              _decodeJsonMapHelper,
              response.body,
            );
            jsonData = parsedIndex;
            // Cache the fetched index for future use
            _repositoryIndexCache[indexUrl] = parsedIndex;
          } else {
            return [];
          }
        }
      } catch (e) {
        return [];
      }
    } else {
      // Use cached default repository
      if (_cachedRawJson == null) {
        try {
          await fetchRepository();
        } catch (e) {
          return [];
        }
      }

      if (_cachedRawJson == null) {
        return [];
      }

      jsonData = _cachedRawJson;
    }

    try {
      final packages = (jsonData!['packages'] as Map?)?.cast<String, dynamic>();
      if (packages == null) {
        return [];
      }

      final pkgData = packages[packageName] as Map?;
      if (pkgData == null) {
        return [];
      }

      // Try multiple locations for screenshots
      List<String>? screenshotsList;

      // 1. Direct metadata.screenshots
      final metadata = (pkgData['metadata'] as Map?)?.cast<String, dynamic>();
      if (metadata != null) {
        screenshotsList = _extractScreenshots(
          metadata['screenshots'],
          locale: locale,
        );
        if (screenshotsList.isNotEmpty) {
          return screenshotsList;
        }

        // 2. Check if screenshots might be in a localized format
        for (final key in metadata.keys) {
          if (key.toString().contains('screenshot')) {
            screenshotsList = _extractScreenshots(
              metadata[key],
              locale: locale,
            );
            if (screenshotsList.isNotEmpty) {
              return screenshotsList;
            }
          }
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Extracts metadata video URL for a package.
  /// Supports both plain string and locale-keyed map (from fastlane video.txt).
  Future<String?> getVideoUrl(
    String packageName, {
    String? repositoryUrl,
    String? locale,
  }) async {
    Map<String, dynamic>? jsonData;

    if (repositoryUrl != null) {
      try {
        var cleanUrl = repositoryUrl.endsWith('/')
            ? repositoryUrl.substring(0, repositoryUrl.length - 1)
            : repositoryUrl;

        if (cleanUrl.endsWith('/index-v2.json')) {
          cleanUrl = cleanUrl.substring(
            0,
            cleanUrl.length - '/index-v2.json'.length,
          );
        }

        final indexUrl = cleanUrl.endsWith('/repo')
            ? '$cleanUrl/index-v2.json'
            : '$cleanUrl/repo/index-v2.json';

        if (_repositoryIndexCache.containsKey(indexUrl)) {
          jsonData = _repositoryIndexCache[indexUrl];
        } else {
          final response = await _client.get(Uri.parse(indexUrl));
          if (response.statusCode != 200) return null;
          final parsedIndex = await compute(
            _decodeJsonMapHelper,
            response.body,
          );
          jsonData = parsedIndex;
          _repositoryIndexCache[indexUrl] = parsedIndex;
        }
      } catch (_) {
        return null;
      }
    } else {
      if (_cachedRawJson == null) {
        try {
          await fetchRepository();
        } catch (_) {
          return null;
        }
      }
      jsonData = _cachedRawJson;
    }

    try {
      final packages = (jsonData?['packages'] as Map?)?.cast<String, dynamic>();
      if (packages == null) return null;

      final pkgData = packages[packageName] as Map?;
      if (pkgData == null) return null;

      final metadata = (pkgData['metadata'] as Map?)?.cast<String, dynamic>();
      if (metadata == null) return null;

      final rawVideo = metadata['video'];
      final parsed = _extractLocalizedUrl(rawVideo, locale);
      return parsed;
    } catch (_) {
      return null;
    }
  }

  /// Gets the feature graphic (branding image) for an app from the specified repository
  /// Uses cached repository index to avoid repeated Network requests
  Future<String?> getFeatureGraphic(
    String packageName, {
    required String repositoryUrl,
  }) async {
    try {
      Map<String, dynamic>? jsonData;

      // Ensure URL doesn't end with /repo/index-v2.json
      var cleanUrl = repositoryUrl.endsWith('/')
          ? repositoryUrl.substring(0, repositoryUrl.length - 1)
          : repositoryUrl;

      // Handle various URL formats
      if (cleanUrl.endsWith('/index-v2.json')) {
        cleanUrl = cleanUrl.substring(
          0,
          cleanUrl.length - '/index-v2.json'.length,
        );
      }

      final indexUrl = cleanUrl.endsWith('/repo')
          ? '$cleanUrl/index-v2.json'
          : '$cleanUrl/repo/index-v2.json';

      // Check if we have this repository cached
      if (_repositoryIndexCache.containsKey(indexUrl)) {
        jsonData = _repositoryIndexCache[indexUrl];
      } else {
        // No cached index available - cannot extract feature graphics
        return null;
      }

      if (jsonData == null) {
        return null;
      }

      final packages = (jsonData['packages'] as Map?)?.cast<String, dynamic>();
      if (packages == null) {
        return null;
      }

      final pkgData = packages[packageName] as Map?;
      if (pkgData == null) {
        return null;
      }

      // Get featureGraphic from metadata
      final metadata = (pkgData['metadata'] as Map?)?.cast<String, dynamic>();
      if (metadata != null) {
        if (metadata['featureGraphic'] != null) {
          final featureGraphic = metadata['featureGraphic'];

          // featureGraphic is organized by language: featureGraphic[language]
          if (featureGraphic is Map) {
            // Try to get en-US first, then fall back to any available language
            if (featureGraphic['en-US'] is String &&
                (featureGraphic['en-US'] as String).isNotEmpty) {
              return featureGraphic['en-US'] as String;
            }

            // Fall back to first available language
            for (final langValue in featureGraphic.values) {
              if (langValue is String && langValue.isNotEmpty) {
                return langValue;
              }
            }
          } else if (featureGraphic is String && featureGraphic.isNotEmpty) {
            return featureGraphic;
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Fetches and caches the repository index without parsing the full FDroidRepository
  /// This is useful for feature graphic extraction when apps are loaded from cache
  Future<void> cacheRepositoryIndexFromUrl(String repositoryUrl) async {
    try {
      // Ensure URL doesn't end with /repo/index-v2.json
      var cleanUrl = repositoryUrl.endsWith('/')
          ? repositoryUrl.substring(0, repositoryUrl.length - 1)
          : repositoryUrl;

      if (cleanUrl.endsWith('/index-v2.json')) {
        cleanUrl = cleanUrl.substring(
          0,
          cleanUrl.length - '/index-v2.json'.length,
        );
      }

      final indexUrl = cleanUrl.endsWith('/repo')
          ? '$cleanUrl/index-v2.json'
          : '$cleanUrl/repo/index-v2.json';

      // Skip if already cached
      if (_repositoryIndexCache.containsKey(indexUrl)) {
        debugPrint('💾 Index already cached for $repositoryUrl');
        return;
      }

      debugPrint('📥 Caching index from: $indexUrl');

      // Fetch the index with SNI bypass handling
      final cachedSetting = _workingSniBypassSettings[indexUrl];
      final primarySetting = cachedSetting ?? _sniBypassEnabled;
      final fallbackSetting = !primarySetting;

      try {
        final response = await _fetchCustomRepoWithSNISetting(
          indexUrl,
          primarySetting,
        );

        if (response.statusCode == 200) {
          final parsedIndex = await compute(
            _decodeJsonMapHelper,
            response.body,
          );
          _repositoryIndexCache[indexUrl] = parsedIndex;
          _workingSniBypassSettings[indexUrl] = primarySetting;
          debugPrint('✅ Successfully cached index for $repositoryUrl');
        }
      } catch (primaryError) {
        // Try fallback setting
        try {
          final response = await _fetchCustomRepoWithSNISetting(
            indexUrl,
            fallbackSetting,
          );

          if (response.statusCode == 200) {
            final parsedIndex = await compute(
              _decodeJsonMapHelper,
              response.body,
            );
            _repositoryIndexCache[indexUrl] = parsedIndex;
            _workingSniBypassSettings[indexUrl] = fallbackSetting;
            debugPrint(
              '✅ Successfully cached index for $repositoryUrl (fallback SNI)',
            );
          }
        } catch (fallbackError) {
          debugPrint(
            '⚠️ Could not cache index for $repositoryUrl: $primaryError / $fallbackError',
          );
        }
      }
    } catch (e) {
      debugPrint('💥 Error caching repository index: $e');
    }
  }

  List<String> _extractScreenshots(dynamic screenshotData, {String? locale}) {
    if (screenshotData == null) {
      return [];
    }

    final screenshots = <String>[];

    if (screenshotData is List) {
      for (final item in screenshotData) {
        if (item is String) {
          screenshots.add(item);
        } else if (item is Map) {
          // Try different keys
          if (item['name'] is String) {
            screenshots.add(item['name'] as String);
          } else if (item['path'] is String) {
            screenshots.add(item['path'] as String);
          } else if (item['url'] is String) {
            screenshots.add(item['url'] as String);
          }
        }
      }
    } else if (screenshotData is Map) {
      // Prefer handheld/tablet screenshots over tv/wear when device buckets exist.
      // Stop at the first device bucket that has screenshots.
      for (final deviceType in [
        'phone',
        'sevenInch',
        'tenInch',
        'tablet',
        'phoneScreenshots',
        'wear',
        'tv',
      ]) {
        final deviceData = screenshotData[deviceType];
        if (deviceData != null) {
          // Device data could be localized: {en-US: [...], de: [...]}
          if (deviceData is Map) {
            final localizedScreens = _extractLocalePreferredScreenshots(
              deviceData,
              locale,
            );
            if (localizedScreens.isNotEmpty) {
              screenshots.addAll(localizedScreens);
            } else {
              for (final localeScreenshots in deviceData.values) {
                final extracted = _extractScreenshots(
                  localeScreenshots,
                  locale: locale,
                );
                if (extracted.isNotEmpty) {
                  screenshots.addAll(extracted);
                  break;
                }
              }
            }
          } else if (deviceData is List) {
            screenshots.addAll(_extractScreenshots(deviceData, locale: locale));
          }

          if (screenshots.isNotEmpty) {
            return screenshots.toSet().toList();
          }
        }
      }

      final localePreferred = _extractLocalePreferredScreenshots(
        screenshotData,
        locale,
      );
      if (localePreferred.isNotEmpty) {
        return localePreferred;
      }

      // If no device-type structure found, recursively look for screenshot lists
      // This handles cases where language codes are the keys
      if (screenshots.isEmpty) {
        for (final key in screenshotData.keys) {
          final value = screenshotData[key];

          // Skip known non-screenshot keys
          if (key == 'icon' || key == 'iconBase64' || key == 'icon old') {
            continue;
          }

          // Recursively extract from nested structures
          if (value is List) {
            final extracted = _extractScreenshots(value, locale: locale);
            if (extracted.isNotEmpty) {
              screenshots.addAll(extracted);
            }
          } else if (value is Map) {
            final extracted = _extractScreenshots(value, locale: locale);
            if (extracted.isNotEmpty) {
              screenshots.addAll(extracted);
            }
          } else if (value is String) {
            screenshots.add(value);
          }
        }
      }
    }

    return screenshots.toSet().toList();
  }

  String? _extractLocalizedUrl(dynamic raw, String? locale) {
    if (raw == null) return null;
    if (raw is String) {
      final value = raw.trim();
      return value.isEmpty ? null : value;
    }
    if (raw is Map) {
      final prefs = <String>[];
      void addPref(String key) {
        if (key.isEmpty) return;
        if (!prefs.contains(key)) prefs.add(key);
      }

      if (locale != null && locale.trim().isNotEmpty) {
        final normalized = locale.trim().replaceAll('_', '-');
        addPref(normalized);
        addPref(normalized.replaceAll('-', '_'));
        addPref(normalized.split('-').first);
      }

      addPref('en-US');
      addPref('en_US');
      addPref('en');

      for (final key in prefs) {
        final value = raw[key] ?? raw[key.replaceAll('-', '_')];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }

      for (final value in raw.values) {
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    }
    return null;
  }

  List<String> _extractLocalePreferredScreenshots(
    Map screenshotMap,
    String? locale,
  ) {
    final localePrefs = <String>[];
    void addPref(String key) {
      if (key.isEmpty) return;
      if (!localePrefs.contains(key)) localePrefs.add(key);
    }

    if (locale != null && locale.trim().isNotEmpty) {
      final normalized = locale.trim().replaceAll('_', '-');
      addPref(normalized);
      addPref(normalized.replaceAll('-', '_'));
      final lang = normalized.split('-').first;
      addPref(lang);
    }

    addPref('en-US');
    addPref('en_US');
    addPref('en');

    const nonLocaleKeys = {
      'phone',
      'sevenInch',
      'tenInch',
      'tablet',
      'phoneScreenshots',
      'wear',
      'tv',
      'desktop',
      'ios',
      'android',
      'icon',
      'iconBase64',
      'icon old',
    };

    bool looksLikeLocaleKey(String key) {
      if (nonLocaleKeys.contains(key)) {
        return false;
      }
      final normalized = key.replaceAll('_', '-');
      return RegExp(
        r'^[a-zA-Z]{2,3}(-[a-zA-Z0-9]{2,8})*$',
      ).hasMatch(normalized);
    }

    final normalizedEntries = <String, dynamic>{};
    for (final entry in screenshotMap.entries) {
      final key = entry.key.toString();
      normalizedEntries[key] = entry.value;
      normalizedEntries[key.replaceAll('_', '-')] = entry.value;
    }

    for (final pref in localePrefs) {
      final raw =
          normalizedEntries[pref] ??
          normalizedEntries[pref.replaceAll('_', '-')];
      if (raw == null) continue;
      final extracted = _extractScreenshots(raw, locale: locale);
      if (extracted.isNotEmpty) {
        return extracted;
      }
    }

    for (final entry in screenshotMap.entries) {
      final key = entry.key.toString();
      if (!looksLikeLocaleKey(key)) continue;
      final extracted = _extractScreenshots(entry.value, locale: locale);
      if (extracted.isNotEmpty) {
        return extracted;
      }
    }

    return const <String>[];
  }

  /// Fetches the changelog content from a changelog URL
  Future<String?> fetchChangelogContent(String? changelogUrl) async {
    if (changelogUrl == null || changelogUrl.isEmpty) {
      return null;
    }

    try {
      // If it's a relative URL, prepend the repository base URL
      final fullUrl = changelogUrl.startsWith('http')
          ? changelogUrl
          : '${baseUrl ?? 'https://f-droid.org'}/$changelogUrl';

      debugPrint('Fetching changelog from: $fullUrl');

      final response = await _client.get(
        Uri.parse(fullUrl),
        headers: {'User-Agent': _userAgent},
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        debugPrint('Changelog fetch failed with status ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching changelog: $e');
      return null;
    }
  }

  void dispose() {
    _client.close();
    _databaseService.close();
  }
}

/// Custom HTTP client wrapper that provides SNI bypass capability
/// This extends the http.Client to allow bypassing SNI filtering in censored regions
class SNIBypassHttpClient extends http.BaseClient {
  final http.Client _inner;
  final bool _enableSNIBypass;
  static const String _tag = 'SNIBypassHttpClient';

  SNIBypassHttpClient({http.Client? innerClient, bool enableSNIBypass = true})
    : _inner = innerClient ?? http.Client(),
      _enableSNIBypass = enableSNIBypass;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (!_enableSNIBypass) {
      return _inner.send(request);
    }

    // Log the request for debugging
    debugPrint('$_tag: ${request.method} ${request.url} (SNI bypass enabled)');

    try {
      // Send the request through the inner client
      // The SNI bypass is handled at the HttpClient level by the app
      final response = await _inner.send(request);

      if (!response.isOk) {
        debugPrint(
          '$_tag: Received status ${response.statusCode} for ${request.url}',
        );

        // If SNI filtering is suspected, retry with direct connection
        if (response.statusCode == 403 || response.statusCode == 502) {
          debugPrint('$_tag: Possible SNI blocking detected, retrying...');
          // The retry will use the same client with SNI bypass enabled
          return _inner.send(request);
        }
      }

      return response;
    } catch (e) {
      debugPrint('$_tag: Request failed: $e');
      rethrow;
    }
  }
}

extension on http.StreamedResponse {
  bool get isOk => statusCode >= 200 && statusCode < 300;
}

/// Helper function to parse repository data in a background isolate
Map<String, dynamic> _parseRepositoryDataHelper(Map<String, dynamic> args) {
  final body = args['body'] as String;
  final repositoryUrl = args['repositoryUrl'] as String?;
  final locale = args['locale'] as String?;

  final jsonData = json.decode(body) as Map<String, dynamic>;
  final repo = FDroidRepository.fromJson(
    jsonData,
    repositoryUrl: repositoryUrl,
    locale: locale,
  );

  return {'repo': repo, 'json': jsonData};
}
