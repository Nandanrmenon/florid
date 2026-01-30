import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:florid/providers/settings_provider.dart';
import 'package:florid/screens/florid_app.dart';
import 'package:florid/services/notification_service.dart';
import 'package:florid/services/pairing_service.dart';
import 'package:florid/themes/app_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:universal_platform/universal_platform.dart';

import 'providers/app_provider.dart';
import 'providers/download_provider.dart';
import 'providers/repositories_provider.dart';
import 'screens/install_progress_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/database_service.dart';
import 'services/fdroid_api_service.dart';
import 'services/izzy_stats_service.dart';

// Global navigator key for handling notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    // Initialize notification service on mobile platforms
    if (UniversalPlatform.isAndroid || UniversalPlatform.isIOS) {
      try {
        final notificationService = NotificationService();
        await notificationService.init();
        
        // Set up notification tap handler for install requests
        notificationService.onInstallRequestTapped = (payload) {
          // payload is the package name and app name separated by '|'
          final parts = payload.split('|');
          if (parts.length >= 2) {
            final packageName = parts[0];
            final appName = parts[1];
            
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => InstallProgressScreen(
                  packageName: packageName,
                  appName: appName,
                ),
              ),
            );
          }
        };
      } catch (e) {
        debugPrint('Failed to initialize notification service: $e');
      }
    }
  }

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
        ChangeNotifierProvider<PairingService>(
          create: (_) {
            final service = PairingService();
            // Initialize with server configuration
            // TODO: Make this configurable in settings
            service.init(
              serverUrl: 'http://localhost:3000',
              wsUrl: 'ws://localhost:3000',
            );
            
            // Listen for install requests on mobile
            if (UniversalPlatform.isAndroid || UniversalPlatform.isIOS) {
              service.installRequestStream.listen((request) {
                _handleInstallRequest(request);
              });
            }
            
            return service;
          },
        ),
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
            title: 'Florid - F-Droid Client',
            navigatorKey: navigatorKey,
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
  
  /// Handle install requests received from web
  Future<void> _handleInstallRequest(InstallRequest request) async {
    debugPrint('[MainApp] Received install request: ${request.packageName}');
    
    // Show notification
    try {
      final notificationService = NotificationService();
      await notificationService.showInstallRequest(
        appName: request.appName,
        packageName: '${request.packageName}|${request.appName}',
      );
    } catch (e) {
      debugPrint('[MainApp] Failed to show install request notification: $e');
    }
    
    // Optionally navigate to install progress screen immediately
    // navigatorKey.currentState?.push(
    //   MaterialPageRoute(
    //     builder: (context) => InstallProgressScreen(
    //       packageName: request.packageName,
    //       appName: request.appName,
    //     ),
    //   ),
    // );
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
