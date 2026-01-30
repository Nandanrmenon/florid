import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'providers/repositories_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/web/web_home_screen.dart';
import 'screens/web/web_login_screen.dart';
import 'services/database_service.dart';
import 'services/fdroid_api_service.dart';
import 'services/izzy_stats_service.dart';
import 'services/web_auth_service.dart';
import 'services/web_device_service.dart';
import 'themes/app_themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const FloridWebApp(),
    ),
  );
}

class FloridWebApp extends StatelessWidget {
  const FloridWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(),
        ),
        ChangeNotifierProvider<WebAuthService>(
          create: (_) => WebAuthService(),
        ),
        ChangeNotifierProvider<RepositoriesProvider>(
          create: (_) => RepositoriesProvider(DatabaseService()),
        ),
        Provider<IzzyStatsService>(
          create: (_) => IzzyStatsService(),
        ),
        ProxyProvider<SettingsProvider, FDroidApiService>(
          update: (_, settings, previous) {
            if (previous != null) {
              previous.updateSettings(settings);
              return previous;
            }
            return FDroidApiService(settings);
          },
        ),
        ProxyProvider<FDroidApiService, AppProvider>(
          update: (_, apiService, previous) {
            return previous ?? AppProvider(apiService);
          },
        ),
        ProxyProvider<WebAuthService, WebDeviceService>(
          update: (_, authService, previous) {
            return previous ?? WebDeviceService(authService);
          },
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Florid Web',
            debugShowCheckedModeBanner: false,
            theme: AppThemes.getLightTheme(settings.themeStyle),
            darkTheme: AppThemes.getDarkTheme(settings.themeStyle),
            themeMode: settings.themeMode,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: Consumer<WebAuthService>(
              builder: (context, authService, _) {
                if (authService.isAuthenticated) {
                  return const WebHomeScreen();
                } else {
                  return const WebLoginScreen();
                }
              },
            ),
          );
        },
      ),
    );
  }
}
