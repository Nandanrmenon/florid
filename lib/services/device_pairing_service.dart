import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../providers/settings_provider.dart';

/// Service for managing device pairing with the web companion store
class DevicePairingService {
  final SettingsProvider _settingsProvider;
  static const _uuid = Uuid();

  DevicePairingService(this._settingsProvider);

  /// Check if device is currently paired
  bool get isPaired => _settingsProvider.webSyncEnabled;

  /// Get the current device ID (generates one if not exists)
  Future<String> getDeviceId() async {
    String? deviceId = _settingsProvider.deviceId;
    
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = _generateDeviceId();
      // Store device ID but don't enable sync yet (that happens after pairing)
      final prefs = await _settingsProvider.saveDevicePairing(
        deviceId: deviceId,
        userId: _settingsProvider.userId ?? '',
        authToken: _settingsProvider.authToken ?? '',
      );
    }
    
    return deviceId;
  }

  /// Generate a unique device ID
  String _generateDeviceId() {
    return _uuid.v4();
  }

  /// Generate a pairing code for web to scan/enter
  String generatePairingCode() {
    // Generate a 6-digit pairing code
    final random = DateTime.now().millisecondsSinceEpoch % 1000000;
    return random.toString().padLeft(6, '0');
  }

  /// Get device name for display
  Future<String> getDeviceName() async {
    String? savedName = _settingsProvider.deviceName;
    if (savedName != null && savedName.isNotEmpty) {
      return savedName;
    }

    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return '${iosInfo.name} (${iosInfo.model})';
      }
    } catch (e) {
      debugPrint('[DevicePairingService] Error getting device name: $e');
    }

    return 'Unknown Device';
  }

  /// Pair device with user account
  Future<void> pairDevice({
    required String userId,
    required String authToken,
  }) async {
    final deviceId = await getDeviceId();
    final deviceName = await getDeviceName();

    await _settingsProvider.saveDevicePairing(
      deviceId: deviceId,
      userId: userId,
      authToken: authToken,
      deviceName: deviceName,
    );

    debugPrint(
      '[DevicePairingService] Device paired: $deviceId ($deviceName) with user $userId',
    );
  }

  /// Unpair device from user account
  Future<void> unpairDevice() async {
    await _settingsProvider.clearDevicePairing();
    debugPrint('[DevicePairingService] Device unpaired');
  }

  /// Update device name
  Future<void> updateDeviceName(String newName) async {
    await _settingsProvider.setDeviceName(newName);
  }

  /// Get pairing URL for QR code
  String getPairingUrl(String pairingCode, String deviceId) {
    // This URL would point to your web app's pairing page
    // For now, using a placeholder. Replace with actual domain when backend is deployed
    const baseUrl = 'https://florid.app/pair'; // TODO: Update with actual URL
    return '$baseUrl?code=$pairingCode&deviceId=$deviceId';
  }
}
