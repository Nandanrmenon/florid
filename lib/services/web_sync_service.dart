import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/install_command.dart';
import '../providers/download_provider.dart';
import '../providers/settings_provider.dart';

/// Service for managing WebSocket connection to backend server
class WebSyncService {
  final SettingsProvider _settingsProvider;
  WebSocketChannel? _channel;
  StreamController<InstallCommand>? _installCommandsController;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  bool _isConnecting = false;
  bool _intentionalDisconnect = false;

  // Backend WebSocket URL - TODO: Update with actual backend URL
  static const String _websocketUrl = 'wss://florid-backend.example.com/ws';

  WebSyncService(this._settingsProvider);

  /// Stream of install commands received from web/other devices
  Stream<InstallCommand> get installCommands {
    _installCommandsController ??=
        StreamController<InstallCommand>.broadcast();
    return _installCommandsController!.stream;
  }

  /// Check if currently connected
  bool get isConnected => _channel != null;

  /// Connect to the backend WebSocket server
  Future<void> connect() async {
    if (_isConnecting || isConnected) {
      debugPrint('[WebSyncService] Already connected or connecting');
      return;
    }

    if (!_settingsProvider.webSyncEnabled) {
      debugPrint('[WebSyncService] Web sync not enabled');
      return;
    }

    final deviceId = _settingsProvider.deviceId;
    final authToken = _settingsProvider.authToken;

    if (deviceId == null || authToken == null) {
      debugPrint('[WebSyncService] Missing device ID or auth token');
      return;
    }

    _isConnecting = true;
    _intentionalDisconnect = false;

    try {
      debugPrint('[WebSyncService] Connecting to $_websocketUrl');

      // Add authentication parameters to WebSocket URL
      final uri = Uri.parse(
        '$_websocketUrl?deviceId=$deviceId&authToken=$authToken',
      );

      _channel = WebSocketChannel.connect(uri);

      // Listen for messages
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDisconnect,
        cancelOnError: false,
      );

      // Send authentication message
      _sendMessage({
        'type': 'authenticate',
        'deviceId': deviceId,
        'authToken': authToken,
      });

      // Start heartbeat to keep connection alive
      _startHeartbeat();

      _isConnecting = false;
      debugPrint('[WebSyncService] Connected successfully');
    } catch (e) {
      _isConnecting = false;
      debugPrint('[WebSyncService] Connection error: $e');
      _scheduleReconnect();
    }
  }

  /// Disconnect from the backend
  void disconnect() {
    _intentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    debugPrint('[WebSyncService] Disconnected');
  }

  /// Handle incoming WebSocket messages
  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final type = data['type'] as String?;

      debugPrint('[WebSyncService] Received message: $type');

      switch (type) {
        case 'install-request':
          _handleInstallRequest(data);
          break;
        case 'pong':
          // Heartbeat response
          break;
        case 'authenticated':
          debugPrint('[WebSyncService] Authentication successful');
          break;
        case 'error':
          debugPrint('[WebSyncService] Server error: ${data['message']}');
          break;
        default:
          debugPrint('[WebSyncService] Unknown message type: $type');
      }
    } catch (e) {
      debugPrint('[WebSyncService] Error parsing message: $e');
    }
  }

  /// Handle install request from web
  void _handleInstallRequest(Map<String, dynamic> data) {
    try {
      final command = InstallCommand.fromJson(data);
      _installCommandsController?.add(command);
      debugPrint(
        '[WebSyncService] Received install request: ${command.packageName}',
      );

      // Send acknowledgment
      _sendMessage({
        'type': 'install-ack',
        'packageName': command.packageName,
        'timestamp': command.timestamp,
      });
    } catch (e) {
      debugPrint('[WebSyncService] Error handling install request: $e');
    }
  }

  /// Send install status update to backend
  Future<void> sendInstallStatus({
    required String packageName,
    required DownloadStatus status,
    required double progress,
    String? error,
  }) async {
    if (!isConnected) {
      debugPrint('[WebSyncService] Not connected, cannot send status');
      return;
    }

    _sendMessage({
      'type': 'install-status-update',
      'packageName': packageName,
      'status': status.name,
      'progress': progress,
      'timestamp': DateTime.now().toIso8601String(),
      if (error != null) 'error': error,
    });
  }

  /// Send a message through WebSocket
  void _sendMessage(Map<String, dynamic> message) {
    if (_channel == null) return;

    try {
      _channel!.sink.add(jsonEncode(message));
    } catch (e) {
      debugPrint('[WebSyncService] Error sending message: $e');
    }
  }

  /// Handle WebSocket errors
  void _onError(dynamic error) {
    debugPrint('[WebSyncService] WebSocket error: $error');
    _scheduleReconnect();
  }

  /// Handle WebSocket disconnection
  void _onDisconnect() {
    debugPrint('[WebSyncService] WebSocket disconnected');
    _channel = null;
    _heartbeatTimer?.cancel();

    if (!_intentionalDisconnect) {
      _scheduleReconnect();
    }
  }

  /// Schedule automatic reconnection
  void _scheduleReconnect() {
    if (_intentionalDisconnect || _reconnectTimer != null) return;

    debugPrint('[WebSyncService] Scheduling reconnect in 10 seconds');
    _reconnectTimer = Timer(const Duration(seconds: 10), () {
      _reconnectTimer = null;
      connect();
    });
  }

  /// Start heartbeat to keep connection alive
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!isConnected) {
        timer.cancel();
        return;
      }
      _sendMessage({'type': 'ping'});
    });
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _installCommandsController?.close();
    _installCommandsController = null;
  }
}
