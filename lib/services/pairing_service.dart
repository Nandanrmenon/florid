import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Service for managing web-mobile device pairing and communication
class PairingService extends ChangeNotifier {
  static const String _deviceIdKey = 'device_id';
  static const String _sessionIdKey = 'session_id';
  
  // Default server URL - can be configured
  String _serverUrl = 'http://localhost:3000';
  String _wsUrl = 'ws://localhost:3000';
  
  String? _deviceId;
  String? _sessionId;
  String? _pairingCode;
  bool _isPaired = false;
  String? _pairedDeviceName;
  
  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSubscription;
  
  final _installRequestController = StreamController<InstallRequest>.broadcast();
  final _downloadProgressController = StreamController<DownloadProgress>.broadcast();
  
  // Getters
  String? get deviceId => _deviceId;
  String? get sessionId => _sessionId;
  String? get pairingCode => _pairingCode;
  bool get isPaired => _isPaired;
  String? get pairedDeviceName => _pairedDeviceName;
  
  Stream<InstallRequest> get installRequestStream => _installRequestController.stream;
  Stream<DownloadProgress> get downloadProgressStream => _downloadProgressController.stream;
  
  /// Initialize the service
  Future<void> init({String? serverUrl, String? wsUrl}) async {
    if (serverUrl != null) {
      _serverUrl = serverUrl;
    }
    if (wsUrl != null) {
      _wsUrl = wsUrl;
    }
    
    // Load or generate device ID
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString(_deviceIdKey);
    if (_deviceId == null) {
      _deviceId = const Uuid().v4();
      await prefs.setString(_deviceIdKey, _deviceId!);
    }
    
    _sessionId = prefs.getString(_sessionIdKey);
    
    debugPrint('[PairingService] Initialized with device ID: $_deviceId');
  }
  
  /// Configure server URLs
  void configureServer({required String httpUrl, required String wsUrl}) {
    _serverUrl = httpUrl;
    _wsUrl = wsUrl;
    debugPrint('[PairingService] Server configured: $_serverUrl');
  }
  
  /// Generate a pairing code (web side)
  Future<String> generatePairingCode() async {
    try {
      final response = await http.post(
        Uri.parse('$_serverUrl/api/pairing/generate'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _pairingCode = data['pairingCode'];
        _sessionId = data['sessionId'];
        
        // Save session ID
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_sessionIdKey, _sessionId!);
        
        // Connect to WebSocket
        await _connectWebSocket();
        
        // Start polling for pairing status
        _pollPairingStatus();
        
        notifyListeners();
        
        debugPrint('[PairingService] Generated pairing code: $_pairingCode');
        return _pairingCode!;
      } else {
        throw Exception('Failed to generate pairing code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[PairingService] Error generating pairing code: $e');
      rethrow;
    }
  }
  
  /// Join a pairing session (mobile side)
  Future<void> joinPairingSession(String pairingCode, {String? deviceName}) async {
    try {
      final response = await http.post(
        Uri.parse('$_serverUrl/api/pairing/join'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'pairingCode': pairingCode,
          'deviceId': _deviceId,
          'deviceName': deviceName ?? 'Florid Mobile',
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _sessionId = data['sessionId'];
        _isPaired = true;
        
        // Save session ID
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_sessionIdKey, _sessionId!);
        
        // Connect to WebSocket
        await _connectWebSocket();
        
        notifyListeners();
        
        debugPrint('[PairingService] Joined pairing session: $_sessionId');
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
        throw Exception('Failed to join pairing session: $error');
      }
    } catch (e) {
      debugPrint('[PairingService] Error joining pairing session: $e');
      rethrow;
    }
  }
  
  /// Check pairing status
  bool _isPolling = false;
  
  Future<void> _pollPairingStatus() async {
    if (_sessionId == null || _isPolling) return;
    
    _isPolling = true;
    int attempts = 0;
    const maxAttempts = 60; // Poll for 5 minutes (every 5 seconds)
    
    while (attempts < maxAttempts && !_isPaired && _isPolling) {
      await Future.delayed(const Duration(seconds: 5));
      
      // Stop polling if service is being disposed or session is cleared
      if (!_isPolling || _sessionId == null) break;
      
      try {
        final response = await http.get(
          Uri.parse('$_serverUrl/api/pairing/status/$_sessionId'),
        );
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['paired'] == true) {
            _isPaired = true;
            _pairedDeviceName = data['mobileDeviceName'];
            notifyListeners();
            debugPrint('[PairingService] Successfully paired with: $_pairedDeviceName');
            break;
          }
        }
      } catch (e) {
        debugPrint('[PairingService] Error polling pairing status: $e');
      }
      
      attempts++;
    }
    
    _isPolling = false;
  }
  
  /// Connect to WebSocket server
  Future<void> _connectWebSocket() async {
    if (_sessionId == null) return;
    
    try {
      // Close existing connection if any
      await _closeWebSocket();
      
      _wsChannel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      
      // Reset reconnection attempts on successful connection
      _reconnectAttempts = 0;
      
      // Register device
      _wsChannel!.sink.add(jsonEncode({
        'type': 'register',
        'deviceId': _deviceId,
        'sessionId': _sessionId,
      }));
      
      // Listen to messages
      _wsSubscription = _wsChannel!.stream.listen(
        (message) {
          _handleWebSocketMessage(message);
        },
        onError: (error) {
          debugPrint('[PairingService] WebSocket error: $error');
          _reconnectWebSocket();
        },
        onDone: () {
          debugPrint('[PairingService] WebSocket connection closed');
          _reconnectWebSocket();
        },
      );
      
      debugPrint('[PairingService] WebSocket connected');
    } catch (e) {
      debugPrint('[PairingService] Error connecting to WebSocket: $e');
    }
  }
  
  /// Reconnect WebSocket after a delay
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  
  Future<void> _reconnectWebSocket() async {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('[PairingService] Max reconnection attempts reached');
      return;
    }
    
    _reconnectAttempts++;
    final delay = Duration(seconds: 5 * _reconnectAttempts); // Exponential backoff
    await Future.delayed(delay);
    
    if (_sessionId != null) {
      await _connectWebSocket();
    }
  }
  
  /// Close WebSocket connection
  Future<void> _closeWebSocket() async {
    await _wsSubscription?.cancel();
    await _wsChannel?.sink.close();
    _wsSubscription = null;
    _wsChannel = null;
  }
  
  /// Handle incoming WebSocket messages
  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      final type = data['type'];
      
      debugPrint('[PairingService] Received message: $type');
      
      switch (type) {
        case 'registered':
          debugPrint('[PairingService] Device registered on server');
          break;
          
        case 'paired':
          _isPaired = true;
          _pairedDeviceName = data['deviceName'];
          notifyListeners();
          debugPrint('[PairingService] Paired with: $_pairedDeviceName');
          break;
          
        case 'install_request':
          final request = InstallRequest(
            packageName: data['packageName'],
            appName: data['appName'],
            repositoryUrl: data['repositoryUrl'],
            timestamp: data['timestamp'],
          );
          _installRequestController.add(request);
          debugPrint('[PairingService] Received install request: ${request.packageName}');
          break;
          
        case 'download_progress':
          final progress = DownloadProgress(
            packageName: data['packageName'],
            progress: data['progress'],
            status: data['status'],
          );
          _downloadProgressController.add(progress);
          break;
          
        case 'install_progress':
          // Handle install progress if needed
          break;
          
        case 'pong':
          // Keep-alive response
          break;
      }
    } catch (e) {
      debugPrint('[PairingService] Error handling WebSocket message: $e');
    }
  }
  
  /// Send install request to mobile device (web side)
  Future<void> sendInstallRequest({
    required String packageName,
    required String appName,
    String? repositoryUrl,
  }) async {
    if (_sessionId == null) {
      throw Exception('No active session');
    }
    
    if (!_isPaired) {
      throw Exception('Not paired with a mobile device');
    }
    
    try {
      final response = await http.post(
        Uri.parse('$_serverUrl/api/install/request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sessionId': _sessionId,
          'packageName': packageName,
          'appName': appName,
          'repositoryUrl': repositoryUrl ?? 'https://f-droid.org/repo',
        }),
      );
      
      if (response.statusCode == 200) {
        debugPrint('[PairingService] Install request sent for: $packageName');
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
        throw Exception('Failed to send install request: $error');
      }
    } catch (e) {
      debugPrint('[PairingService] Error sending install request: $e');
      rethrow;
    }
  }
  
  /// Send download progress update (mobile side)
  Future<void> sendDownloadProgress({
    required String packageName,
    required double progress,
    required String status,
  }) async {
    if (_wsChannel == null) return;
    
    try {
      _wsChannel!.sink.add(jsonEncode({
        'type': 'download_progress',
        'packageName': packageName,
        'progress': progress,
        'status': status,
      }));
    } catch (e) {
      debugPrint('[PairingService] Error sending download progress: $e');
    }
  }
  
  /// Send install progress update (mobile side)
  Future<void> sendInstallProgress({
    required String packageName,
    required String status,
  }) async {
    if (_wsChannel == null) return;
    
    try {
      _wsChannel!.sink.add(jsonEncode({
        'type': 'install_progress',
        'packageName': packageName,
        'status': status,
      }));
    } catch (e) {
      debugPrint('[PairingService] Error sending install progress: $e');
    }
  }
  
  /// Unpair devices
  Future<void> unpair() async {
    _isPaired = false;
    _pairedDeviceName = null;
    _pairingCode = null;
    _sessionId = null;
    _isPolling = false; // Stop polling
    
    await _closeWebSocket();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionIdKey);
    
    notifyListeners();
    
    debugPrint('[PairingService] Unpaired');
  }
  
  @override
  void dispose() {
    _isPolling = false; // Stop polling
    _closeWebSocket();
    _installRequestController.close();
    _downloadProgressController.close();
    super.dispose();
  }
}

/// Install request data
class InstallRequest {
  final String packageName;
  final String appName;
  final String repositoryUrl;
  final int timestamp;
  
  InstallRequest({
    required this.packageName,
    required this.appName,
    required this.repositoryUrl,
    required this.timestamp,
  });
}

/// Download progress data
class DownloadProgress {
  final String packageName;
  final double progress;
  final String status;
  
  DownloadProgress({
    required this.packageName,
    required this.progress,
    required this.status,
  });
}
