import 'package:florid/screens/library_screen.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

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

      appProvider.fetchInstalledApps();
      repositoriesProvider.loadRepositories();
    });
  }

  @override
  void dispose() {
    _tabNotifier.dispose();
    super.dispose();
  }

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Symbols.newsstand_rounded),
      selectedIcon: Icon(Symbols.newsstand_rounded, fill: 1),
      label: 'Library',
    ),
    NavigationDestination(
      icon: Icon(Symbols.search),
      selectedIcon: Icon(Symbols.search, fill: 1),
      label: 'Search',
    ),
    NavigationDestination(
      icon: Icon(Symbols.system_update),
      selectedIcon: Icon(Symbols.system_update, fill: 1),
      label: 'Updates',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
          _tabNotifier.value = index;
        },
        destinations: _destinations,
      ),
    );
  }
}
