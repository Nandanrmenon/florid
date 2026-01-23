import 'package:florid/constants.dart';
import 'package:florid/screens/settings_screen.dart';
import 'package:flutter/material.dart';

class MenuActions {
  /// Shows the settings dialog/screen
  static void showSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          return const SettingsScreen();
        },
      ),
    );
  }

  /// Shows the about dialog
  static Future<void> showAbout(BuildContext context) async {
    showAboutDialog(
      context: context,
      applicationName: 'Florid',
      applicationIcon: ClipRRect(
        borderRadius: BorderRadiusGeometry.circular(12),
        child: Image.asset('assets/Florid.png', width: 48, height: 48),
      ),
      applicationVersion: await kAppversion,
      children: [
        Text(
          'A modern F-Droid client to browse, search, and download open-source Android apps with ease.',
        ),
      ],
    );
  }
}
