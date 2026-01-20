import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'providers/download_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'services/fdroid_api_service.dart';

void main() {
  runApp(const FloridApp());
}

class FloridApp extends StatelessWidget {
  const FloridApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(),
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
                seedColor: Colors.green,
                brightness: Brightness.light,
              ),
              appBarTheme: const AppBarTheme(elevation: 0),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.green,
                brightness: Brightness.dark,
              ),
              appBarTheme: const AppBarTheme(elevation: 0),
              useMaterial3: true,
            ),
            themeMode: settings.themeMode,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
