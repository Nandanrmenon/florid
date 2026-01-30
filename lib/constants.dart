import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

var kAppColor = Color(0xFF74DAB6);
String kAppName = 'Florid';
const kAppPackageName = 'com.nahnah.florid';

Future<String> kAppversion = getAppVersion(); // Fallback version

Future<String> getAppVersion() async {
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  } catch (e) {
    return kAppversion;
  }
}

// Server configuration for web-mobile pairing
// TODO: Make these configurable through settings or environment variables
const String kDefaultServerUrl = String.fromEnvironment(
  'SERVER_URL',
  defaultValue: 'http://localhost:3000',
);

const String kDefaultWsUrl = String.fromEnvironment(
  'WS_URL',
  defaultValue: 'ws://localhost:3000',
);
