import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../models/fdroid_app.dart';
import '../../providers/app_provider.dart';
import '../../services/web_auth_service.dart';
import '../../services/web_device_service.dart';
import 'web_app_details_screen.dart';
import 'web_device_selector.dart';

/// Web home screen for browsing apps
class WebHomeScreen extends StatefulWidget {
  const WebHomeScreen({super.key});

  @override
  State<WebHomeScreen> createState() => _WebHomeScreenState();
}

class _WebHomeScreenState extends State<WebHomeScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final appProvider = context.read<AppProvider>();
    final deviceService = context.read<WebDeviceService>();
    
    await Future.wait([
      appProvider.fetchLatestApps(limit: 50),
      deviceService.fetchDevices(),
    ]);
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() => _searchQuery = '');
      return;
    }
    setState(() => _searchQuery = query);
    context.read<AppProvider>().searchApps(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Florid Web'),
        actions: [
          const WebDeviceSelector(),
          IconButton(
            icon: const Icon(Symbols.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Symbols.logout),
            onPressed: () async {
              final authService = context.read<WebAuthService>();
              await authService.logout();
            },
            tooltip: 'Logout',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search apps...',
                prefixIcon: const Icon(Symbols.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Symbols.close),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                filled: true,
              ),
              onChanged: _performSearch,
              onSubmitted: _performSearch,
            ),
          ),
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, _) {
          if (_searchQuery.isNotEmpty) {
            return _buildAppGrid(appProvider.searchResults, 'Search Results');
          } else {
            return _buildAppGrid(appProvider.latestApps, 'Latest Apps');
          }
        },
      ),
    );
  }

  Widget _buildAppGrid(List<FDroidApp> apps, String title) {
    if (apps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Symbols.apps,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No apps found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              childAspectRatio: 0.85,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final app = apps[index];
                return _AppCard(app: app);
              },
              childCount: apps.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _AppCard extends StatelessWidget {
  final FDroidApp app;

  const _AppCard({required this.app});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WebAppDetailsScreen(app: app),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (app.icon != null)
              Image.network(
                app.icon!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 120,
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: const Icon(Symbols.android, size: 48),
                  );
                },
              )
            else
              Container(
                height: 120,
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: const Icon(Symbols.android, size: 48),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      app.summary,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
