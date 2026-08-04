import 'dart:convert';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:florid/l10n/app_localizations.dart';
import 'package:florid/providers/settings_provider.dart';
import 'package:florid/screens/florid_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hornbill/hornbill.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'providers/download_provider.dart';
import 'providers/repositories_provider.dart';
import 'screens/onboarding_screen.dart';
import 'services/database_service.dart';
import 'services/fdroid_api_service.dart';
import 'services/izzy_stats_service.dart';
import 'services/update_check_service.dart';
import 'utils/app_navigator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UpdateCheckService.initialize();
  runApp(MainApp());
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
              previous.setLocale(settings.effectiveLocale);
              return previous;
            }
            // Create new service with current locale
            final service = FDroidApiService();
            service.setLocale(settings.effectiveLocale);
            // Set default F-Droid repository immediately (synchronously)
            service.setRepositoryUrl('https://f-droid.org/repo');
            // Then try to load from config asynchronously
            _initializeDefaultRepository(service);
            return service;
          },
        ),
        ChangeNotifierProxyProvider2<
          FDroidApiService,
          SettingsProvider,
          AppProvider
        >(
          create: (context) => AppProvider(
            Provider.of<FDroidApiService>(context, listen: false),
            Provider.of<SettingsProvider>(context, listen: false),
          ),
          update: (context, apiService, settings, previous) {
            if (previous == null) {
              return AppProvider(apiService, settings);
            }
            previous.updateSettings(settings);
            return previous;
          },
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
            apiService.setLocale(settings.effectiveLocale);

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
          return DynamicColorBuilder(
            builder: (lightDynamic, darkDynamic) {
              final dynamicColorSupported =
                  lightDynamic != null || darkDynamic != null;
              final useDynamic =
                  settings.dynamicColorEnabled && dynamicColorSupported;

              // Debug: log dynamic color availability and selected seeds
              debugPrint(
                'DynamicColor supported: $dynamicColorSupported, useDynamic: $useDynamic',
              );
              final ColorScheme lightScheme = useDynamic && lightDynamic != null
                  ? lightDynamic
                  : ColorScheme.fromSeed(
                      seedColor: settings.themeColor,
                      brightness: Brightness.light,
                    );
              final ColorScheme darkScheme = useDynamic && darkDynamic != null
                  ? darkDynamic
                  : ColorScheme.fromSeed(
                      seedColor: settings.themeColor,
                      brightness: Brightness.dark,
                    );

              // Use Hornbill for both light and dark themes so styles match
              // Use the generated ColorScheme primary color as Hornbill's seed
              // so system/dynamic colors (when enabled) are respected.
              debugPrint(
                'Light seed: ${lightScheme.primary}, Dark seed: ${darkScheme.primary}',
              );

              final ThemeData lightTheme = HornbillTheme(
                seedColor: lightScheme.primary,
              ).lightTheme();
              final ThemeData darkThemeData = HornbillTheme(
                seedColor: darkScheme.primary,
              ).darkTheme();

              return MaterialApp(
                title: 'Florid - F-Droid Client',
                debugShowCheckedModeBanner: false,
                navigatorKey: appNavigatorKey,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                theme: lightTheme,
                darkTheme: darkThemeData,
                themeMode: settings.themeMode,
                home: !settings.isLoaded
                    ? const Scaffold(
                        body: Center(child: M3EContainedLoadingIndicator()),
                      )
                    : settings.onboardingComplete
                    ? const FloridApp()
                    : const OnboardingScreen(),
              );
            },
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
