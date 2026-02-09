import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

var kAppColor = Color(0xFF74DAB6);
String kAppName = 'Florid';
const kAppPackageName = 'com.nahnah.florid';

const kAndroidSdkVersions = <int, String>{
  14: 'Android 4.0',
  15: 'Android 4.0.3',
  16: 'Android 4.1',
  17: 'Android 4.2',
  18: 'Android 4.3',
  19: 'Android 4.4',
  20: 'Android 4.4W',
  21: 'Android 5.0',
  22: 'Android 5.1',
  23: 'Android 6.0',
  24: 'Android 7.0',
  25: 'Android 7.1',
  26: 'Android 8.0',
  27: 'Android 8.1',
  28: 'Android 9',
  29: 'Android 10',
  30: 'Android 11',
  31: 'Android 12',
  32: 'Android 12L',
  33: 'Android 13',
  34: 'Android 14',
  35: 'Android 15',
};

Future<String> kAppversion = getAppVersion(); // Fallback version

Future<String> getAppVersion() async {
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  } catch (e) {
    return kAppversion;
  }
}
