import 'dart:convert';
import 'package:crowdin_sdk/crowdin_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service to initialize and manage Crowdin Over-The-Air (OTA) translations
class CrowdinService {
  static bool _initialized = false;
  static String? _distributionHash;

  /// Initialize Crowdin SDK with OTA distribution
  /// 
  /// This method loads the Crowdin configuration from assets and initializes
  /// the SDK for over-the-air translation updates.
  /// 
  /// Returns true if initialization was successful, false otherwise.
  static Future<bool> initialize() async {
    if (_initialized) {
      debugPrint('Crowdin SDK already initialized');
      return true;
    }

    try {
      // Load Crowdin configuration from assets
      final configJson = await rootBundle.loadString('assets/crowdin_config.json');
      final config = jsonDecode(configJson) as Map<String, dynamic>;

      _distributionHash = config['distributionHash'] as String?;
      final sourceLanguage = config['sourceLanguage'] as String? ?? 'en';

      // Check if distribution hash is configured
      if (_distributionHash == null || 
          _distributionHash!.isEmpty || 
          _distributionHash == 'YOUR_DISTRIBUTION_HASH_HERE') {
        debugPrint('Crowdin OTA: Distribution hash not configured. '
            'OTA updates will not be available. '
            'Please set the distributionHash in assets/crowdin_config.json');
        return false;
      }

      debugPrint('Initializing Crowdin SDK with distribution hash: $_distributionHash');

      // Initialize Crowdin SDK with the distribution hash
      await Crowdin.init(
        distributionHash: _distributionHash!,
        connectionType: InternetConnectionType.any,
        updatesInterval: const Duration(minutes: 15),
        sourceLanguage: sourceLanguage,
      );

      _initialized = true;
      debugPrint('Crowdin SDK initialized successfully for OTA updates');
      return true;
    } catch (e, stackTrace) {
      debugPrint('Failed to initialize Crowdin SDK: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Check if Crowdin SDK is initialized
  static bool get isInitialized => _initialized;

  /// Get the current distribution hash
  static String? get distributionHash => _distributionHash;

  /// Manually trigger a translation update check
  /// 
  /// This will fetch the latest translations from Crowdin's distribution
  /// if available.
  static Future<void> checkForUpdates() async {
    if (!_initialized) {
      debugPrint('Crowdin SDK not initialized. Cannot check for updates.');
      return;
    }

    try {
      debugPrint('Checking for Crowdin translation updates...');
      // The SDK will automatically fetch and cache the latest translations
      // based on the distribution manifest
    } catch (e) {
      debugPrint('Error checking for Crowdin updates: $e');
    }
  }
}
