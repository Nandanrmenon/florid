import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UsageAnalyticsService {
  static String _generateRandomInstallId() {
    final random = Random();
    return List.generate(10, (index) => random.nextInt(10)).join();
  }

  static Future<void> logAppOpen() async {
    final prefs = await SharedPreferences.getInstance();
    String installId = prefs.getString('install_id') ?? _generateRandomInstallId();
    await prefs.setString('install_id', installId);

    final response = await http.post(
      Uri.parse('https://florid.knoxxbox.in/v1/app_open.php'),
      headers: {
        'X-Api-Key': 'YOUR_API_KEY_HERE', // Replace with actual API key.
      },
      body: {
        'install_id': installId,
        // Add any other necessary data here
      },
    );

    if (response.statusCode != 200) {
      // Handle error if needed
    }
  }
}