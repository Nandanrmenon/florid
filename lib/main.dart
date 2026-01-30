import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:florid/providers/settings_provider.dart';
import 'package:florid/screens/florid_app.dart';
import 'package:florid/services/notification_service.dart';
import 'package:florid/services/web_pairing_service.dart';
import 'package:florid/themes/app_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'providers/download_provider.dart';
import 'providers/repositories_provider.dart';
import 'screens/onboarding_screen.dart';
import 'screens/remote_install_progress_screen.dart';
import 'services/database_service.dart';
import 'services/fdroid_api_service.dart';
import 'services/izzy_stats_service.dart';

// Global navigator key for handling notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Initialize notification service
  final notificationService = NotificationService();
  try {
    await notificationService.init();
    
    // Set up notification tap handler
    notificationService.onNotificationTap = (payload) {
      if (payload != null && payload.contains('|')) {
        final parts = payload.split('|');
        if (parts.length == 2) {
          final packageName = parts[0];
          final versionName = parts[1];
          
          // Navigate to remote install progress screen
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => RemoteInstallProgressScreen(
                packageName: packageName,
                versionName: versionName,
              ),
            ),
          );
        }
      }
    };
  } catch (e) {
    debugPrint('Notification service initialization error: $e');
  }

  // Initialize web pairing service
  final webPairingService = WebPairingService();
  try {
    await webPairingService.initialize();
    
    // Set up remote install request handler
    webPairingService.onRemoteInstallRequest = (packageName, versionName) {
      debugPrint('Remote install request: $packageName v$versionName');
      
      // Show notification
      notificationService.showRemoteInstallNotification(
        appName: packageName,
        packageName: packageName,
        versionName: versionName,
      );
    };
  } catch (e) {
    debugPrint('Web pairing service initialization error: $e');
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(),
        ),
        ChangeNotifierProvider<RepositoriesProvider>(
          create: (_) => RepositoriesProvider(DatabaseService()),
        ),
        Provider<IzzyStatsService>(create: (_) => IzzyStatsService()),
        ProxyProvider<SettingsProvider, FDroidApiService>(
          update: (context, settings, previous) {
            if (previous != null) {
              // Update existing service with new locale
              previous.setLocale(settings.locale);
              return previous;
            }
            // Create new service with current locale
            final service = FDroidApiService();
            service.setLocale(settings.locale);
            // Set default F-Droid repository immediately (synchronously)
            service.setRepositoryUrl('https://f-droid.org/repo');
            // Then try to load from config asynchronously
            _initializeDefaultRepository(service);
            return service;
          },
        ),
        ChangeNotifierProxyProvider<FDroidApiService, AppProvider>(
          create: (context) => AppProvider(
            Provider.of<FDroidApiService>(context, listen: false),
          ),
          update: (context, apiService, previous) =>
              previous ?? AppProvider(apiService),
        ),
        ChangeNotifierProxyProvider2<
          FDroidApiService,
          SettingsProvider,
          DownloadProvider
        >(
          create: (context) => DownloadProvider(
            Provider.of<FDroidApiService>(context, listen: false),
            Provider.of<SettingsProvider>(context, listen: false),
          ),
          update: (context, apiService, settings, previous) {
            // Update locale when settings change
            apiService.setLocale(settings.locale);

            if (previous == null) {
              return DownloadProvider(apiService, settings);
            }
            previous.updateSettings(settings);
            return previous;
          },
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'Florid - F-Droid Client',
            debugShowCheckedModeBanner: false,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            theme: settings.themeStyle == ThemeStyle.florid
                ? AppThemes.floridLightTheme()
                : AppThemes.materialLightTheme(),
            darkTheme: settings.themeStyle == ThemeStyle.florid
                ? AppThemes.floridDarkTheme()
                : AppThemes.materialDarkTheme(),
            themeMode: settings.themeMode,
            home: !settings.isLoaded
                ? const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  )
                : settings.onboardingComplete
                ? const FloridApp()
                : const OnboardingScreen(),
          );
        },
      ),
    );
  }
}

/// Initializes the default repository URL from the JSON configuration
Future<void> _initializeDefaultRepository(FDroidApiService service) async {
  try {
    final jsonString = await rootBundle.loadString('assets/repositories.json');
    final jsonData = jsonDecode(jsonString);
    final repos = (jsonData['repositories'] as List?)
        ?.cast<Map<String, dynamic>>();

    if (repos != null && repos.isNotEmpty) {
      // Find the first enabled repository (usually F-Droid)
      final firstRepo = repos.first;
      if (firstRepo['url'] is String) {
        service.setRepositoryUrl(firstRepo['url'] as String);
      }
    }
  } catch (e) {
    debugPrint('Error initializing default repository: $e');
    // Set a default F-Droid URL as fallback
    service.setRepositoryUrl('https://f-droid.org/repo');
  }
}

// Store build context for asset loading
late BuildContext buildContext;
