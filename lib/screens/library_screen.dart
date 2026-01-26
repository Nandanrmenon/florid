import 'package:florid/providers/app_provider.dart';
import 'package:florid/providers/repositories_provider.dart';
import 'package:florid/screens/categories_screen.dart';
import 'package:florid/screens/home_screen.dart';
import 'package:florid/utils/menu_actions.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Florid'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        surfaceTintColor: Theme.of(context).colorScheme.surfaceContainerLow,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'refresh':
                  _refreshData();
                  break;
                case 'settings':
                  MenuActions.showSettings(context);
                  break;
                case 'about':
                  MenuActions.showAbout(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: ListTile(
                  leading: Icon(Symbols.refresh),
                  title: Text('Refresh'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Symbols.settings),
                  title: Text('Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'about',
                child: ListTile(
                  leading: Icon(Symbols.info),
                  title: Text('About'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          dividerHeight: 0,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Symbols.home, fill: 1),
                  SizedBox(width: 8),
                  Text("Home"),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Symbols.category, fill: 1),
                  SizedBox(width: 8),
                  Text("Categories"),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(controller: _tabController, children: tabs),
          ),
        ],
      ),
    );
  }

  void _refreshData() {
    final currentIndex = _tabController.index;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Refreshing data...')));

    Future.microtask(() async {
      try {
        final appProvider = context.read<AppProvider>();
        final repositoriesProvider = context.read<RepositoriesProvider>();

        if (currentIndex == 0) {
          // Refresh Home (Latest and Recently Updated)
          await Future.wait([
            appProvider.fetchLatestApps(
              repositoriesProvider: repositoriesProvider,
            ),
            appProvider.fetchRecentlyUpdatedApps(
              repositoriesProvider: repositoriesProvider,
            ),
          ]);
        } else if (currentIndex == 1) {
          // Refresh Categories
          await appProvider.fetchCategories();
        }

        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Data refreshed')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Refresh failed: $e')));
      }
    });
  }
}
