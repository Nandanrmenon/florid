import 'dart:io';

import 'package:app_installer/app_installer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../providers/settings_provider.dart';

/// Service to handle APK installation using different methods
class AppInstallationService {
  static const MethodChannel _channel =
      MethodChannel('com.nahnah.florid/shizuku');

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
      final isShizukuAvailable = await isShizukuAvailable();
      if (!isShizukuAvailable) {
        throw Exception(
          'Shizuku is not available. Please install and start Shizuku service.',
        );
      }

      // Check if Shizuku permission is granted
      final hasPermission = await hasShizukuPermission();
      if (!hasPermission) {
        // Request permission
        final granted = await requestShizukuPermission();
        if (!granted) {
          throw Exception('Shizuku permission denied');
        }
      }

      // Install the APK using Shizuku
      final result = await _channel.invokeMethod<bool>(
        'installApk',
        {'filePath': filePath},
      );
      
      if (result != true) {
        throw Exception('Shizuku installation failed');
      }
    } on PlatformException catch (e) {
      throw Exception('Shizuku installation error: ${e.message}');
    } catch (e) {
      throw Exception('Shizuku installation error: $e');
    }
  }

  /// Checks if Shizuku is available on the device
  static Future<bool> isShizukuAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isShizukuAvailable');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[AppInstallationService] Error checking Shizuku: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[AppInstallationService] Error checking Shizuku: $e');
      return false;
    }
  }

  /// Checks if Shizuku permission is granted
  static Future<bool> hasShizukuPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkPermission');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[AppInstallationService] Error checking Shizuku permission: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[AppInstallationService] Error checking Shizuku permission: $e');
      return false;
    }
  }

  /// Requests Shizuku permission
  static Future<bool> requestShizukuPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestPermission');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[AppInstallationService] Error requesting Shizuku permission: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[AppInstallationService] Error requesting Shizuku permission: $e');
      return false;
    }
  }
}
