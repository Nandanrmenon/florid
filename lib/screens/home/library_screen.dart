import 'dart:async';

import 'package:florid/constants.dart';
import 'package:florid/l10n/app_localizations.dart';
import 'package:florid/providers/repositories_provider.dart';
import 'package:florid/providers/settings_provider.dart';
import 'package:florid/screens/home/categories_screen.dart';
import 'package:florid/screens/home/games_screen.dart';
import 'package:florid/screens/home/home_screen.dart';
import 'package:florid/screens/top_apps/top_apps_screen.dart';
import 'package:florid/widgets/f_tabbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/svg.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

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
    _tabController = TabController(length: 3, vsync: this);
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

      final newLength = shouldShowTopApps ? 4 : 3;
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
    final tabs = <Widget>[
      const HomeScreen(),
      if (_showTopAppsTab) const TopAppsAllTimeScreen(),
      const CategoriesScreen(),
      const GamesScreen(),
    ];

    final settingsProvider = context.watch<SettingsProvider>();
    final isDarkKnight = settingsProvider.themeStyle == ThemeStyle.darkKnight;

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
              backgroundColor: isDarkKnight
                  ? null
                  : Theme.of(context).colorScheme.surfaceContainerLow,
              surfaceTintColor: isDarkKnight
                  ? null
                  : Theme.of(context).colorScheme.surfaceContainerLow,
              pinned: false,
            ),
            SliverPersistentHeader(
              delegate: _FTabBarHeaderDelegate(
                height: settingsProvider.themeStyle == ThemeStyle.florid
                    ? 64
                    : 56,
                child: Material(
                  color: isDarkKnight
                      ? null
                      : Theme.of(context).colorScheme.surfaceContainerLow,
                  surfaceTintColor: isDarkKnight
                      ? null
                      : Theme.of(context).colorScheme.surfaceContainerLow,
                  child: FTabBar(
                    controller: _tabController,
                    onTabChanged: (index) {
                      _tabController.animateTo(index);
                    },
                    isScrollable: true,
                    items: [
                      FloridTabBarItem(
                        icon: Symbols.home,
                        label: AppLocalizations.of(context)!.home,
                      ),
                      if (_showTopAppsTab)
                        FloridTabBarItem(
                          icon: Symbols.emoji_events,
                          label: AppLocalizations.of(context)!.top_apps,
                        ),
                      FloridTabBarItem(
                        icon: Symbols.category,
                        label: AppLocalizations.of(context)!.categories,
                      ),
                      FloridTabBarItem(
                        icon: Symbols.sports_esports,
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

class _FTabBarHeaderDelegate extends SliverPersistentHeaderDelegate {
  _FTabBarHeaderDelegate({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _FTabBarHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}
