import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:app_installer/app_installer.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shizuku_api/shizuku_api.dart';

import '../models/fdroid_app.dart';
import '../providers/settings_provider.dart';
import '../services/app_preferences_service.dart';
import '../services/fdroid_api_service.dart';
import '../services/installation_tracking_service.dart';
import '../services/notification_service.dart';

enum DownloadStatus {
  idle,
  downloading,
  completed,
  installing,
  error,
  cancelled,
}

class DownloadInfo {
  final String packageName;
  final String versionName;
  final DownloadStatus status;
  final double progress;
  final String? filePath;
  final String? error;
  final int bytesDownloaded;
  final int totalBytes;
  final double downloadSpeed; // bytes per second

  const DownloadInfo({
    required this.packageName,
    required this.versionName,
    required this.status,
    this.progress = 0.0,
    this.filePath,
    this.error,
    this.bytesDownloaded = 0,
    this.totalBytes = 0,
    this.downloadSpeed = 0.0,
  });

  DownloadInfo copyWith({
    DownloadStatus? status,
    double? progress,
    String? filePath,
    String? error,
    int? bytesDownloaded,
    int? totalBytes,
    double? downloadSpeed,
  }) {
    return DownloadInfo(
      packageName: packageName,
      versionName: versionName,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      filePath: filePath ?? this.filePath,
      error: error ?? this.error,
      bytesDownloaded: bytesDownloaded ?? this.bytesDownloaded,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadSpeed: downloadSpeed ?? this.downloadSpeed,
    );
  }

  String get key => '${packageName}_$versionName';

  String get formattedBytesDownloaded => _formatBytes(bytesDownloaded);
  String get formattedTotalBytes => _formatBytes(totalBytes);
  String get formattedSpeed => '${_formatBytes(downloadSpeed.toInt())}/s';

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

class DownloadProvider extends ChangeNotifier {
  final FDroidApiService _apiService;
  SettingsProvider _settingsProvider;
  final Map<String, DownloadInfo> _downloads = {};
  final NotificationService _notificationService = NotificationService();
  final InstallationTrackingService _trackingService =
      InstallationTrackingService();
  final AppPreferencesService _preferencesService = AppPreferencesService();
  final ShizukuApi _shizukuApi = ShizukuApi();
  String? _androidPackageName;

  // Delay after Shizuku installation to allow UI to fetch installed apps
  static const Duration _shizukuInstallSettleDelay = Duration(seconds: 2);

  DownloadProvider(this._apiService, this._settingsProvider) {
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    try {
      await _notificationService.init();
    } catch (e) {
      debugPrint('[DownloadProvider] Failed to initialize notifications: $e');
    }
  }

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
  Future<String?> downloadApk(FDroidApp app, {bool? skipAutoInstall}) async {
    final version = app.latestVersion;
    skipAutoInstall = _settingsProvider.autoInstallApk;
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
      // Verify the file actually exists before returning cached path
      if (await File(existingInfo!.filePath!).exists()) {
        return existingInfo.filePath;
      } else {
        // File was deleted, clear the cached entry
        _downloads.remove(key);
      }
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

    // Show initial notification
    await _notificationService.showDownloadProgress(
      title: app.name,
      packageName: app.packageName,
      progress: 0,
      maxProgress: 100,
    );

    // Track download speed with 5-second sampling intervals
    int lastSpeedBytes = 0;
    DateTime lastSpeedTime = DateTime.now();
    double currentSpeed = 0.0;

    try {
      final filePath = await _apiService.downloadApk(
        version,
        app.packageName,
        app.repositoryUrl,
        onProgress: (received, total) {
          final now = DateTime.now();
          final timeSinceLastSpeedUpdate =
              now.difference(lastSpeedTime).inMilliseconds / 1000.0;

          // Update speed every 5 seconds for smoother display
          if (timeSinceLastSpeedUpdate >= 1.0) {
            final bytesDiff = received - lastSpeedBytes;
            if (timeSinceLastSpeedUpdate > 0) {
              currentSpeed = bytesDiff / timeSinceLastSpeedUpdate;
            }
            lastSpeedBytes = received;
            lastSpeedTime = now;
          }

          final progress = total > 0 ? received / total : 0.0;

          _downloads[key] = _downloads[key]!.copyWith(
            progress: progress,
            bytesDownloaded: received,
            totalBytes: total,
            downloadSpeed: currentSpeed,
          );
          notifyListeners();

          // Update notification with progress
          _notificationService.showDownloadProgress(
            title: app.name,
            packageName: app.packageName,
            progress: (progress * 100).toInt(),
            maxProgress: 100,
          );
        },
      );

      _downloads[key] = _downloads[key]!.copyWith(
        status: DownloadStatus.completed,
        progress: 1.0,
        filePath: filePath,
      );
      notifyListeners();

      // Track which repository this app was downloaded from
      await _trackingService.setAppSource(app.packageName, app.repositoryUrl);

      // Show completion notification
      await _notificationService.showDownloadComplete(
        title: app.name,
        packageName: app.packageName,
      );

      // Auto-install after download completes if enabled
      if (_settingsProvider.autoInstallApk) {
        debugPrint(
          '[DownloadProvider] Auto-install queued for ${app.packageName} ${version.versionName} (method: ${_settingsProvider.installMethod})',
        );
        try {
          if (_settingsProvider.installMethod == InstallMethod.shizuku) {
            Future.microtask(() async {
              debugPrint('[DownloadProvider] Auto-install (shizuku) start');
              try {
                await installApk(
                  filePath,
                  app.packageName,
                  version.versionName,
                );
                debugPrint('[DownloadProvider] Auto-install (shizuku) done');
              } catch (e) {
                debugPrint('Auto-install (shizuku) failed: $e');
              }
            });
          } else {
            debugPrint('[DownloadProvider] Auto-install (system) start');
            await installApk(filePath, app.packageName, version.versionName);
            debugPrint('[DownloadProvider] Auto-install (system) done');
          }
        } catch (e) {
          debugPrint('Auto-install failed: $e');
        }
      } else {
        debugPrint(
          '[DownloadProvider] Auto-install skipped (enabled=${_settingsProvider.autoInstallApk}, skipAutoInstall=$skipAutoInstall)',
        );
      }

      return filePath;
    } catch (e) {
      _downloads[key] = _downloads[key]!.copyWith(
        status: DownloadStatus.error,
        error: e.toString(),
      );
      notifyListeners();

      // Show error notification
      await _notificationService.showDownloadError(
        title: app.name,
        packageName: app.packageName,
        error: e.toString(),
      );

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

      // Cancel the notification
      _notificationService.cancelDownloadNotification();
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
  Future<void> installApk(
    String filePath,
    String packageName,
    String versionName,
  ) async {
    debugPrint('[DownloadProvider] installApk entry: $filePath');
    final key = '${packageName}_$versionName';

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

      // Update status to installing
      final downloadInfo = _downloads[key];
      if (downloadInfo != null) {
        _downloads[key] = downloadInfo.copyWith(
          status: DownloadStatus.installing,
        );
        notifyListeners();
      } else {
        debugPrint(
          '[DownloadProvider] Warning: downloadInfo is null for $key, UI status will not update',
        );
      }

      if (_settingsProvider.installMethod == InstallMethod.shizuku) {
        // Schedule Shizuku install work off the immediate call stack to avoid
        // blocking UI when the platform channel does synchronous work.
        await Future<void>(() => _installWithShizuku(filePath));

        // Keep the installing status for a bit longer to allow the UI layer
        // (which has access to AppProvider) to call fetchInstalledApps().
        // Note: This is a workaround for the architectural constraint that
        // DownloadProvider doesn't have access to AppProvider. A better solution
        // would be to use a callback or event system, but that would require
        // larger architectural changes.
        await Future.delayed(_shizukuInstallSettleDelay);
      } else {
        await _installWithSystemInstaller(filePath);
      }

      // Update status back to completed after installation
      final updatedInfo = _downloads[key];
      if (updatedInfo != null) {
        _downloads[key] = updatedInfo.copyWith(
          status: DownloadStatus.completed,
        );
        notifyListeners();
      }
    } catch (e) {
      // On error, revert status back to completed so the install button
      // remains clickable, allowing the user to retry the installation
      final downloadInfo = _downloads[key];
      if (downloadInfo != null) {
        _downloads[key] = downloadInfo.copyWith(
          status: DownloadStatus.completed,
        );
        notifyListeners();
      }
      throw Exception('Failed to install APK: $e');
    }
  }

  Future<void> _installWithSystemInstaller(String filePath) async {
    await AppInstaller.installApk(filePath);
  }

  Future<void> _installWithShizuku(String filePath) async {
    if (!Platform.isAndroid) {
      throw Exception('Shizuku install is only available on Android');
    }

    final isBinderRunning = await _shizukuApi.pingBinder() ?? false;
    if (!isBinderRunning) {
      throw Exception('Shizuku is not running');
    }

    var hasPermission = await _shizukuApi.checkPermission() ?? false;
    if (!hasPermission) {
      hasPermission = await _shizukuApi.requestPermission() ?? false;
    }
    if (!hasPermission) {
      throw Exception('Shizuku permission denied');
    }

    final packageName = await _getAndroidPackageName();
    final sourcePath = await _prepareShizukuSource(filePath);
    final escapedPath = _escapeForDoubleQuotes(sourcePath);
    final fileName = Uri.file(sourcePath).pathSegments.last;
    final tempPath = '/data/local/tmp/$fileName';

    try {
      // Copy into /data/local/tmp so system_server can read it.
      final copyCommand = _buildShizukuCopyCommand(
        packageName: packageName,
        sourcePath: escapedPath,
        destPath: tempPath,
      );
      final copyResult = await _shizukuApi.runCommand(copyCommand);
      if (copyResult == null) {
        throw Exception('Shizuku copy returned no response');
      }
      final copyLower = copyResult.toLowerCase();
      if (copyLower.contains('permission denied') ||
          copyLower.contains('no such file') ||
          copyLower.contains('error')) {
        throw Exception('Shizuku copy failed: $copyResult');
      }

      final installCommand = 'pm install -r -g "$tempPath"';
      final result = await _shizukuApi.runCommand(installCommand);
      if (result == null) {
        throw Exception('Shizuku install returned no response');
      }

      final normalized = result.toLowerCase();
      final success = normalized.contains('success');
      if (!success) {
        throw Exception('Shizuku install failed: $result');
      }
    } finally {
      await _shizukuApi.runCommand('rm -f "$tempPath"');
    }
  }

  Future<String> _prepareShizukuSource(String filePath) async {
    final tempDir = await getTemporaryDirectory();
    final fileName = Uri.file(filePath).pathSegments.last;
    final stagedPath = p.join(tempDir.path, fileName);
    if (filePath == stagedPath) {
      return stagedPath;
    }

    final sourceFile = File(filePath);
    final stagedFile = File(stagedPath);
    await stagedFile.parent.create(recursive: true);
    await sourceFile.copy(stagedPath);
    return stagedPath;
  }

  String _buildShizukuCopyCommand({
    required String packageName,
    required String sourcePath,
    required String destPath,
  }) {
    final isInternal =
        sourcePath.startsWith('/data/user/0/$packageName/') ||
        sourcePath.startsWith('/data/data/$packageName/');
    if (isInternal) {
      return 'sh -c "run-as $packageName cat \\"$sourcePath\\" > \\"$destPath\\""';
    }
    return 'cp "$sourcePath" "$destPath"';
  }

  Future<String> _getAndroidPackageName() async {
    if (_androidPackageName != null) {
      return _androidPackageName!;
    }
    final info = await PackageInfo.fromPlatform();
    final packageName = info.packageName;
    _androidPackageName = packageName;
    return packageName;
  }

  String _escapeForDoubleQuotes(String value) {
    return value.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
  }

  /// Requests install permission
  Future<bool> requestInstallPermission() async {
    try {
      if (_settingsProvider.installMethod == InstallMethod.shizuku) {
        final isBinderRunning = await _shizukuApi.pingBinder() ?? false;
        if (!isBinderRunning) {
          return false;
        }
        final hasPermission = await _shizukuApi.checkPermission() ?? false;
        if (hasPermission) {
          return true;
        }
        return await _shizukuApi.requestPermission() ?? false;
      }
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

      // Remove tracking data when app is uninstalled
      // Note: This is best-effort. The actual uninstall is handled by Android
      // and we can't know for sure if it succeeded immediately
      await _trackingService.removeAppSource(packageName);
      await _preferencesService.removeIncludeUnstable(packageName);
    } catch (e) {
      throw Exception('Failed to uninstall app: $e');
    }
  }

  /// Gets the repository URL that an app was downloaded from
  Future<String?> getAppSource(String packageName) async {
    return await _trackingService.getAppSource(packageName);
  }
}
