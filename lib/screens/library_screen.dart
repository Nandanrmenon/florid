import 'package:florid/l10n/app_localizations.dart';
import 'package:florid/providers/settings_provider.dart';
import 'package:florid/screens/categories_screen.dart';
import 'package:florid/screens/home_screen.dart';
import 'package:florid/widgets/f_tabbar.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with TickerProviderStateMixin {
  final tabs = [HomeScreen(), CategoriesScreen()];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar.medium(
              title: Text(AppLocalizations.of(context)!.app_name),
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerLow,
              surfaceTintColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerLow,
              pinned: false,
            ),
            SliverPersistentHeader(
              delegate: _FTabBarHeaderDelegate(
                height: settingsProvider.themeStyle == ThemeStyle.florid
                    ? 68
                    : 56,
                child: Material(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  surfaceTintColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerLow,
                  child: Container(
                    margin: settingsProvider.themeStyle == ThemeStyle.florid
                        ? const EdgeInsets.only(top: 8)
                        : null,
                    child: FTabBar(
                      controller: _tabController,
                      onTabChanged: (index) {
                        _tabController.animateTo(index);
                      },
                      items: [
                        FloridTabBarItem(
                          icon: Symbols.home,
                          label: AppLocalizations.of(context)!.home,
                        ),
                        FloridTabBarItem(
                          icon: Symbols.category,
                          label: AppLocalizations.of(context)!.categories,
                        ),
                      ],
                    ),
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
