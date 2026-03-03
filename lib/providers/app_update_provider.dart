import 'package:flutter/foundation.dart';

import '../services/app_updater_service.dart';

class AppUpdateProvider extends ChangeNotifier {
  final AppUpdaterService _updaterService = AppUpdaterService();

  AppVersion? _availableUpdate;
  bool _isChecking = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _downloadError;
  bool _hasChecked = false;

  AppVersion? get availableUpdate => _availableUpdate;
  bool get isChecking => _isChecking;
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  String? get downloadError => _downloadError;
  bool get hasChecked => _hasChecked;
  bool get hasUpdate => _availableUpdate != null;

  /// Check for updates
  Future<void> checkForUpdates({bool includePreReleases = false}) async {
    if (_isChecking) return;

    _isChecking = true;
    _downloadError = null;
    notifyListeners();

    try {
      final update = await _updaterService.checkForUpdates(
        includePreReleases: includePreReleases,
      );
      _availableUpdate = update;
      _hasChecked = true;
    } catch (e) {
      _downloadError = e.toString();
      debugPrint('Error checking for updates: $e');
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  /// Download the available update
  Future<String?> downloadUpdate() async {
    if (_availableUpdate == null || _isDownloading) {
      return null;
    }

    _isDownloading = true;
    _downloadProgress = 0.0;
    _downloadError = null;
    notifyListeners();

    try {
      final filePath = await _updaterService.downloadUpdate(
        _availableUpdate!,
        onProgress: (received, total) {
          _downloadProgress = received / total;
          notifyListeners();
        },
      );

      if (filePath == null) {
        _downloadError = 'Failed to download APK';
      }

      return filePath;
    } catch (e) {
      _downloadError = e.toString();
      debugPrint('Error downloading update: $e');
      return null;
    } finally {
      _isDownloading = false;
      notifyListeners();
    }
  }

  /// Dismiss the available update notification
  void dismissUpdate() {
    _availableUpdate = null;
    notifyListeners();
  }

  /// Reset the provider state
  void reset() {
    _availableUpdate = null;
    _isChecking = false;
    _isDownloading = false;
    _downloadProgress = 0.0;
    _downloadError = null;
    _hasChecked = false;
    notifyListeners();
  }
}
