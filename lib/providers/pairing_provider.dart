import 'package:flutter/foundation.dart';
import '../services/pairing_service.dart';

class PairingProvider extends ChangeNotifier {
  final PairingService _pairingService;

  PairingProvider(this._pairingService) {
    _init();
  }

  String? _currentPairingCode;
  bool _isLoading = false;
  String? _errorMessage;

  String? get currentPairingCode => _currentPairingCode;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isPaired => _pairingService.isPaired;
  String? get deviceId => _pairingService.deviceId;

  Future<void> _init() async {
    await _pairingService.init();
    notifyListeners();
  }

  /// Start pairing (mobile side)
  Future<String?> startPairing() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentPairingCode = await _pairingService.startPairing();
      _isLoading = false;
      notifyListeners();
      return _currentPairingCode;
    } catch (e) {
      _errorMessage = 'Failed to start pairing: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Pair using code (web side)
  Future<bool> pairWithCode(String code) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _pairingService.pairWithCode(code);
      _isLoading = false;
      if (success) {
        _currentPairingCode = code;
        _errorMessage = null;
      } else {
        // Provide helpful error message based on platform
        if (kIsWeb) {
          _errorMessage = 
              'Failed to pair. Make sure:\n'
              '• The mobile app is running\n'
              '• Mobile has started pairing with code: $code\n'
              '• For same-browser testing: Open mobile in another tab\n'
              '• For cross-device: A server backend is required (see docs)';
        } else {
          _errorMessage = 'Failed to pair. Please check the code and try again.';
        }
      }
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Failed to pair: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Stop pairing
  void stopPairing() {
    _pairingService.stopPairing();
    _currentPairingCode = null;
    notifyListeners();
  }

  /// Unpair
  Future<void> unpair() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _pairingService.unpair();
      _currentPairingCode = null;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to unpair: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Send install request (web side)
  Future<bool> sendInstallRequest({
    required String packageName,
    required String appName,
    String? versionName,
  }) async {
    if (!_pairingService.isPaired) {
      _errorMessage = 'Not paired with any device';
      notifyListeners();
      return false;
    }

    try {
      final success = await _pairingService.sendInstallRequest(
        packageName: packageName,
        appName: appName,
        versionName: versionName,
      );
      if (!success) {
        _errorMessage = 'Failed to send install request';
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = 'Failed to send install request: $e';
      notifyListeners();
      return false;
    }
  }

  /// Check for install requests (mobile side)
  Future<PairingMessage?> checkForInstallRequest() async {
    return await _pairingService.checkForInstallRequest();
  }

  /// Send install status (mobile side)
  Future<void> sendInstallStatus({
    required String packageName,
    required String status,
    double? progress,
  }) async {
    await _pairingService.sendInstallStatus(
      packageName: packageName,
      status: status,
      progress: progress,
    );
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _pairingService.dispose();
    super.dispose();
  }
}
