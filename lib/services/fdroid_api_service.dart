import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/fdroid_app.dart';

class FDroidApiService {
  static const String baseUrl = 'https://f-droid.org';
  static const String apiUrl = '$baseUrl/api/v1';
  static const String repoIndexUrl = '$baseUrl/repo/index-v2.json';
  static const String _cacheFileName = 'fdroid_index_cache.json';
  static const Duration _fallbackCacheMaxAge = Duration(hours: 6);

  final http.Client _client;
  final Dio _dio;
  final Map<String, CancelToken> _downloadTokens = {};

  /// Cache raw repository JSON for screenshot extraction
  Map<String, dynamic>? _cachedRawJson;

  FDroidApiService({http.Client? client, Dio? dio})
    : _client = client ?? http.Client(),
      _dio = dio ?? Dio();

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

  /// Fetches the complete F-Droid repository index with disk caching.
  /// Flow: try cache (fresh) -> network -> cache fallback on network failure.
  Future<FDroidRepository> fetchRepository() async {
    Map<String, dynamic>? cachedJson = await _tryLoadCache();

    // Prefer cache when available.
    if (cachedJson != null) {
      try {
        _cachedRawJson = cachedJson;
        return FDroidRepository.fromJson(cachedJson);
      } catch (_) {
        // If cache is corrupt, fall through to network fetch.
        cachedJson = null;
      }
    }

    try {
      final response = await _client.get(Uri.parse(repoIndexUrl));

      if (response.statusCode == 200) {
        final body = response.body;
        await _saveCache(body);
        final jsonData = json.decode(body);
        // Cache the raw JSON for screenshot extraction
        _cachedRawJson = jsonData as Map<String, dynamic>;
        // Defensive: ensure expected top-level keys exist, else wrap in structure
        if ((!jsonData.containsKey('repo') ||
            !jsonData.containsKey('packages'))) {
          // Possibly already flattened custom structure; we still attempt parsing
        }
        final repo = FDroidRepository.fromJson(jsonData);
        return repo;
      } else {
        throw Exception('Failed to load repository: ${response.statusCode}');
      }
    } catch (e) {
      // Fall back to cache if available.
      if (cachedJson != null) {
        _cachedRawJson = cachedJson;
        return FDroidRepository.fromJson(cachedJson);
      }
      throw Exception('Error fetching repository: $e');
    }
  }

  /// Clears the cached repository index from disk and memory.
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
  }

  /// Fetches apps with pagination support
  Future<List<FDroidApp>> fetchApps({
    int? limit,
    int? offset,
    String? category,
    String? search,
  }) async {
    try {
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
    } catch (e) {
      throw Exception('Error fetching apps: $e');
    }
  }

  /// Fetches the latest apps
  Future<List<FDroidApp>> fetchLatestApps({int limit = 50}) async {
    try {
      final repository = await fetchRepository();
      return repository.latestApps.take(limit).toList();
    } catch (e) {
      throw Exception('Error fetching latest apps: $e');
    }
  }

  /// Fetches apps by category
  Future<List<FDroidApp>> fetchAppsByCategory(String category) async {
    try {
      final repository = await fetchRepository();
      return repository.getAppsByCategory(category);
    } catch (e) {
      throw Exception('Error fetching apps by category: $e');
    }
  }

  /// Searches for apps
  Future<List<FDroidApp>> searchApps(String query) async {
    try {
      final repository = await fetchRepository();
      return repository.searchApps(query);
    } catch (e) {
      throw Exception('Error searching apps: $e');
    }
  }

  /// Fetches all available categories
  Future<List<String>> fetchCategories() async {
    try {
      final repository = await fetchRepository();
      return repository.categories;
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }

  /// Fetches a specific app by package name
  Future<FDroidApp?> fetchApp(String packageName) async {
    try {
      final repository = await fetchRepository();
      return repository.apps[packageName];
    } catch (e) {
      throw Exception('Error fetching app: $e');
    }
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
  }
}
