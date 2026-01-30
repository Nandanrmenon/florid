import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Service for managing web pairing and remote install requests
/// Uses a self-hosted backend server (no Google services)
class WebPairingService {
  static final WebPairingService _instance = WebPairingService._internal();
  
  factory WebPairingService() {
    return _instance;
  }
  
  WebPairingService._internal();
  
  String? _deviceId;
  String? _pairingCode;
  DateTime? _pairingExpiry;
  Timer? _pollTimer;
  WebSocketChannel? _wsChannel;
  
  // Backend server URL (can be configured by user or use default)
  String _serverUrl = 'https://florid-web-store.example.com'; // Replace with actual server
  
  static const String _deviceIdKey = 'device_id';
  static const String _pairingCodeKey = 'pairing_code';
  static const String _pairingExpiryKey = 'pairing_expiry';
  static const String _webPairingEnabledKey = 'web_pairing_enabled';
  static const String _serverUrlKey = 'server_url';
  
  // Callback for remote install requests
  Function(String packageName, String versionName)? onRemoteInstallRequest;
  
  /// Initialize the service
  Future<void> initialize() async {
    try {
      // Load saved data
      await _loadSettings();
      
      // Generate or load device ID
      await _ensureDeviceId();
      
      // Start polling if enabled
      final enabled = await isWebPairingEnabled();
      if (enabled) {
        _startPolling();
      }
      
    } catch (e) {
      debugPrint('[WebPairingService] Initialization error: $e');
    }
  }
  
  /// Ensure device has a unique ID
  Future<void> _ensureDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString(_deviceIdKey);
    
    if (_deviceId == null) {
      // Generate new device ID
      final random = Random.secure();
      final bytes = List<int>.generate(16, (_) => random.nextInt(256));
      _deviceId = base64Url.encode(bytes).replaceAll('=', '');
      await prefs.setString(_deviceIdKey, _deviceId!);
    }
    
    debugPrint('[WebPairingService] Device ID: $_deviceId');
  }
  
  /// Start polling for install requests
  void _startPolling() {
    _stopPolling();
    
    // Poll every 5 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkForInstallRequests();
    });
    
    debugPrint('[WebPairingService] Started polling for install requests');
  }
  
  /// Stop polling
  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _wsChannel?.sink.close();
    _wsChannel = null;
  }
  
  /// Check for pending install requests
  Future<void> _checkForInstallRequests() async {
    try {
      if (_deviceId == null) return;
      
      final response = await http.get(
        Uri.parse('$_serverUrl/api/device/$_deviceId/requests'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final requests = data['requests'] as List?;
        
        if (requests != null && requests.isNotEmpty) {
          for (final request in requests) {
            final requestMap = request as Map<String, dynamic>;
            final packageName = requestMap['package_name'] as String?;
            final versionName = requestMap['version_name'] as String?;
            final requestId = requestMap['id'] as String?;
            
            if (packageName != null && versionName != null) {
              debugPrint('[WebPairingService] Install request: $packageName v$versionName');
              
              // Call callback
              onRemoteInstallRequest?.call(packageName, versionName);
              
              // Acknowledge request
              if (requestId != null) {
                await _acknowledgeRequest(requestId);
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[WebPairingService] Error checking for requests: $e');
    }
  }
  
  /// Acknowledge a processed install request
  Future<void> _acknowledgeRequest(String requestId) async {
    try {
      await http.delete(
        Uri.parse('$_serverUrl/api/device/$_deviceId/requests/$requestId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('[WebPairingService] Error acknowledging request: $e');
    }
  }
  
  /// Generate a new pairing code
  Future<String> generatePairingCode() async {
    // Generate 6-digit pairing code
    final random = Random.secure();
    final code = random.nextInt(900000) + 100000; // 100000-999999
    _pairingCode = code.toString();
    _pairingExpiry = DateTime.now().add(const Duration(minutes: 15));
    
    await _savePairingData();
    
    // Register pairing code with server
    await _registerPairingCode();
    
    debugPrint('[WebPairingService] Generated pairing code: $_pairingCode (expires at $_pairingExpiry)');
    return _pairingCode!;
  }
  
  /// Register pairing code with server
  Future<void> _registerPairingCode() async {
    try {
      if (_deviceId == null || _pairingCode == null) return;
      
      final response = await http.post(
        Uri.parse('$_serverUrl/api/pair'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'device_id': _deviceId,
          'pairing_code': _pairingCode,
          'expires_at': _pairingExpiry?.toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        debugPrint('[WebPairingService] Pairing code registered with server');
      } else {
        debugPrint('[WebPairingService] Failed to register pairing code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[WebPairingService] Error registering pairing code: $e');
    }
  }
  
  /// Get the current pairing code if valid
  String? getPairingCode() {
    if (_pairingCode != null && _pairingExpiry != null) {
      if (DateTime.now().isBefore(_pairingExpiry!)) {
        return _pairingCode;
      } else {
        // Expired
        _pairingCode = null;
        _pairingExpiry = null;
        _savePairingData();
      }
    }
    return null;
  }
  
  /// Get the device ID for pairing
  String? getDeviceId() => _deviceId;
  
  /// Get server URL
  String getServerUrl() => _serverUrl;
  
  /// Set custom server URL
  Future<void> setServerUrl(String url) async {
    _serverUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverUrlKey, url);
  }
  
  /// Check if web pairing is enabled
  Future<bool> isWebPairingEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_webPairingEnabledKey) ?? false;
  }
  
  /// Enable or disable web pairing
  Future<void> setWebPairingEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_webPairingEnabledKey, enabled);
    
    if (enabled) {
      _startPolling();
    } else {
      _stopPolling();
      // Clear pairing data when disabled
      _pairingCode = null;
      _pairingExpiry = null;
      await _savePairingData();
    }
  }
  
  /// Save pairing data to shared preferences
  Future<void> _savePairingData() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (_pairingCode != null) {
      await prefs.setString(_pairingCodeKey, _pairingCode!);
    } else {
      await prefs.remove(_pairingCodeKey);
    }
    
    if (_pairingExpiry != null) {
      await prefs.setString(_pairingExpiryKey, _pairingExpiry!.toIso8601String());
    } else {
      await prefs.remove(_pairingExpiryKey);
    }
  }
  
  /// Load settings from shared preferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    _deviceId = prefs.getString(_deviceIdKey);
    _pairingCode = prefs.getString(_pairingCodeKey);
    
    final serverUrl = prefs.getString(_serverUrlKey);
    if (serverUrl != null) {
      _serverUrl = serverUrl;
    }
    
    final expiryString = prefs.getString(_pairingExpiryKey);
    if (expiryString != null) {
      _pairingExpiry = DateTime.tryParse(expiryString);
      
      // Check if expired
      if (_pairingExpiry != null && DateTime.now().isAfter(_pairingExpiry!)) {
        _pairingCode = null;
        _pairingExpiry = null;
        await _savePairingData();
      }
    }
  }
  
  /// Get pairing data as JSON for QR code
  Map<String, dynamic> getPairingData() {
    return {
      'device_id': _deviceId,
      'pairing_code': getPairingCode(),
      'server_url': _serverUrl,
      'app_name': 'Florid',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  /// Get pairing data as JSON string for QR code
  String getPairingDataJson() {
    return jsonEncode(getPairingData());
  }
  
  /// Dispose resources
  void dispose() {
    _stopPolling();
  }
}
