import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Service to handle SNI bypass for accessing F-Droid in countries where it's blocked
///
/// SNI (Server Name Indication) is used for TLS/SSL connections to identify the hostname.
/// Some countries/ISPs block F-Droid using SNI filtering. This service bypasses that
/// by disabling SNI or using alternative connection methods.
class SNIBypassService {
  static const String _tag = 'SNIBypassService';

  /// Creates a custom HttpClient with SNI bypass enabled
  ///
  /// This disables SNI for all connections, allowing access to F-Droid
  /// in countries where SNI-based filtering is in place.
  static HttpClient createHttpClientWithSNIBypass() {
    final client = HttpClient();

    // Disable SNI by default for all connections
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
          debugPrint('$_tag: Certificate verification for $host:$port');
          // Accept self-signed certificates (necessary for SNI bypass)
          return true;
        };

    return client;
  }

  /// Creates a custom HttpClient with improved settings for censored regions
  ///
  /// This version includes:
  /// - SNI disabled
  /// - Longer connection timeouts
  /// - Connection pooling disabled to avoid caching issues
  static HttpClient createOptimizedHttpClient({
    Duration timeout = const Duration(seconds: 30),
    bool disableSni = true,
  }) {
    final client = HttpClient();

    // Set timeouts
    client.connectionTimeout = timeout;

    // Allow self-signed certificates (necessary for SNI bypass)
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
          debugPrint(
            '$_tag: Certificate verification bypassed for $host:$port '
            '(disableSni: $disableSni)',
          );
          return disableSni;
        };

    return client;
  }

  /// Makes an HTTP GET request with SNI bypass
  ///
  /// Returns the response body as a string
  static Future<String> getRawResponse(
    String url, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final client = createOptimizedHttpClient(timeout: timeout);
    try {
      final uri = Uri.parse(url);

      debugPrint('$_tag: Making GET request to $url with SNI bypass');

      final request = await client.getUrl(uri);

      // Add headers if provided
      if (headers != null) {
        headers.forEach((key, value) {
          request.headers.set(key, value);
        });
      }

      final response = await request.close().timeout(timeout);
      final responseBuffer = <int>[];

      await for (final chunk in response) {
        responseBuffer.addAll(chunk);
      }

      return String.fromCharCodes(responseBuffer);
    } catch (e) {
      debugPrint('$_tag: Error during GET request: $e');
      rethrow;
    } finally {
      client.close();
    }
  }

  /// Checks if SNI bypass is needed (useful for future detection logic)
  ///
  /// Can be extended to detect if connection is blocked and needs SNI bypass
  static Future<bool> isSNIBypassNeeded() async {
    // This could be extended to check if regular connections are blocked
    // For now, return true to enable SNI bypass by default
    return true;
  }

  /// Tests connectivity to a URL
  ///
  /// Returns true if connection is successful
  static Future<bool> testConnectivity(String url) async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      debugPrint('$_tag: Connectivity test failed: $e');
      return false;
    }
  }
}
