import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../l10n/current_l10n.dart';
import '../utils/app_navigator.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static const String downloadChannelId = 'com.florid.download';
  static const int downloadNotificationId = 1;

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
        settings: customIconSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
    } on PlatformException catch (e) {
      if (e.code == 'invalid_icon') {
        debugPrint(
          'Notification icon ic_notification missing, falling back to launcher icon: $e',
        );
        await _flutterLocalNotificationsPlugin.initialize(
          settings: fallbackIconSettings,
          onDidReceiveNotificationResponse: _onNotificationTapped,
        );
      } else {
        rethrow;
      }
    }

    // Request notification permission on Android 13+
    await requestPermission();

    final launchDetails = await _flutterLocalNotificationsPlugin
        .getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final payload = launchDetails?.notificationResponse?.payload;
      _handleNotificationPayload(payload);
    }

    // Create download notification channel
    await _createDownloadChannel();
  }

  Future<void> requestPermission() async {
    final androidImplementation = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImplementation?.requestNotificationsPermission();
  }

  Future<void> _createDownloadChannel() async {
    final l10n = currentL10n();
    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      downloadChannelId,
      l10n.download_channel_name,
      description: l10n.download_progress_channel_description,
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

  Future<void> showDownloadProgress({
    required String title,
    required String packageName,
    required int progress,
    required int maxProgress,
  }) async {
    final percent = ((progress / maxProgress) * 100).toStringAsFixed(0);

    final l10n = currentL10n();
    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: AndroidNotificationDetails(
        downloadChannelId,
        l10n.download_channel_name,
        channelDescription: l10n.download_progress_channel_description,
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
      id: downloadNotificationId,
      title: title,
      body: l10n.downloading_package_percent(percent, packageName),
      notificationDetails: platformChannelSpecifics,
      payload: packageName,
    );
  }

  Future<void> showDownloadComplete({
    required String title,
    required String packageName,
  }) async {
    final l10n = currentL10n();
    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: AndroidNotificationDetails(
        downloadChannelId,
        l10n.download_channel_name,
        channelDescription: l10n.download_notifications_channel_description,
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
      id: downloadNotificationId,
      title: title,
      body: l10n.download_complete_body(packageName),
      notificationDetails: platformChannelSpecifics,
      payload: packageName,
    );
  }

  Future<void> showDownloadError({
    required String title,
    required String packageName,
    required String error,
  }) async {
    final l10n = currentL10n();
    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: AndroidNotificationDetails(
        downloadChannelId,
        l10n.download_channel_name,
        channelDescription: l10n.download_error_channel_description,
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
      id: downloadNotificationId,
      title: title,
      body: l10n.download_failed_with_error(error),
      notificationDetails: platformChannelSpecifics,
      payload: packageName,
    );
  }

  Future<void> cancelDownloadNotification() async {
    await _flutterLocalNotificationsPlugin.cancel(id: downloadNotificationId);
  }

  void _onNotificationTapped(NotificationResponse response) {
    _handleNotificationPayload(response.payload);
  }

  void _handleNotificationPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map && decoded['type'] == 'updates') {
        openUpdatesScreen();
        return;
      }
      if (decoded is Map && decoded['type'] == 'debug_update_check') {
        openUpdatesScreen();
      }
    } catch (_) {
      // Ignore invalid payloads.
    }
  }
}
