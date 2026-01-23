import 'package:florid/constants.dart';
import 'package:florid/screens/florid_app.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'providers/download_provider.dart';
import 'providers/repositories_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/onboarding_screen.dart';
import 'services/database_service.dart';
import 'services/fdroid_api_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service and request permission
  await NotificationService().init();

  runApp(const MainApp());
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
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: kAppColor,
                brightness: Brightness.light,
              ),
              appBarTheme: const AppBarTheme(),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: kAppColor,
                brightness: Brightness.dark,
              ),
              appBarTheme: const AppBarTheme(),
              useMaterial3: true,
            ),
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
