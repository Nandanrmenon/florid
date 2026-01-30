import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static const String downloadChannelId = 'com.florid.download';
  static const String downloadChannelName = 'Download Progress';
  static const int downloadNotificationId = 1;
  
  static const String remoteInstallChannelId = 'com.florid.remote_install';
  static const String remoteInstallChannelName = 'Remote Install';
  static const int remoteInstallNotificationId = 2;

  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  Future<void> init() async {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const InitializationSettings customIconSettings = InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
    );

    const InitializationSettings fallbackIconSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    try {
      await _flutterLocalNotificationsPlugin.initialize(
        customIconSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
    } on PlatformException catch (e) {
      if (e.code == 'invalid_icon') {
        debugPrint(
          'Notification icon ic_notification missing, falling back to launcher icon: $e',
        );
        await _flutterLocalNotificationsPlugin.initialize(
          fallbackIconSettings,
          onDidReceiveNotificationResponse: _onNotificationTapped,
        );
      } else {
        rethrow;
      }
    }

    // Request notification permission on Android 13+
    await requestPermission();

    // Create download notification channel
    await _createDownloadChannel();
    
    // Create remote install notification channel
    await _createRemoteInstallChannel();
  }

  Future<void> requestPermission() async {
    final androidImplementation = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImplementation?.requestNotificationsPermission();
  }

  Future<void> _createDownloadChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      downloadChannelId,
      downloadChannelName,
      description: 'Download progress notifications',
      importance: Importance.low,
      enableVibration: false,
      playSound: false,
      showBadge: false,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<void> _createRemoteInstallChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      remoteInstallChannelId,
      remoteInstallChannelName,
      description: 'Remote install notifications from web store',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
      showBadge: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<void> showDownloadProgress({
    required String title,
    required String packageName,
    required int progress,
    required int maxProgress,
  }) async {
    final percent = ((progress / maxProgress) * 100).toStringAsFixed(0);

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          downloadChannelId,
          downloadChannelName,
          channelDescription: 'Download progress notifications',
          importance: Importance.high,
          priority: Priority.high,
          progress: 100,
          indeterminate: false,
          showProgress: true,
          maxProgress: 100,
          enableVibration: false,
          playSound: false,
          channelShowBadge: false,
        );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: AndroidNotificationDetails(
        downloadChannelId,
        downloadChannelName,
        channelDescription: 'Download progress notifications',
        importance: Importance.high,
        priority: Priority.high,
        showProgress: true,
        ongoing: true,
        progress: progress,
        maxProgress: maxProgress,
        enableVibration: false,
        playSound: false,
        channelShowBadge: true,
        onlyAlertOnce: true,
        tag: packageName,
      ),
    );

    await _flutterLocalNotificationsPlugin.show(
      downloadNotificationId,
      title,
      '$percent% - Downloading $packageName',
      platformChannelSpecifics,
      payload: packageName,
    );
  }

  Future<void> showDownloadComplete({
    required String title,
    required String packageName,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          downloadChannelId,
          downloadChannelName,
          channelDescription: 'Download notifications',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          showProgress: false,
          enableVibration: true,
          playSound: true,
          channelShowBadge: true,
        );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: AndroidNotificationDetails(
        downloadChannelId,
        downloadChannelName,
        channelDescription: 'Download notifications',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        showProgress: false,
        enableVibration: true,
        playSound: true,
        channelShowBadge: true,
        tag: packageName,
      ),
    );

    await _flutterLocalNotificationsPlugin.show(
      downloadNotificationId,
      title,
      'Download complete - $packageName',
      platformChannelSpecifics,
      payload: packageName,
    );
  }

  Future<void> showDownloadError({
    required String title,
    required String packageName,
    required String error,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          downloadChannelId,
          downloadChannelName,
          channelDescription: 'Download error notifications',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          showProgress: false,
          enableVibration: true,
          playSound: true,
          channelShowBadge: true,
        );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: AndroidNotificationDetails(
        downloadChannelId,
        downloadChannelName,
        channelDescription: 'Download error notifications',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        showProgress: false,
        enableVibration: true,
        playSound: true,
        channelShowBadge: true,
        tag: packageName,
      ),
    );

    await _flutterLocalNotificationsPlugin.show(
      downloadNotificationId,
      title,
      'Download failed: $error',
      platformChannelSpecifics,
      payload: packageName,
    );
  }

  Future<void> cancelDownloadNotification() async {
    await _flutterLocalNotificationsPlugin.cancel(downloadNotificationId);
  }

  /// Show notification for remote install request
  Future<void> showRemoteInstallNotification({
    required String appName,
    required String packageName,
    required String sourceDevice,
  }) async {
    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: AndroidNotificationDetails(
        remoteInstallChannelId,
        remoteInstallChannelName,
        channelDescription: 'Remote install notifications from web store',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        channelShowBadge: true,
        tag: packageName,
      ),
    );

    await _flutterLocalNotificationsPlugin.show(
      remoteInstallNotificationId,
      'Install Request',
      'Install $appName from $sourceDevice',
      platformChannelSpecifics,
      payload: packageName,
    );
  }

  /// Show notification for successful pairing
  Future<void> showPairingSuccessNotification({
    required String deviceName,
  }) async {
    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: AndroidNotificationDetails(
        remoteInstallChannelId,
        remoteInstallChannelName,
        channelDescription: 'Device pairing notifications',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        enableVibration: true,
        playSound: true,
        channelShowBadge: true,
      ),
    );

    await _flutterLocalNotificationsPlugin.show(
      remoteInstallNotificationId,
      'Device Paired',
      'Successfully paired with $deviceName',
      platformChannelSpecifics,
    );
  }

  /// Cancel remote install notification
  Future<void> cancelRemoteInstallNotification() async {
    await _flutterLocalNotificationsPlugin.cancel(remoteInstallNotificationId);
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint(
      '[NotificationService] Notification tapped: ${response.payload}',
    );
  }
}
