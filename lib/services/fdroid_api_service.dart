import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/fdroid_app.dart';
import 'database_service.dart';

class FDroidApiService {
  static const String baseUrl = 'https://f-droid.org';
  static const String apiUrl = '$baseUrl/api/v1';
  static const String repoIndexUrl = '$baseUrl/repo/index-v2.json';
  static const String _cacheFileName = 'fdroid_index_cache.json';
  static const Duration _fallbackCacheMaxAge = Duration(hours: 6);

  final http.Client _client;
  final Dio _dio;
  final Map<String, CancelToken> _downloadTokens = {};
  final DatabaseService _databaseService;

  /// Cache raw repository JSON for screenshot extraction
  Map<String, dynamic>? _cachedRawJson;

  FDroidApiService({
    http.Client? client,
    Dio? dio,
    DatabaseService? databaseService,
  }) : _client = client ?? http.Client(),
       _dio = dio ?? Dio(),
       _databaseService = databaseService ?? DatabaseService();

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

  /// Fetches the complete F-Droid repository index with database caching.
  /// Flow: try database (fresh) -> network -> database fallback on network failure.
  Future<FDroidRepository> fetchRepository() async {
    debugPrint('=== fetchRepository called ===');

    // Check if database is populated and fresh
    final isPopulated = await _databaseService.isPopulated();
    final needsUpdate = await _databaseService.needsUpdate(
      _fallbackCacheMaxAge,
    );

    debugPrint('Database populated: $isPopulated, needs update: $needsUpdate');

    // If database is fresh, load from it
    if (isPopulated && !needsUpdate) {
      try {
        debugPrint('Loading from database (fresh)...');
        return await _loadRepositoryFromDatabase();
      } catch (e) {
        // If database read fails, try network
        debugPrint('Error loading from database: $e');
      }
    }

    // Try to fetch from network
    try {
      debugPrint('Fetching from network...');
      final response = await _client.get(Uri.parse(repoIndexUrl));

      if (response.statusCode == 200) {
        final body = response.body;
        final jsonData = json.decode(body);

        // Cache the raw JSON for screenshot extraction
        _cachedRawJson = jsonData as Map<String, dynamic>;
        debugPrint(
          'Cached raw JSON, size: ${_cachedRawJson?.length ?? 0} keys',
        );

        // Parse repository
        final repo = FDroidRepository.fromJson(jsonData);

        // Store in database on a background isolate to avoid blocking UI
        try {
          _importRepositoryInBackground(repo); // Fire and forget
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
    } catch (e) {
      debugPrint('Network fetch failed: $e');

      // Fall back to database if available (even if stale)
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

      throw Exception('Error fetching repository: $e');
    }
  }

  /// Loads repository data from the database
  Future<FDroidRepository> _loadRepositoryFromDatabase() async {
    final apps = await _databaseService.getAllApps();
    final repoName =
        await _databaseService.getMetadata('repo_name') ?? 'F-Droid';
    final repoDescription =
        await _databaseService.getMetadata('repo_description') ?? '';

    // Also try to load the cached JSON for screenshot extraction
    final cachedJson = await _tryLoadCache();
    if (cachedJson != null) {
      _cachedRawJson = cachedJson;
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

  /// Fetches repository from a custom URL
  Future<FDroidRepository> fetchRepositoryFromUrl(String url) async {
    try {
      // Construct the index URL
      String indexUrl;
      if (url.endsWith('index-v2.json')) {
        // Full URL provided
        indexUrl = url;
      } else if (url.endsWith('/repo') || url.endsWith('/repo/')) {
        // URL already includes /repo path
        indexUrl = url.endsWith('/')
            ? '${url}index-v2.json'
            : '$url/index-v2.json';
      } else {
        // Base URL without /repo
        indexUrl = url.endsWith('/')
            ? '${url}repo/index-v2.json'
            : '$url/repo/index-v2.json';
      }

      // Derive repository base (strip the index file and trailing slash)
      var repoBase = indexUrl.replaceFirst(RegExp(r'index-v2\.json$'), '');
      if (repoBase.endsWith('/')) {
        repoBase = repoBase.substring(0, repoBase.length - 1);
      }

      debugPrint('Fetching from custom repo: $indexUrl');
      final response = await _client.get(Uri.parse(indexUrl));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final repo = FDroidRepository.fromJson(
          jsonData,
          repositoryUrl: repoBase,
        );
        debugPrint('Successfully fetched repository from $url');
        return repo;
      } else {
        throw Exception('Failed to load repository: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching from custom repo $url: $e');
      throw Exception('Error fetching repository from $url: $e');
    }
  }

  /// Imports repository asynchronously to avoid blocking UI
  void _importRepositoryInBackground(
    FDroidRepository repo, {
    int? repositoryId,
  }) {
    try {
      debugPrint('Scheduling database import...');
      // Defer import to run after the current frame without blocking UI
      Future.microtask(() async {
        try {
          await _databaseService.importRepository(
            repo,
            repositoryId: repositoryId,
          );
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

  /// Searches for apps from a specific custom repository using database
  Future<List<FDroidApp>> searchAppsFromRepositoryUrl(
    String query,
    String repositoryUrl,
  ) async {
    try {
      // Try to search from database if repository data is cached there
      final results = await _databaseService.searchAppsByRepository(
        query,
        repositoryUrl,
      );
      if (results.isNotEmpty) {
        return results;
      }

      // Fallback: fetch from network if not in database
      debugPrint(
        'Repository $repositoryUrl not in database, fetching from network...',
      );
      final repo = await fetchRepositoryFromUrl(repositoryUrl);
      return repo.searchApps(query);
    } catch (e) {
      throw Exception('Error searching apps from repository: $e');
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
    _databaseService.setLocale(locale);
  }

  /// Downloads an APK file with progress tracking and cancellation support
  Future<String> downloadApk(
    FDroidVersion version,
    String packageName,
    String repositoryUrl, {
    Function(double)? onProgress,
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
      print('[FDroidApiService] Downloading APK:');
      print('  URL: $downloadUrl');
      print('  To: $filePath');

      final token = cancelToken ?? CancelToken();
      _downloadTokens[packageName] = token;

      final response = await _dio.download(
        downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            onProgress(received / total);
          }
        },
        cancelToken: token,
      );

      // Log response metadata
      try {
        final status = response.statusCode;
        final contentType = response.headers.value('content-type');
        print(
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

        print(
          '[FDroidApiService] Downloaded file: $filePath (exists: $fileExists, size: $fileSize bytes, zipMagic=$isZip, magicBytes=$magic)',
        );

        if (!fileExists || fileSize <= 0 || !isZip) {
          throw Exception('Downloaded APK is invalid or missing');
        }
      } catch (e) {
        print('[FDroidApiService] Error checking file after download: $e');
        rethrow;
      }

      _downloadTokens.remove(packageName);
      return filePath;
    } catch (e) {
      _downloadTokens.remove(packageName);
      print('[FDroidApiService] Error downloading APK: $e');
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

  /// Extracts screenshots for a specific app package from cached raw JSON
  /// If the cache is not populated, fetches the repository first
  Future<List<String>> getScreenshots(String packageName) async {
    debugPrint('=== getScreenshots called for: $packageName ===');

    // If cache is empty, fetch the repository first
    if (_cachedRawJson == null) {
      debugPrint('Cache is empty, fetching repository first...');
      try {
        await fetchRepository();
      } catch (e) {
        debugPrint('Error fetching repository: $e');
        return [];
      }
    }

    if (_cachedRawJson == null) {
      debugPrint('_cachedRawJson is still null after fetch!');
      return [];
    }

    try {
      final packages = (_cachedRawJson!['packages'] as Map?)
          ?.cast<String, dynamic>();
      if (packages == null) {
        debugPrint('packages is null!');
        return [];
      }

      final pkgData = packages[packageName] as Map?;
      if (pkgData == null) {
        debugPrint('pkgData is null for $packageName');
        return [];
      }

      debugPrint('pkgData keys: ${pkgData.keys.toList()}');

      // Try multiple locations for screenshots
      List<String>? screenshotsList;

      // 1. Direct metadata.screenshots
      final metadata = (pkgData['metadata'] as Map?)?.cast<String, dynamic>();
      if (metadata != null) {
        debugPrint('metadata found! Keys: ${metadata.keys.toList()}');
        screenshotsList = _extractScreenshots(metadata['screenshots']);
        if (screenshotsList.isNotEmpty) {
          debugPrint(
            'Found ${screenshotsList.length} screenshots in metadata[screenshots]',
          );
          return screenshotsList;
        }

        // 2. Check if screenshots might be in a localized format
        for (final key in metadata.keys) {
          if (key.toString().contains('screenshot')) {
            debugPrint('Checking key: $key');
            screenshotsList = _extractScreenshots(metadata[key]);
            if (screenshotsList.isNotEmpty) {
              debugPrint(
                'Found ${screenshotsList.length} screenshots under key: $key',
              );
              return screenshotsList;
            }
          }
        }
      } else {
        debugPrint('metadata is null!');
      }

      debugPrint('No screenshots found for $packageName');
      return [];
    } catch (e) {
      debugPrint('Error extracting screenshots for $packageName: $e');
      return [];
    }
  }

  List<String> _extractScreenshots(dynamic screenshotData) {
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
      // Check for device-type categories (phone, sevenInch, tenInch)
      for (final deviceType in ['phone', 'sevenInch', 'tenInch']) {
        final deviceData = screenshotData[deviceType];
        if (deviceData != null) {
          // Device data could be localized: {en-US: [...], de: [...]}
          if (deviceData is Map) {
            // Look for localized screenshot lists
            for (final localeScreenshots in deviceData.values) {
              if (localeScreenshots is List) {
                for (final item in localeScreenshots) {
                  if (item is String) {
                    screenshots.add(item);
                  } else if (item is Map && item['name'] is String) {
                    screenshots.add(item['name'] as String);
                  }
                }
              }
            }
          } else if (deviceData is List) {
            for (final item in deviceData) {
              if (item is String) {
                screenshots.add(item);
              } else if (item is Map && item['name'] is String) {
                screenshots.add(item['name'] as String);
              }
            }
          }
        }
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
            final extracted = _extractScreenshots(value);
            if (extracted.isNotEmpty) {
              screenshots.addAll(extracted);
            }
          } else if (value is Map) {
            final extracted = _extractScreenshots(value);
            if (extracted.isNotEmpty) {
              screenshots.addAll(extracted);
            }
          } else if (value is String) {
            screenshots.add(value);
          }
        }
      }
    }

    return screenshots;
  }

  void dispose() {
    _client.close();
    _databaseService.close();
  }
}
