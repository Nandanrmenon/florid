import 'package:florid/l10n/app_localizations.dart';
import 'package:florid/models/fdroid_app.dart';
import 'package:florid/screens/library_screen.dart';
import 'package:florid/widgets/f_navbar.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../providers/repositories_provider.dart';
import '../providers/settings_provider.dart';
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

      appProvider.fetchInstalledApps();
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
    return Scaffold(
      body: Consumer2<AppProvider, SettingsProvider>(
        builder: (context, appProvider, settings, child) {
          return FutureBuilder<List<FDroidApp>>(
            future: appProvider.getUpdatableApps(),
            builder: (context, snapshot) {
              final updatableAppsCount = snapshot.data?.length ?? 0;
              final localizations = AppLocalizations.of(context)!;
              final isFlorid = settings.themeStyle == ThemeStyle.florid;

              Widget buildIcon(IconData iconData, {required bool selected}) {
                final icon = Icon(
                  iconData,
                  fill: selected ? 1 : 0,
                  weight: selected ? 600 : 400,
                );
                if (iconData == Symbols.mobile_3_rounded &&
                    updatableAppsCount > 0) {
                  return Badge.count(count: updatableAppsCount, child: icon);
                }
                return icon;
              }

              return Stack(
                children: [
                  IndexedStack(index: _currentIndex, children: _screens),
                  if (isFlorid)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 16,
                      child: SafeArea(
                        child: FNavBar(
                          currentIndex: _currentIndex,
                          onChanged: (index) {
                            setState(() {
                              _currentIndex = index;
                            });
                            _tabNotifier.value = index;
                          },
                          items: [
                            FloridNavBarItem(
                              icon: buildIcon(
                                Symbols.newsstand_rounded,
                                selected: false,
                              ),
                              selectedIcon: buildIcon(
                                Symbols.newsstand_rounded,
                                selected: true,
                              ),
                              label: localizations.home,
                            ),
                            FloridNavBarItem(
                              icon: buildIcon(Symbols.search, selected: false),
                              selectedIcon: buildIcon(
                                Symbols.search,
                                selected: true,
                              ),
                              label: localizations.search,
                            ),
                            FloridNavBarItem(
                              icon: buildIcon(
                                Symbols.mobile_3_rounded,
                                selected: false,
                              ),
                              selectedIcon: buildIcon(
                                Symbols.mobile_3_rounded,
                                selected: true,
                              ),
                              label: localizations.device,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
      bottomNavigationBar: Visibility(
        visible:
            Provider.of<SettingsProvider>(context).themeStyle ==
            ThemeStyle.material,
        child: Consumer2<AppProvider, SettingsProvider>(
          builder: (context, appProvider, settings, child) {
            return FutureBuilder<List<FDroidApp>>(
              future: appProvider.getUpdatableApps(),
              builder: (context, snapshot) {
                final updatableAppsCount = snapshot.data?.length ?? 0;
                final localizations = AppLocalizations.of(context)!;

                final destinations = [
                  NavigationDestination(
                    icon: const Icon(Symbols.newsstand_rounded),
                    selectedIcon: const Icon(
                      Symbols.newsstand_rounded,
                      fill: 1,
                      weight: 600,
                    ),
                    label: localizations.home,
                  ),
                  NavigationDestination(
                    icon: const Icon(Symbols.search),
                    selectedIcon: const Icon(
                      Symbols.search,
                      fill: 1,
                      weight: 600,
                    ),
                    label: localizations.search,
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
                        : const Icon(
                            Symbols.mobile_3_rounded,
                            fill: 1,
                            weight: 600,
                          ),
                    label: localizations.device,
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
            );
          },
        ),
      ),
    );
  }
}
