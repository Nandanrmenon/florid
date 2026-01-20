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
  })  : _client = client ?? http.Client(),
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
    // Check if database is populated and fresh
    final isPopulated = await _databaseService.isPopulated();
    final needsUpdate = await _databaseService.needsUpdate(_fallbackCacheMaxAge);

    // If database is fresh, load from it
    if (isPopulated && !needsUpdate) {
      try {
        return await _loadRepositoryFromDatabase();
      } catch (e) {
        // If database read fails, try network
        print('Error loading from database: $e');
      }
    }

    // Try to fetch from network
    try {
      final response = await _client.get(Uri.parse(repoIndexUrl));

      if (response.statusCode == 200) {
        final body = response.body;
        final jsonData = json.decode(body);
        
        // Cache the raw JSON for screenshot extraction
        _cachedRawJson = jsonData as Map<String, dynamic>;
        
        // Parse repository
        final repo = FDroidRepository.fromJson(jsonData);
        
        // Store in database asynchronously (don't wait for it)
        _databaseService.importRepository(repo).catchError((e) {
          debugPrint('Error importing to database: $e');
        });
        
        // Also save JSON cache for screenshot extraction
        await _saveCache(body);
        
        return repo;
      } else {
        throw Exception('Failed to load repository: ${response.statusCode}');
      }
    } catch (e) {
      // Fall back to database if available (even if stale)
      if (isPopulated) {
        try {
          return await _loadRepositoryFromDatabase();
        } catch (dbError) {
          debugPrint('Error loading from database fallback: $dbError');
        }
      }
      
      // Last resort: try JSON cache
      final cachedJson = await _tryLoadCache();
      if (cachedJson != null) {
        _cachedRawJson = cachedJson;
        return FDroidRepository.fromJson(cachedJson);
      }
      
      throw Exception('Error fetching repository: $e');
    }
  }

  /// Loads repository data from the database
  Future<FDroidRepository> _loadRepositoryFromDatabase() async {
    final apps = await _databaseService.getAllApps();
    final repoName = await _databaseService.getMetadata('repo_name') ?? 'F-Droid';
    final repoDescription = await _databaseService.getMetadata('repo_description') ?? '';
    
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
    String packageName, {
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
      print('[FDroidApiService] Downloading APK:');
      print('  URL: ${version.downloadUrl}');
      print('  To: $filePath');

      final token = cancelToken ?? CancelToken();
      _downloadTokens[packageName] = token;

      final response = await _dio.download(
        version.downloadUrl,
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
  List<String> getScreenshots(String packageName) {
    if (_cachedRawJson == null) {
      return [];
    }

    try {
      final packages = (_cachedRawJson!['packages'] as Map?)
          ?.cast<String, dynamic>();
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
        screenshotsList = _extractScreenshots(metadata['screenshots']);
        if (screenshotsList.isNotEmpty) {
          return screenshotsList;
        }
      }

      // 2. Check if screenshots might be in a localized format
      if (metadata != null) {
        for (final key in metadata.keys) {
          if (key.toString().contains('screenshot')) {
            screenshotsList = _extractScreenshots(metadata[key]);
            if (screenshotsList.isNotEmpty) return screenshotsList;
          }
        }
      }

      return [];
    } catch (e) {
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

      // If no device-type structure found, try localized format
      if (screenshots.isEmpty) {
        for (final value in screenshotData.values) {
          if (value is List) {
            screenshots.addAll(_extractScreenshots(value));
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
