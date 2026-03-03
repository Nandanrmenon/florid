import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class AppVersion {
  final String version;
  final String buildNumber;
  final String releaseUrl;
  final String releaseNotes;
  final String downloadUrl;
  final DateTime releaseDate;
  final bool isPreRelease;

  AppVersion({
    required this.version,
    required this.buildNumber,
    required this.releaseUrl,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.releaseDate,
    required this.isPreRelease,
  });

  bool isNewerThan(String currentVersion) {
    final current = _parseVersion(currentVersion);
    final remote = _parseVersion(version);

    for (int i = 0; i < current.length && i < remote.length; i++) {
      if (remote[i] > current[i]) return true;
      if (remote[i] < current[i]) return false;
    }

    return remote.length > current.length;
  }

  static List<int> _parseVersion(String version) {
    return version.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  }
}

class AppUpdaterService {
  static const String _owner = 'Nandanrmenon';
  static const String _repo = 'florid';
  static const String _apiUrl =
      'https://api.github.com/repos/$_owner/$_repo/releases';
  static const String _releaseUrl =
      'https://github.com/$_owner/$_repo/releases/tag';

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  /// Check for app updates
  /// Returns the latest available version if an update is available, null otherwise
  Future<AppVersion?> checkForUpdates({bool includePreReleases = false}) async {
    try {
      final currentInfo = await PackageInfo.fromPlatform();
      final currentVersion = currentInfo.version;

      final response = await _dio.get<String>(_apiUrl);

      if (response.statusCode != 200) {
        debugPrint('❌ Failed to fetch releases: ${response.statusCode}');
        return null;
      }

      final releases = jsonDecode(response.data!) as List<dynamic>;

      for (final release in releases) {
        final releaseData = release as Map<String, dynamic>;
        final isDraft = releaseData['draft'] as bool? ?? false;
        final isPreRelease = releaseData['prerelease'] as bool? ?? false;
        final tagName = releaseData['tag_name'] as String? ?? '';

        // Skip drafts and pre-releases if not included
        if (isDraft || (isPreRelease && !includePreReleases)) {
          continue;
        }

        // Extract version from tag (e.g., "v1.0.8" -> "1.0.8")
        final version = tagName.replaceFirst('v', '');

        if (version.isEmpty) continue;

        // Check if this is a newer version
        if (!_isVersionNewer(version, currentVersion)) {
          continue;
        }

        // Find APK download URL
        final assets = releaseData['assets'] as List<dynamic>? ?? [];
        final apkAsset = assets.firstWhere((asset) {
          final name = (asset as Map<String, dynamic>)['name'] as String?;
          return name?.endsWith('.apk') ?? false;
        }, orElse: () => null);

        if (apkAsset == null) {
          debugPrint('⚠️ No APK found in release $version');
          continue;
        }

        final downloadUrl =
            (apkAsset as Map<String, dynamic>)['browser_download_url']
                as String?;
        if (downloadUrl == null || downloadUrl.isEmpty) {
          continue;
        }

        final releaseNotes =
            releaseData['body'] as String? ?? 'No release notes provided';
        final releaseDateStr = releaseData['published_at'] as String? ?? '';
        final releaseDate = DateTime.tryParse(releaseDateStr) ?? DateTime.now();

        return AppVersion(
          version: version,
          buildNumber: currentInfo.buildNumber,
          releaseUrl: '$_releaseUrl/$tagName',
          releaseNotes: releaseNotes,
          downloadUrl: downloadUrl,
          releaseDate: releaseDate,
          isPreRelease: isPreRelease,
        );
      }

      debugPrint('✅ No updates available');
      return null;
    } catch (e) {
      debugPrint('❌ Error checking for updates: $e');
      return null;
    }
  }

  /// Download the APK file
  /// Returns the file path if successful, null otherwise
  Future<String?> downloadUpdate(
    AppVersion version, {
    Function(int, int)? onProgress,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/florid_${version.version}.apk';

      await _dio.download(
        version.downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress?.call(received, total);
          }
        },
      );

      debugPrint('✅ Downloaded APK to: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('❌ Failed to download APK: $e');
      return null;
    }
  }

  bool _isVersionNewer(String remoteVersion, String currentVersion) {
    try {
      // Extract semantic version (before the +) from version string
      // Format is typically "1.0.8" or "1.0.8+9" where +9 is build number
      final remoteSemantic = remoteVersion.split('+')[0];
      final currentSemantic = currentVersion.split('+')[0];

      final remoteParts = remoteSemantic
          .split('.')
          .map((e) => int.tryParse(e) ?? 0)
          .toList();
      final currentParts = currentSemantic
          .split('.')
          .map((e) => int.tryParse(e) ?? 0)
          .toList();

      // Pad with zeros to ensure same length for comparison
      final maxLength = [
        remoteParts.length,
        currentParts.length,
      ].reduce((a, b) => a > b ? a : b);
      while (remoteParts.length < maxLength) remoteParts.add(0);
      while (currentParts.length < maxLength) currentParts.add(0);

      for (int i = 0; i < maxLength; i++) {
        final remote = remoteParts[i];
        final current = currentParts[i];

        if (remote > current) return true;
        if (remote < current) return false;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error parsing versions: $e');
      return false;
    }
  }
}
