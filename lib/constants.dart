import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

var kAppColor = Color(0xFF74DAB6);
String kAppName = 'Florid';
const kAppPackageName = 'com.nahnah.florid';

const kAppLogoSvg = 'assets/Florid.svg';

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

const kPermissionDescriptions = <String, String>{
  'android.permission.INTERNET':
      'Allows the app to create network connections.',
  'android.permission.ACCESS_NETWORK_STATE':
      'Allows the app to view network connections.',
  'android.permission.ACCESS_WIFI_STATE':
      'Allows the app to view Wi-Fi connection status.',
  'android.permission.CHANGE_WIFI_STATE':
      'Allows the app to change Wi-Fi connectivity.',
  'android.permission.READ_EXTERNAL_STORAGE':
      'Allows the app to read files from storage.',
  'android.permission.WRITE_EXTERNAL_STORAGE':
      'Allows the app to write files to storage.',
  'android.permission.MANAGE_EXTERNAL_STORAGE':
      'Allows the app broad access to manage files on storage.',
  'android.permission.REQUEST_INSTALL_PACKAGES':
      'Allows the app to request installation of packages.',
  'android.permission.POST_NOTIFICATIONS':
      'Allows the app to show notifications.',
  'android.permission.VIBRATE': 'Allows the app to control vibration.',
  'android.permission.WAKE_LOCK': 'Allows the app to keep the device awake.',
  'android.permission.RECEIVE_BOOT_COMPLETED':
      'Allows the app to run at device startup.',
  'android.permission.FOREGROUND_SERVICE':
      'Allows the app to run foreground services.',
  'android.permission.CAMERA': 'Allows the app to use the camera.',
  'android.permission.RECORD_AUDIO': 'Allows the app to record audio.',
  'android.permission.READ_CONTACTS': 'Allows the app to read contacts.',
  'android.permission.WRITE_CONTACTS': 'Allows the app to modify contacts.',
  'android.permission.ACCESS_FINE_LOCATION':
      'Allows the app to access precise location.',
  'android.permission.ACCESS_COARSE_LOCATION':
      'Allows the app to access approximate location.',
  'android.permission.BLUETOOTH':
      'Allows the app to connect to Bluetooth devices.',
  'android.permission.BLUETOOTH_CONNECT':
      'Allows the app to connect to Bluetooth devices.',
  'android.permission.BLUETOOTH_SCAN':
      'Allows the app to discover nearby Bluetooth devices.',
  'android.permission.NFC': 'Allows the app to use NFC.',
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
