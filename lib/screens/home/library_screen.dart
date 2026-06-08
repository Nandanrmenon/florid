import 'dart:async';

import 'package:florid/constants.dart';
import 'package:florid/l10n/app_localizations.dart';
import 'package:florid/providers/app_provider.dart';
import 'package:florid/providers/repositories_provider.dart';
import 'package:florid/providers/settings_provider.dart';
import 'package:florid/screens/home/app_section_viewer.dart';
import 'package:florid/screens/home/categories_screen.dart';
import 'package:florid/screens/home/home_screen.dart';
import 'package:florid/widgets/f_tabbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/svg.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';
import 'package:solar_icons/solar_icons.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with TickerProviderStateMixin {
  bool _showTopAppsTab = false;
  late TabController _tabController;
  Timer? _titleSwitchTimer;
  bool _showAppName = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _titleSwitchTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _showAppName = true;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repositoriesProvider = context.watch<RepositoriesProvider>();

    if (repositoriesProvider.repositories.isEmpty &&
        !repositoriesProvider.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<RepositoriesProvider>().loadRepositories();
      });
    }

    final shouldShowTopApps = repositoriesProvider.enabledRepositories.any(
      (repo) => repo.name == 'IzzyOnDroid',
    );

    if (shouldShowTopApps != _showTopAppsTab) {
      final oldIndex = _tabController.index;
      final wasShowingTopApps = _showTopAppsTab;
      _showTopAppsTab = shouldShowTopApps;

      var newIndex = oldIndex;
      if (wasShowingTopApps && !shouldShowTopApps && oldIndex > 1) {
        newIndex = oldIndex - 1;
      } else if (!wasShowingTopApps && shouldShowTopApps && oldIndex > 0) {
        newIndex = oldIndex + 1;
      }

      final newLength = shouldShowTopApps ? 3 : 2;
      final clampedIndex = newIndex.clamp(0, newLength - 1);

      _tabController.dispose();
      _tabController = TabController(
        length: newLength,
        vsync: this,
        initialIndex: clampedIndex,
      );
      setState(() {});
    }
  }

  @override
  void dispose() {
    _titleSwitchTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final tabs = <Widget>[
      const HomeScreen(),
      if (_showTopAppsTab)
        AppSectionViewer(
          showAppBar: false,
          title: localizations.top_apps,
          subtitle: localizations.from_izzyondroid,
          stateSelector: (appProvider) => appProvider.topAppsAllTimeState,
          appsSelector: (appProvider) => appProvider.topAppsAllTime,
          errorSelector: (appProvider) => appProvider.topAppsAllTimeError,
          onRefresh: (context) {
            final appProvider = context.read<AppProvider>();
            final repositoriesProvider = context.read<RepositoriesProvider>();
            return appProvider.fetchTopAppsAllTime(
              repositoriesProvider: repositoriesProvider,
              limit: 100,
            );
          },
          loadingMessage: localizations.loading_top_apps,
          emptyMessage: localizations.no_apps_from_izzyondroid,
          emptyIcon: Symbols.emoji_events,
          showInstallStatus: true,
          showRank: true,
          showDownloadBadge: true,
          downloadsSelector: (appProvider) =>
              appProvider.topAppsAllTimeDownloads,
          addFloridBottomSpacing: true,
        ),
      // const CategoriesScreen(),
      AppSectionViewer(
        showAppBar: false,
        title: localizations.games,
        stateSelector: (appProvider) => appProvider.categoryAppsState,
        appsSelector: (appProvider) => appProvider.categoryApps['games'] ?? [],
        errorSelector: (appProvider) => appProvider.categoryAppsError,
        onRefresh: (context) async {
          final appProvider = context.read<AppProvider>();
          appProvider.categoryApps.remove('games');
          await appProvider.fetchAppsByCategory('games');
        },
        loadingMessage: localizations.loading_apps,
        emptyMessage: localizations.no_apps_in_category(localizations.games),
        emptyIcon: Symbols.sports_esports,
        showInstallStatus: true,
        addFloridBottomSpacing: true,
      ),
    ];

    final settingsProvider = context.watch<SettingsProvider>();
    final isDarkKnight = settingsProvider.themeStyle == ThemeStyle.darkKnight;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: _showAppName
                    ? Text(
                        AppLocalizations.of(context)!.app_name,
                        key: const ValueKey('app_name'),
                      )
                    : SvgPicture.asset(
                        kAppLogoSvg,
                        key: const ValueKey('app_logo'),
                        height: 56,
                        colorFilter: ColorFilter.mode(
                          Theme.of(context).colorScheme.primary,
                          BlendMode.srcIn,
                        ),
                      ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
              ),
              backgroundColor: isDark
                  ? Theme.of(context).colorScheme.surfaceContainerLowest
                  : Theme.of(context).colorScheme.surface,
              surfaceTintColor: isDark
                  ? Theme.of(context).colorScheme.surfaceContainerLowest
                  : Theme.of(context).colorScheme.surface,
              snap: true,
              floating: true,
              shape: LinearBorder(bottom: LinearBorderEdge(), side: BorderSide(color: Theme.of(context).colorScheme.surfaceContainerLow)),
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(
                  settingsProvider.themeStyle == ThemeStyle.florid ? 64 : 56,
                ),
                child: Material(
                  color: isDark
                      ? Theme.of(context).colorScheme.surfaceContainerLowest
                      : Theme.of(context).colorScheme.surface,
                  surfaceTintColor: isDark
                      ? Theme.of(context).colorScheme.surfaceContainerLowest
                      : Theme.of(context).colorScheme.surface,
                  child: FTabBar(
                    controller: _tabController,
                    onTabChanged: (index) {
                      _tabController.animateTo(index);
                    },
                    isScrollable: true,
                    items: [
                      FloridTabBarItem(
                        icon: SolarIconsOutline.home,
                        label: AppLocalizations.of(context)!.home,
                      ),
                      if (_showTopAppsTab)
                        FloridTabBarItem(
                          icon: SolarIconsOutline.courseUp,
                          label: AppLocalizations.of(context)!.top_apps,
                        ),
                      FloridTabBarItem(
                        icon: SolarIconsOutline.gamepad,
                        label: AppLocalizations.of(context)!.games,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(controller: _tabController, children: tabs),
      ),
    );
  }
}
