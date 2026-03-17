import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UsageAnalyticsService {
  static final Uri _endpoint = Uri.parse(
    'https://florid.knoxxbox.in/v1/app_open.php',
  );

  static const String _installIdKey = 'usage_install_id';
  static const String _lastPingDayKey = 'usage_last_ping_day_utc';
  static const String _optOutKey = 'usage_telemetry_opt_out';

  Future<bool> isOptedOut() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_optOutKey) ?? false;
  }

  Future<void> setOptOut(bool optOut) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_optOutKey, optOut);
  }

  Future<void> trackAppOpen() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if user has opted out
      final isOptedOut = prefs.getBool(_optOutKey) ?? false;
      if (isOptedOut) {
        print('[Analytics] User has opted out of telemetry');
        return;
      }

      final today = _utcDayKey(DateTime.now().toUtc());
      final lastDay = prefs.getString(_lastPingDayKey);
      print('[Analytics] Last ping day: $lastDay, Today: $today');

      // Allow forcing analytics for testing
      const forceAnalytics =
          String.fromEnvironment('FLORID_DEBUG_FORCE_ANALYTICS') == 'true';
      if (lastDay == today && !forceAnalytics) {
        print('[Analytics] Already pinged today, skipping');
        return;
      }
      print('[Analytics] Proceeding to send analytics ping');

      final installId = await _getOrCreateInstallId(prefs);

      final info = await PackageInfo.fromPlatform();
      final appVersion = '${info.version}+${info.buildNumber}';

      final payload = jsonEncode({
        'install_id': installId,
        'app_version': appVersion,
      });

      final resp = await http.post(
        _endpoint,
        headers: {'Content-Type': 'application/json'},
        body: payload,
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        await prefs.setString(_lastPingDayKey, today);
      } else {
        print('[Analytics] Request failed with status: ${resp.statusCode}');
        print('[Analytics] Response: ${resp.body}');
      }
    } catch (e, st) {
      // Log the error but don't crash the app
      print('[Analytics] Error tracking app open: $e');
      print('[Analytics] Stack trace: $st');
    }
  }

  Future<String> _getOrCreateInstallId(SharedPreferences prefs) async {
    final existing = prefs.getString(_installIdKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final id = _randomHexId(16); // 128-bit
    await prefs.setString(_installIdKey, id);
    return id;
  }

  String _utcDayKey(DateTime utc) {
    final y = utc.year.toString().padLeft(4, '0');
    final m = utc.month.toString().padLeft(2, '0');
    final d = utc.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _randomHexId(int bytesLen) {
    final rnd = Random.secure();
    final bytes = List<int>.generate(bytesLen, (_) => rnd.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
