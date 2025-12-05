import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import 'categories_screen.dart';
import 'latest_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'updates_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    LatestScreen(),
    CategoriesScreen(),
    UpdatesScreen(),
  ];

  @override
  void initState() {
    super.initState();
  }

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Symbols.new_releases),
      selectedIcon: Icon(Symbols.new_releases),
      label: 'Latest',
    ),
    NavigationDestination(
      icon: Icon(Symbols.category),
      selectedIcon: Icon(Symbols.category),
      label: 'Categories',
    ),
    NavigationDestination(
      icon: Icon(Symbols.system_update),
      selectedIcon: Icon(Symbols.system_update),
      label: 'Updates',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Florid'),
        actions: [
          IconButton(
            icon: const Icon(Symbols.search),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'refresh':
                  _refreshData();
                  break;
                case 'settings':
                  _showSettings();
                  break;
                case 'about':
                  _showAbout();
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
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: _destinations,
      ),
    );
  }

  void _refreshData() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Refreshing data...')));
    Future.microtask(() async {
      try {
        final appProvider = context.read<AppProvider>();
        await appProvider.refreshAll();
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

  void _showSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Florid',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Symbols.android, size: 48, color: Colors.green),
      children: const [
        Text('A modern F-Droid client built with Flutter.'),
        SizedBox(height: 16),
        Text('Browse, search, and download free and open-source Android apps.'),
      ],
    );
  }
}
