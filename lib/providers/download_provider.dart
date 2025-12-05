import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:app_installer/app_installer.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/fdroid_app.dart';
import '../providers/settings_provider.dart';
import '../services/fdroid_api_service.dart';

enum DownloadStatus { idle, downloading, completed, error, cancelled }

class DownloadInfo {
  final String packageName;
  final String versionName;
  final DownloadStatus status;
  final double progress;
  final String? filePath;
  final String? error;

  const DownloadInfo({
    required this.packageName,
    required this.versionName,
    required this.status,
    this.progress = 0.0,
    this.filePath,
    this.error,
  });

  DownloadInfo copyWith({
    DownloadStatus? status,
    double? progress,
    String? filePath,
    String? error,
  }) {
    return DownloadInfo(
      packageName: packageName,
      versionName: versionName,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      filePath: filePath ?? this.filePath,
      error: error ?? this.error,
    );
  }

  String get key => '${packageName}_$versionName';
}

class DownloadProvider extends ChangeNotifier {
  final FDroidApiService _apiService;
  SettingsProvider _settingsProvider;
  final Map<String, DownloadInfo> _downloads = {};

  DownloadProvider(this._apiService, this._settingsProvider);

  void updateSettings(SettingsProvider settings) {
    _settingsProvider = settings;
    notifyListeners();
  }

  Map<String, DownloadInfo> get downloads => Map.unmodifiable(_downloads);

  DownloadInfo? getDownloadInfo(String packageName, String versionName) {
    final key = '${packageName}_$versionName';
    return _downloads[key];
  }

  bool isDownloading(String packageName, String versionName) {
    final info = getDownloadInfo(packageName, versionName);
    return info?.status == DownloadStatus.downloading;
  }

  bool isDownloaded(String packageName, String versionName) {
    final info = getDownloadInfo(packageName, versionName);
    return info?.status == DownloadStatus.completed;
  }

  double getProgress(String packageName, String versionName) {
    final info = getDownloadInfo(packageName, versionName);
    return info?.progress ?? 0.0;
  }

  /// Requests necessary permissions for downloads
  /// On Android 13+ (API 33+), storage permission is not needed for app-specific directories.
  /// On older versions, we need WRITE_EXTERNAL_STORAGE permission.
  Future<bool> requestPermissions() async {
    // Check if storage permission is granted
    if (await Permission.storage.isGranted) {
      return true;
    }

    // Request storage permission
    final status = await Permission.storage.request();

    if (status.isGranted) {
      return true;
    }

    // On Android 13+, storage permission will be denied/unavailable
    // but we can still use app-specific storage via getExternalStorageDirectory()
    // which doesn't require permission
    if (status.isDenied || status.isPermanentlyDenied || status.isRestricted) {
      // This is expected on Android 13+
      // We'll allow the download to proceed using app-specific storage
      debugPrint(
        '[DownloadProvider] Storage permission not available (likely Android 13+), using app-specific storage',
      );
      return true;
    }

    return false;
  }

  /// Downloads an APK file
  Future<String?> downloadApk(FDroidApp app) async {
    final version = app.latestVersion;
    if (version == null) {
      throw Exception('No version available for download');
    }

    final key = DownloadInfo(
      packageName: app.packageName,
      versionName: version.versionName,
      status: DownloadStatus.idle,
    ).key;

    // Check if already downloading or completed
    final existingInfo = _downloads[key];
    if (existingInfo?.status == DownloadStatus.downloading) {
      throw Exception('Download already in progress');
    }
    if (existingInfo?.status == DownloadStatus.completed &&
        existingInfo?.filePath != null) {
      return existingInfo!.filePath;
    }

    // Check permissions
    if (!await requestPermissions()) {
      throw Exception('Storage permission is required to download APK files');
    }

    // Check if already downloaded
    if (await _apiService.isApkDownloaded(
      app.packageName,
      version.versionName,
    )) {
      final filePath = await _apiService.getDownloadedApkPath(
        app.packageName,
        version.versionName,
      );
      if (filePath != null) {
        _downloads[key] = DownloadInfo(
          packageName: app.packageName,
          versionName: version.versionName,
          status: DownloadStatus.completed,
          progress: 1.0,
          filePath: filePath,
        );
        notifyListeners();
        return filePath;
      }
    }

    // Start download
    _downloads[key] = DownloadInfo(
      packageName: app.packageName,
      versionName: version.versionName,
      status: DownloadStatus.downloading,
      progress: 0.0,
    );
    notifyListeners();

    try {
      final filePath = await _apiService.downloadApk(
        version,
        app.packageName,
        onProgress: (progress) {
          _downloads[key] = _downloads[key]!.copyWith(progress: progress);
          notifyListeners();
        },
      );

      _downloads[key] = _downloads[key]!.copyWith(
        status: DownloadStatus.completed,
        progress: 1.0,
        filePath: filePath,
      );
      notifyListeners();

      // Auto-install after download completes if enabled
      if (_settingsProvider.autoInstallApk) {
        try {
          await installApk(filePath);
        } catch (e) {
          debugPrint('Auto-install failed: $e');
        }
      }

      return filePath;
    } catch (e) {
      _downloads[key] = _downloads[key]!.copyWith(
        status: DownloadStatus.error,
        error: e.toString(),
      );
      notifyListeners();

      rethrow;
    }
  }

  /// Cancels a download (if possible)
  void cancelDownload(String packageName, String versionName) {
    final key = '${packageName}_$versionName';
    final info = _downloads[key];

    if (info?.status == DownloadStatus.downloading) {
      // Cancel the ongoing download in the API service
      _apiService.cancelDownload(packageName);

      _downloads[key] = info!.copyWith(status: DownloadStatus.cancelled);
      notifyListeners();
    }
  }

  /// Removes a download from the list
  void removeDownload(String packageName, String versionName) {
    final key = '${packageName}_$versionName';
    _downloads.remove(key);
    notifyListeners();
  }

  /// Clears all completed downloads
  void clearCompleted() {
    _downloads.removeWhere(
      (key, info) =>
          info.status == DownloadStatus.completed ||
          info.status == DownloadStatus.error ||
          info.status == DownloadStatus.cancelled,
    );
    notifyListeners();
  }

  /// Clears all tracked downloads and deletes APK files from storage.
  Future<int> clearAllDownloads() async {
    final deleted = await _apiService.clearDownloadedApks();
    _downloads.clear();
    notifyListeners();
    return deleted;
  }

  /// Gets all active downloads
  List<DownloadInfo> getActiveDownloads() {
    return _downloads.values
        .where((info) => info.status == DownloadStatus.downloading)
        .toList();
  }

  /// Gets all completed downloads
  List<DownloadInfo> getCompletedDownloads() {
    return _downloads.values
        .where((info) => info.status == DownloadStatus.completed)
        .toList();
  }

  /// Gets the download queue count
  int get activeDownloadsCount {
    return _downloads.values
        .where((info) => info.status == DownloadStatus.downloading)
        .length;
  }

  /// Installs an APK file
  Future<void> installApk(String filePath) async {
    try {
      final file = File(filePath);
      final exists = await file.exists();
      final size = exists ? await file.length() : -1;
      debugPrint(
        '[DownloadProvider] Installing APK at $filePath (exists: $exists, size: $size)',
      );

      if (!exists || size <= 0) {
        throw Exception('APK file missing or empty');
      }

      await AppInstaller.installApk(filePath);
    } catch (e) {
      throw Exception('Failed to install APK: $e');
    }
  }

  /// Requests install permission
  Future<bool> requestInstallPermission() async {
    try {
      final status = await Permission.requestInstallPackages.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('Error requesting install permission: $e');
      return false;
    }
  }

  /// Deletes a downloaded APK file
  Future<void> deleteDownloadedFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('Deleted APK file: $filePath');
      }
    } catch (e) {
      debugPrint('Error deleting APK file: $e');
    }
  }

  /// Uninstalls an app by package name
  Future<void> uninstallApp(String packageName) async {
    try {
      const actionDelete = 'android.intent.action.DELETE';
      final intent = AndroidIntent(
        action: actionDelete,
        data: 'package:$packageName',
      );
      await intent.launch();
    } catch (e) {
      throw Exception('Failed to uninstall app: $e');
    }
  }
}
