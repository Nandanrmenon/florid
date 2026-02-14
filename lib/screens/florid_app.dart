import 'package:florid/l10n/app_localizations.dart';
import 'package:florid/models/fdroid_app.dart';
import 'package:florid/screens/library_screen.dart';
import 'package:florid/screens/settings_screen.dart';
import 'package:florid/screens/user_screen.dart';
import 'package:florid/utils/responsive.dart';
import 'package:florid/utils/whats_new.dart';
import 'package:florid/widgets/f_navbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
  bool _hasCheckedWhatsNew = false;
  bool _isShowingWhatsNew = false;

  late final List<Widget> _screens = [
    const LibraryScreen(),
    UpdatesScreen(),
    UserScreen(),
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
      _maybeShowWhatsNewDialog();
    });
  }

  Future<void> _maybeShowWhatsNewDialog() async {
    if (_hasCheckedWhatsNew) return;
    _hasCheckedWhatsNew = true;
    await _showWhatsNew(force: false, markSeen: true);
  }

  Future<void> _showWhatsNew({
    required bool force,
    required bool markSeen,
  }) async {
    if (_isShowingWhatsNew) return;
    _isShowingWhatsNew = true;

    final settings = context.read<SettingsProvider>();
    if (!settings.isLoaded) {
      _isShowingWhatsNew = false;
      return;
    }

    final info = await PackageInfo.fromPlatform();
    final currentVersion = '${info.version}+${info.buildNumber}';
    if (!force && settings.lastSeenVersion == currentVersion) {
      _isShowingWhatsNew = false;
      return;
    }

    final whatsNew = await WhatsNewLoader.loadForVersion(currentVersion);
    if (!mounted) {
      _isShowingWhatsNew = false;
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 24,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    spacing: 16,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "What's new in $currentVersion",
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 12,
                        children: _buildWhatsNewContent(context, whatsNew),
                      ),
                    ],
                  ),
                ),
              ),
              FilledButton(onPressed: () {}, child: Text("Close")),
            ],
          ),
        );
      },
    );

    if (markSeen) {
      await settings.setLastSeenVersion(currentVersion);
    }

    _isShowingWhatsNew = false;
  }

  static Future<void> triggerWhatsNew(
    BuildContext context, {
    bool markSeen = true,
  }) async {
    final state = context.findAncestorStateOfType<_FloridAppState>();
    if (state != null) {
      await state._showWhatsNew(force: true, markSeen: markSeen);
    }
  }

  List<Widget> _buildWhatsNewContent(BuildContext context, WhatsNewData? data) {
    if (data == null || data.sections.isEmpty) {
      return const [
        Text('Thanks for updating Florid!'),
        Text('Enjoy the latest improvements.'),
      ];
    }

    final titleStyle = Theme.of(context).textTheme.titleMedium;

    return data.sections
        .map(
          (section) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Text(section.title, style: titleStyle),
              ...section.items.map(
                (item) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            ],
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    _tabNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= Responsive.largeWidth;

    return Scaffold(
      backgroundColor: screenWidth < Responsive.largeWidth
          ? Theme.of(context).colorScheme.surface
          : context.watch<SettingsProvider>().themeStyle == ThemeStyle.florid
          ? Theme.of(context).colorScheme.surfaceContainer
          : Theme.of(context).colorScheme.surface,
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

              final homeIcon = buildIcon(
                Symbols.newsstand_rounded,
                selected: false,
              );
              final homeSelectedIcon = buildIcon(
                Symbols.newsstand_rounded,
                selected: true,
              );

              final searchIcon = buildIcon(Symbols.search, selected: false);
              final searchSelectedIcon = buildIcon(
                Symbols.search,
                selected: true,
              );

              final deviceIcon = buildIcon(
                Symbols.mobile_3_rounded,
                selected: false,
              );
              final deviceSelectedIcon = buildIcon(
                Symbols.mobile_3_rounded,
                selected: true,
              );

              final userIcon = buildIcon(
                Symbols.person_rounded,
                selected: false,
              );
              final userSelectedIcon = buildIcon(
                Symbols.person_rounded,
                selected: true,
              );

              final floridNavItems = [
                FloridNavBarItem(
                  icon: homeIcon,
                  selectedIcon: homeSelectedIcon,
                  label: localizations.home,
                ),
                FloridNavBarItem(
                  icon: deviceIcon,
                  selectedIcon: deviceSelectedIcon,
                  label: localizations.device,
                ),
                FloridNavBarItem(
                  icon: userIcon,
                  selectedIcon: userSelectedIcon,
                  label: settings.userName.isNotEmpty
                      ? (settings.userName.length > 10
                            ? '${settings.userName.substring(0, 10)}...'
                            : settings.userName)
                      : 'User',
                ),
              ];

              final navRailDestinations = [
                NavigationRailDestination(
                  icon: homeIcon,
                  selectedIcon: homeSelectedIcon,
                  label: Text(localizations.home),
                ),
                NavigationRailDestination(
                  icon: deviceIcon,
                  selectedIcon: deviceSelectedIcon,
                  label: Text(localizations.device),
                ),
                NavigationRailDestination(
                  icon: userIcon,
                  selectedIcon: userSelectedIcon,
                  label: Text(
                    settings.userName.isNotEmpty
                        ? (settings.userName.length > 10
                              ? '${settings.userName.substring(0, 10)}...'
                              : settings.userName)
                        : 'User',
                  ),
                ),
              ];

              final floridNavIndex = _currentIndex == 1
                  ? 1
                  : _currentIndex == 2
                  ? 2
                  : 0;

              final searchFab = FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SearchScreen(),
                    ),
                  );
                },
                child: const Icon(Symbols.search),
              );

              return Stack(
                children: [
                  Row(
                    children: [
                      if (isWide)
                        NavigationRail(
                          selectedIndex: _currentIndex,
                          onDestinationSelected: (index) {
                            setState(() {
                              _currentIndex = index;
                            });
                            _tabNotifier.value = index;
                          },
                          destinations: navRailDestinations,
                          trailingAtBottom: true,
                          trailing: Column(
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SettingsScreen(),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      const Icon(Symbols.settings),
                                      const SizedBox(height: 4),
                                      Text(
                                        localizations.settings,
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (kDebugMode)
                                TextButton(
                                  onPressed: () => _showWhatsNew(
                                    force: true,
                                    markSeen: false,
                                  ),
                                  child: const Text("Show what's new"),
                                ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      if (!isWide)
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            transitionBuilder: (child, animation) {
                              final scaleAnimation = Tween<double>(
                                begin: 0.98,
                                end: 1.0,
                              ).animate(animation);
                              return FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: scaleAnimation,
                                  child: child,
                                ),
                              );
                            },
                            child: KeyedSubtree(
                              key: ValueKey<int>(_currentIndex),
                              child: _screens[_currentIndex],
                            ),
                          ),
                        ),
                      if (isWide)
                        Expanded(
                          child: SafeArea(
                            child: Material(
                              clipBehavior: Clip.antiAlias,
                              borderRadius: BorderRadius.circular(24),
                              elevation: 1,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                switchInCurve: Curves.easeOut,
                                switchOutCurve: Curves.easeIn,
                                transitionBuilder: (child, animation) {
                                  final scaleAnimation = Tween<double>(
                                    begin: 0.98,
                                    end: 1.0,
                                  ).animate(animation);
                                  return FadeTransition(
                                    opacity: animation,
                                    child: ScaleTransition(
                                      scale: scaleAnimation,
                                      child: child,
                                    ),
                                  );
                                },
                                child: KeyedSubtree(
                                  key: ValueKey<int>(_currentIndex),
                                  child: _screens[_currentIndex],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (isFlorid && !isWide)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 16,
                      child: SafeArea(
                        child: FNavBar(
                          currentIndex: floridNavIndex,
                          onChanged: (index) {
                            setState(() {
                              _currentIndex = index;
                            });
                            _tabNotifier.value = index;
                          },
                          items: floridNavItems,
                          fab: searchFab,
                        ),
                      ),
                    ),
                  if (isFlorid && isWide)
                    Positioned.fill(
                      child: SafeArea(
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: searchFab,
                          ),
                        ),
                      ),
                    ),
                  if (!isFlorid && !isWide)
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: SafeArea(child: searchFab),
                    ),
                  if (!isFlorid && isWide)
                    Positioned(
                      right: 24,
                      bottom: 24,
                      child: SafeArea(child: searchFab),
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
                ThemeStyle.material &&
            MediaQuery.sizeOf(context).width < Responsive.largeWidth,
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
                  NavigationDestination(
                    icon: Icon(Symbols.person_rounded),
                    selectedIcon: Icon(
                      Symbols.person_rounded,
                      fill: 1,
                      weight: 600,
                    ),
                    label: settings.userName.isNotEmpty
                        ? (settings.userName.length > 10
                              ? '${settings.userName.substring(0, 10)}...'
                              : settings.userName)
                        : 'User',
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
