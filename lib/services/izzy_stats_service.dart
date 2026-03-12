import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class IzzyStats {
  final int? lastDay;
  final int? last30Days;
  final int? last365Days;

  const IzzyStats({this.lastDay, this.last30Days, this.last365Days});

  bool get hasAny =>
      lastDay != null || last30Days != null || last365Days != null;
}

class IzzyStatsService {
  static const String _baseUrl =
      'https://dlstats.izzyondroid.org/iod-stats-collector/stats';

  final http.Client _client;
  final Map<String, Map<String, int>> _cache = {};

  IzzyStatsService({http.Client? client}) : _client = client ?? http.Client();

  /// Returns monthly rolling download counts keyed by package name.
  Future<Map<String, int>> fetchMonthlyStats() async {
    return await _loadStats('basic/monthly/rolling.json');
  }

  /// Returns yearly rolling download counts keyed by package name.
  Future<Map<String, int>> fetchYearlyStats() async {
    return await _loadStats('basic/yearly/rolling.json');
  }

  /// Fetches download stats for a package from the IzzyOnDroid mirrors.
  /// Uses three rolling windows: last day, last 30 days, last 365 days.
  Future<IzzyStats> fetchStatsForPackage(String packageName) async {
    final results = await Future.wait<int?>([
      _getCount('basic/daily/rolling.json', packageName),
      _getCount('basic/monthly/rolling.json', packageName),
      _getCount('basic/yearly/rolling.json', packageName),
    ]);

    return IzzyStats(
      lastDay: results[0],
      last30Days: results[1],
      last365Days: results[2],
    );
  }

  Future<int?> _getCount(String path, String packageName) async {
    try {
      final stats = await _loadStats(path);
      return stats[packageName];
    } catch (e) {
      debugPrint('Error loading Izzy stats ($path): $e');
      return null;
    }
  }

  Future<Map<String, int>> _loadStats(String path) async {
    if (_cache.containsKey(path)) return _cache[path]!;

    final url = '$_baseUrl/$path';
    final response = await _client.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected stats format');
    }

    final parsed = <String, int>{};
    decoded.forEach((key, value) {
      final count = value is num
          ? value.toInt()
          : int.tryParse(value.toString().trim());
      if (count != null) parsed[key] = count;
    });

    _cache[path] = parsed;
    return parsed;
  }
}
