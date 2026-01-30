import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static const String downloadChannelId = 'com.florid.download';
  static const String downloadChannelName = 'Download Progress';
  static const String installRequestChannelId = 'com.florid.install_request';
  static const String installRequestChannelName = 'Install Requests';
  static const int downloadNotificationId = 1;
  static const int installRequestNotificationId = 2;

  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  
  // Callback for notification taps
  Function(String)? onInstallRequestTapped;

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
    
    // Create install request notification channel
    await _createInstallRequestChannel();
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
  
  Future<void> _createInstallRequestChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      installRequestChannelId,
      installRequestChannelName,
      description: 'Install requests from web',
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

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint(
      '[NotificationService] Notification tapped: ${response.payload}',
    );
    
    // Handle install request notification taps
    if (response.id == installRequestNotificationId && 
        response.payload != null &&
        onInstallRequestTapped != null) {
      onInstallRequestTapped!(response.payload!);
    }
  }
  
  /// Show notification for install request from web
  Future<void> showInstallRequest({
    required String appName,
    required String packageName,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          installRequestChannelId,
          installRequestChannelName,
          channelDescription: 'Install requests from web',
          importance: Importance.high,
          priority: Priority.high,
          showProgress: false,
          enableVibration: true,
          playSound: true,
          channelShowBadge: true,
        );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: AndroidNotificationDetails(
        installRequestChannelId,
        installRequestChannelName,
        channelDescription: 'Install requests from web',
        importance: Importance.high,
        priority: Priority.high,
        showProgress: false,
        enableVibration: true,
        playSound: true,
        channelShowBadge: true,
        tag: packageName,
      ),
    );

    await _flutterLocalNotificationsPlugin.show(
      installRequestNotificationId,
      'Install Request',
      'Tap to install $appName from web',
      platformChannelSpecifics,
      payload: packageName,
    );
  }
  
  /// Cancel install request notification
  Future<void> cancelInstallRequestNotification() async {
    await _flutterLocalNotificationsPlugin.cancel(installRequestNotificationId);
  }
}
