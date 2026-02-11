import 'dart:io';

import 'package:app_installer/app_installer.dart';
import 'package:flutter/foundation.dart';
import 'package:shizuku_apk_installer/shizuku_apk_installer.dart';

import '../providers/settings_provider.dart';

/// Service to handle APK installation using different methods
class AppInstallationService {
  /// Installs an APK file using the specified installation method
  static Future<void> installApk(
    String filePath,
    InstallMethod method,
  ) async {
    try {
      final file = File(filePath);
      final exists = await file.exists();
      final size = exists ? await file.length() : -1;
      debugPrint(
        '[AppInstallationService] Installing APK at $filePath (exists: $exists, size: $size, method: $method)',
      );

      if (!exists || size <= 0) {
        throw Exception('APK file missing or empty');
      }

      switch (method) {
        case InstallMethod.systemDefault:
          await _installViaSystemDefault(filePath);
          break;
        case InstallMethod.shizuku:
          await _installViaShizuku(filePath);
          break;
      }
    } catch (e) {
      throw Exception('Failed to install APK: $e');
    }
  }

  /// Installs APK using the system default method
  static Future<void> _installViaSystemDefault(String filePath) async {
    await AppInstaller.installApk(filePath);
  }

  /// Installs APK using Shizuku
  static Future<void> _installViaShizuku(String filePath) async {
    try {
      // Check if Shizuku is available
      final isShizukuAvailable = await ShizukuApkInstaller.isShizukuAvailable();
      if (!isShizukuAvailable) {
        throw Exception(
          'Shizuku is not available. Please install and start Shizuku service.',
        );
      }

      // Check if Shizuku permission is granted
      final hasPermission = await ShizukuApkInstaller.checkPermission();
      if (!hasPermission) {
        // Request permission
        final granted = await ShizukuApkInstaller.requestPermission();
        if (!granted) {
          throw Exception('Shizuku permission denied');
        }
      }

      // Install the APK
      final result = await ShizukuApkInstaller.installApk(filePath);
      if (!result) {
        throw Exception('Shizuku installation failed');
      }
    } catch (e) {
      throw Exception('Shizuku installation error: $e');
    }
  }

  /// Checks if Shizuku is available on the device
  static Future<bool> isShizukuAvailable() async {
    try {
      return await ShizukuApkInstaller.isShizukuAvailable();
    } catch (e) {
      debugPrint('[AppInstallationService] Error checking Shizuku: $e');
      return false;
    }
  }

  /// Checks if Shizuku permission is granted
  static Future<bool> hasShizukuPermission() async {
    try {
      return await ShizukuApkInstaller.checkPermission();
    } catch (e) {
      debugPrint('[AppInstallationService] Error checking Shizuku permission: $e');
      return false;
    }
  }

  /// Requests Shizuku permission
  static Future<bool> requestShizukuPermission() async {
    try {
      return await ShizukuApkInstaller.requestPermission();
    } catch (e) {
      debugPrint('[AppInstallationService] Error requesting Shizuku permission: $e');
      return false;
    }
  }
}
