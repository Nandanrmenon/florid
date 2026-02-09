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
