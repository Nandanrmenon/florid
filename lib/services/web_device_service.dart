import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/paired_device.dart';
import 'web_auth_service.dart';

/// Service for managing paired devices on web
class WebDeviceService extends ChangeNotifier {
  final WebAuthService _authService;

  // Backend API URL
  static const String _baseUrl =
      kDebugMode ? 'http://localhost:3000' : 'https://florid-backend.example.com';

  List<PairedDevice> _devices = [];
  PairedDevice? _selectedDevice;
  bool _isLoading = false;

  WebDeviceService(this._authService);

  List<PairedDevice> get devices => List.unmodifiable(_devices);
  PairedDevice? get selectedDevice => _selectedDevice;
  bool get isLoading => _isLoading;

  /// Fetch paired devices from backend
  Future<void> fetchDevices() async {
    if (!_authService.isAuthenticated) {
      debugPrint('[WebDeviceService] Not authenticated');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/devices'),
        headers: _authService.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final devicesList = data['devices'] as List;
        _devices = devicesList
            .map((d) => PairedDevice.fromJson(d as Map<String, dynamic>))
            .toList();

        // Auto-select first active device if none selected
        if (_selectedDevice == null && _devices.isNotEmpty) {
          _selectedDevice = _devices.firstWhere(
            (d) => d.isActive,
            orElse: () => _devices.first,
          );
        }

        debugPrint('[WebDeviceService] Fetched ${_devices.length} devices');
      } else {
        debugPrint('[WebDeviceService] Failed to fetch devices: ${response.body}');
      }
    } catch (e) {
      debugPrint('[WebDeviceService] Error fetching devices: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Pair a device using pairing code
  Future<bool> pairDevice(String deviceId, String deviceName, String pairingCode) async {
    if (!_authService.isAuthenticated) {
      debugPrint('[WebDeviceService] Not authenticated');
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/devices/pair'),
        headers: _authService.getAuthHeaders(),
        body: jsonEncode({
          'deviceId': deviceId,
          'deviceName': deviceName,
          'pairingCode': pairingCode,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('[WebDeviceService] Device paired successfully');
        await fetchDevices();
        return true;
      } else {
        debugPrint('[WebDeviceService] Pairing failed: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('[WebDeviceService] Pairing error: $e');
      return false;
    }
  }

  /// Unpair a device
  Future<bool> unpairDevice(String deviceId) async {
    if (!_authService.isAuthenticated) {
      debugPrint('[WebDeviceService] Not authenticated');
      return false;
    }

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/devices/$deviceId'),
        headers: _authService.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        debugPrint('[WebDeviceService] Device unpaired successfully');
        _devices.removeWhere((d) => d.deviceId == deviceId);
        if (_selectedDevice?.deviceId == deviceId) {
          _selectedDevice = _devices.isNotEmpty ? _devices.first : null;
        }
        notifyListeners();
        return true;
      } else {
        debugPrint('[WebDeviceService] Unpair failed: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('[WebDeviceService] Unpair error: $e');
      return false;
    }
  }

  /// Select a device for remote install
  void selectDevice(PairedDevice device) {
    _selectedDevice = device;
    notifyListeners();
  }

  /// Send install command to selected device
  Future<bool> sendInstallCommand({
    required String packageName,
    required String appName,
    String? iconUrl,
    String? versionName,
  }) async {
    if (!_authService.isAuthenticated) {
      debugPrint('[WebDeviceService] Not authenticated');
      return false;
    }

    if (_selectedDevice == null) {
      debugPrint('[WebDeviceService] No device selected');
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/install'),
        headers: _authService.getAuthHeaders(),
        body: jsonEncode({
          'deviceId': _selectedDevice!.deviceId,
          'packageName': packageName,
          'appName': appName,
          if (iconUrl != null) 'iconUrl': iconUrl,
          if (versionName != null) 'versionName': versionName,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sent = data['sent'] as bool? ?? false;
        debugPrint(
          '[WebDeviceService] Install command ${sent ? "sent" : "queued"} for $packageName',
        );
        return true;
      } else {
        debugPrint('[WebDeviceService] Install command failed: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('[WebDeviceService] Install command error: $e');
      return false;
    }
  }
}
