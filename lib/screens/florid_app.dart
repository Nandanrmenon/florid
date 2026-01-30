import 'package:easy_localization/easy_localization.dart';
import 'package:florid/screens/library_screen.dart';
import 'package:florid/screens/web_store_screen.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:universal_platform/universal_platform.dart';

import '../providers/app_provider.dart';
import '../providers/repositories_provider.dart';
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

      // Only fetch installed apps on mobile platforms
      if (UniversalPlatform.isAndroid || UniversalPlatform.isIOS) {
        appProvider.fetchInstalledApps();
      }
      repositoriesProvider.loadRepositories();
    });
  }

  @override
  void dispose() {
    _tabNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show web store for web platform
    if (UniversalPlatform.isWeb) {
      return const WebStoreScreen();
    }
    
    // Show mobile UI for mobile platforms
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
