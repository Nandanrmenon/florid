import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Message types for web-mobile communication
enum MessageType {
  pairRequest,
  pairResponse,
  installRequest,
  installStatus,
  heartbeat,
}

/// Message data structure
class PairingMessage {
  final MessageType type;
  final String? deviceId;
  final String? pairingCode;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  PairingMessage({
    required this.type,
    this.deviceId,
    this.pairingCode,
    this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'deviceId': deviceId,
    'pairingCode': pairingCode,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
  };

  factory PairingMessage.fromJson(Map<String, dynamic> json) {
    return PairingMessage(
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.heartbeat,
      ),
      deviceId: json['deviceId'] as String?,
      pairingCode: json['pairingCode'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// Service for web-mobile pairing and communication
/// Uses a simple HTTP polling mechanism (no external services required)
class PairingService extends ChangeNotifier {
  static const String _storageKey = 'florid_pairing_data';
  static const Duration _pollInterval = Duration(seconds: 3);
  static const Duration _messageExpiry = Duration(minutes: 5);

  // Shared static message queue (for local testing across web and mobile)
  // For production, replace with actual server backend
  static final Map<String, List<PairingMessage>> _sharedMessageQueue = {};

  String? _deviceId;
  String? _pairingCode;
  bool _isPaired = false;
  String? _pairedDeviceId;
  Timer? _pollTimer;

  String? get deviceId => _deviceId;
  String? get pairingCode => _pairingCode;
  bool get isPaired => _isPaired;
  String? get pairedDeviceId => _pairedDeviceId;

  /// Initialize the pairing service
  Future<void> init() async {
    _deviceId = _generateDeviceId();
    await _loadPairingData();
  }

  /// Generate a unique device ID
  String _generateDeviceId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes).substring(0, 22);
  }

  /// Generate a 6-digit pairing code
  String _generatePairingCode() {
    final random = Random.secure();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// Load pairing data from storage
  Future<void> _loadPairingData() async {
    // TODO: Implement actual storage using shared_preferences
    // For now, just initialize empty
    debugPrint('[PairingService] Device ID: $_deviceId');
  }

  /// Start pairing process (mobile side)
  Future<String> startPairing() async {
    _pairingCode = _generatePairingCode();
    _isPaired = false;
    _pairedDeviceId = null;

    debugPrint('[PairingService] Started pairing with code: $_pairingCode');

    // Start polling for pairing requests
    _startPolling();

    notifyListeners();
    return _pairingCode!;
  }

  /// Pair with a device using pairing code (web side)
  Future<bool> pairWithCode(String code) async {
    try {
      debugPrint('[PairingService] Web: Attempting to pair with code: $code');

      final message = PairingMessage(
        type: MessageType.pairRequest,
        deviceId: _deviceId,
        pairingCode: code,
      );

      // In a real implementation, this would send to a server
      // For now, we'll use local message queue
      _enqueueMessage(code, message);

      // Wait for response
      final response = await _waitForPairingResponse(code);
      if (response != null) {
        _isPaired = true;
        _pairedDeviceId = response.deviceId;
        _pairingCode = code;
        await _savePairingData();
        _startPolling();
        notifyListeners();
        debugPrint(
          '[PairingService] Web: Successfully paired with device: ${response.deviceId}',
        );
        return true;
      }
      debugPrint(
        '[PairingService] Web: Pairing failed - no response from device',
      );
      return false;
    } catch (e) {
      debugPrint('[PairingService] Error pairing: $e');
      return false;
    }
  }

  /// Send install request from web to mobile
  Future<bool> sendInstallRequest({
    required String packageName,
    required String appName,
    String? versionName,
  }) async {
    if (!_isPaired || _pairingCode == null) {
      debugPrint('[PairingService] Not paired, cannot send install request');
      return false;
    }

    try {
      final message = PairingMessage(
        type: MessageType.installRequest,
        deviceId: _deviceId,
        pairingCode: _pairingCode,
        data: {
          'packageName': packageName,
          'appName': appName,
          'versionName': versionName,
        },
      );

      _enqueueMessage(_pairingCode!, message);
      debugPrint('[PairingService] Sent install request for $packageName');
      return true;
    } catch (e) {
      debugPrint('[PairingService] Error sending install request: $e');
      return false;
    }
  }

  /// Check for pairing requests (mobile side)
  Future<PairingMessage?> checkForPairingRequest() async {
    if (_pairingCode == null) return null;

    try {
      final messages = _getMessages(_pairingCode!);

      if (messages.isNotEmpty) {
        debugPrint(
          '[PairingService] Mobile: Found ${messages.length} messages for code $_pairingCode',
        );
        for (var msg in messages) {
          debugPrint(
            '[PairingService] Mobile: Message type: ${msg.type.name}, from device: ${msg.deviceId}',
          );
        }
      }

      final pairRequest = messages
          .where((m) => m.type == MessageType.pairRequest)
          .where(
            (m) => m.timestamp.isAfter(DateTime.now().subtract(_messageExpiry)),
          )
          .firstOrNull;

      if (pairRequest != null) {
        debugPrint(
          '[PairingService] Mobile: Received pairing request from web device: ${pairRequest.deviceId}',
        );

        // Send response
        final response = PairingMessage(
          type: MessageType.pairResponse,
          deviceId: _deviceId,
          pairingCode: _pairingCode,
        );
        _enqueueMessage(_pairingCode!, response);

        // Mark as paired
        _isPaired = true;
        _pairedDeviceId = pairRequest.deviceId;
        await _savePairingData();
        notifyListeners();

        return pairRequest;
      }
      return null;
    } catch (e) {
      debugPrint('[PairingService] Error checking for pairing request: $e');
      return null;
    }
  }

  /// Check for install requests (mobile side)
  Future<PairingMessage?> checkForInstallRequest() async {
    if (_pairingCode == null || !_isPaired) return null;

    try {
      final messages = _getMessages(_pairingCode!);
      final installRequest = messages
          .where((m) => m.type == MessageType.installRequest)
          .where(
            (m) => m.timestamp.isAfter(DateTime.now().subtract(_messageExpiry)),
          )
          .where((m) => m.deviceId == _pairedDeviceId)
          .firstOrNull;

      // Mark message as consumed by removing it from queue
      if (installRequest != null && _sharedMessageQueue.containsKey(_pairingCode!)) {
        _sharedMessageQueue[_pairingCode!]!.remove(installRequest);
      }

      return installRequest;
    } catch (e) {
      debugPrint('[PairingService] Error checking for install request: $e');
      return null;
    }
  }

  /// Send install status update (mobile side)
  Future<void> sendInstallStatus({
    required String packageName,
    required String status,
    double? progress,
  }) async {
    if (!_isPaired || _pairingCode == null) return;

    try {
      final message = PairingMessage(
        type: MessageType.installStatus,
        deviceId: _deviceId,
        pairingCode: _pairingCode,
        data: {
          'packageName': packageName,
          'status': status,
          'progress': progress,
        },
      );

      _enqueueMessage(_pairingCode!, message);
    } catch (e) {
      debugPrint('[PairingService] Error sending install status: $e');
    }
  }

  /// Start polling for messages
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      if (_isPaired) {
        // Check for install requests on mobile
        if (!kIsWeb) {
          await checkForInstallRequest();
        }
      } else if (_pairingCode != null) {
        // Check for pairing requests on mobile
        if (!kIsWeb) {
          await checkForPairingRequest();
        }
      }
    });
  }

  /// Stop polling
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Stop pairing process
  void stopPairing() {
    _pairingCode = null;
    stopPolling();
    notifyListeners();
  }

  /// Unpair devices
  Future<void> unpair() async {
    _isPaired = false;
    _pairedDeviceId = null;
    _pairingCode = null;
    stopPolling();
    await _savePairingData();
    notifyListeners();
  }

  // Local message queue methods (replace with actual server API in production)
  void _enqueueMessage(String code, PairingMessage message) {
    if (!_sharedMessageQueue.containsKey(code)) {
      _sharedMessageQueue[code] = [];
    }
    _sharedMessageQueue[code]!.add(message);

    debugPrint(
      '[PairingService] Enqueued message for code $code: ${message.type.name}',
    );

    // Clean up old messages
    _sharedMessageQueue[code] = _sharedMessageQueue[code]!
        .where(
          (m) => m.timestamp.isAfter(DateTime.now().subtract(_messageExpiry)),
        )
        .toList();
  }

  List<PairingMessage> _getMessages(String code) {
    return _sharedMessageQueue[code] ?? [];
  }

  Future<PairingMessage?> _waitForPairingResponse(String code) async {
    final timeout = DateTime.now().add(const Duration(seconds: 30));
    int attemptCount = 0;

    while (DateTime.now().isBefore(timeout)) {
      final messages = _getMessages(code);

      debugPrint(
        '[PairingService] Waiting for pairing response (attempt ${++attemptCount}), found ${messages.length} messages',
      );

      final response = messages
          .where((m) => m.type == MessageType.pairResponse)
          .where(
            (m) => m.timestamp.isAfter(
              DateTime.now().subtract(const Duration(seconds: 30)),
            ),
          )
          .firstOrNull;

      if (response != null) {
        debugPrint(
          '[PairingService] Received pairing response from device: ${response.deviceId}',
        );
        return response;
      }

      await Future.delayed(const Duration(milliseconds: 500));
    }

    debugPrint(
      '[PairingService] Timeout waiting for pairing response after 30 seconds',
    );
    return null;
  }

  Future<void> _savePairingData() async {
    // TODO: Implement actual storage using shared_preferences
    debugPrint('[PairingService] Saving pairing data');
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
