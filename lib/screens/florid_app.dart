import 'dart:async';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:florid/screens/library_screen.dart';
import 'package:florid/screens/remote_install_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../providers/pairing_provider.dart';
import '../providers/repositories_provider.dart';
import '../services/notification_service.dart';
import 'search_screen.dart';
import 'updates_screen.dart';

class FloridApp extends StatefulWidget {
  const FloridApp({super.key});

  @override
  State<FloridApp> createState() => _FloridAppState();
}

class _FloridAppState extends State<FloridApp> {
  int _currentIndex = 0;
  final ValueNotifier<int> _tabNotifier = ValueNotifier<int>(0);
  Timer? _pollTimer;
  final NotificationService _notificationService = NotificationService();

  late final List<Widget> _screens = [
    const LibraryScreen(),
    SearchScreen(tabIndexListenable: _tabNotifier, tabIndex: 1),
    const UpdatesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Load installed apps and repositories once at startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appProvider = context.read<AppProvider>();
      final repositoriesProvider = context.read<RepositoriesProvider>();

      appProvider.fetchInstalledApps();
      repositoriesProvider.loadRepositories();
      
      // Initialize notification service
      _initNotifications();
      
      // Start polling for install requests from web
      _startPollingForInstallRequests();
    });
  }
  
  Future<void> _initNotifications() async {
    try {
      await _notificationService.init();
    } catch (e) {
      debugPrint('[FloridApp] Failed to initialize notifications: $e');
    }
  }
  
  void _startPollingForInstallRequests() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) return; // Check if widget is still mounted
      
      final pairingProvider = context.read<PairingProvider>();
      
      if (pairingProvider.isPaired) {
        final installRequest = await pairingProvider.checkForInstallRequest();
        
        if (installRequest != null && installRequest.data != null && mounted) {
          final packageName = installRequest.data!['packageName'] as String;
          final appName = installRequest.data!['appName'] as String;
          final versionName = installRequest.data!['versionName'] as String?;
          
          // Show notification
          await _showInstallNotification(packageName, appName, versionName);
        }
      }
    });
  }
  
  Future<void> _showInstallNotification(
    String packageName,
    String appName,
    String? versionName,
  ) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'remote_install_channel',
        'Remote Install Requests',
        channelDescription: 'Notifications for remote install requests from web',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
      );
      
      const NotificationDetails details = NotificationDetails(android: androidDetails);
      
      // Use the initialized notification service
      await _notificationService._flutterLocalNotificationsPlugin.show(
        packageName.hashCode,
        'Install Request',
        'Install $appName from web?',
        details,
        payload: jsonEncode({
          'packageName': packageName,
          'appName': appName,
          'versionName': versionName ?? '',
        }),
      );
      
      // Navigate to remote install screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RemoteInstallScreen(
              packageName: packageName,
              appName: appName,
              versionName: versionName,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('[FloridApp] Failed to show notification: $e');
    }
  }

  @override
  void dispose() {
    _tabNotifier.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          final updatableAppsCount = appProvider.getUpdatableApps().length;

          // Build destinations with translations
          final destinations = [
            NavigationDestination(
              icon: const Icon(Symbols.newsstand_rounded),
              selectedIcon: const Icon(
                Symbols.newsstand_rounded,
                fill: 1,
                weight: 600,
              ),
              label: 'home'.tr(),
            ),
            NavigationDestination(
              icon: const Icon(Symbols.search),
              selectedIcon: const Icon(Symbols.search, fill: 1, weight: 600),
              label: 'search'.tr(),
            ),
            NavigationDestination(
              icon: updatableAppsCount > 0
                  ? Badge.count(
                      count: updatableAppsCount,
                      child: const Icon(Symbols.mobile_3_rounded),
                    )
                  : const Icon(Symbols.mobile_3_rounded),
              selectedIcon: updatableAppsCount > 0
                  ? Badge.count(
                      count: updatableAppsCount,
                      child: const Icon(
                        Symbols.mobile_3_rounded,
                        fill: 1,
                        weight: 600,
                      ),
                    )
                  : const Icon(Symbols.mobile_3_rounded, fill: 1, weight: 600),
              label: 'device'.tr(),
            ),
          ];

          return NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
              _tabNotifier.value = index;
            },
            destinations: destinations,
          );
        },
      ),
    );
  }
}
