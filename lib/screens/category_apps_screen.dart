import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../widgets/app_list_item.dart';
import 'app_details_screen.dart';

class CategoryAppsScreen extends StatefulWidget {
  final String category;

  const CategoryAppsScreen({super.key, required this.category});

  @override
  State<CategoryAppsScreen> createState() => _CategoryAppsScreenState();
}

class _CategoryAppsScreenState extends State<CategoryAppsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final appProvider = context.read<AppProvider>();
    appProvider.fetchAppsByCategory(widget.category);
  }

  Future<void> _onRefresh() async {
    final appProvider = context.read<AppProvider>();
    // Clear cached data for this category and reload
    final categoryApps = appProvider.categoryApps;
    categoryApps.remove(widget.category);
    await appProvider.fetchAppsByCategory(widget.category);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<AppProvider>(
          builder: (context, appProvider, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.category,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${appProvider.categoryApps[widget.category]?.length ?? 0} apps',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          final state = appProvider.categoryAppsState;
          final apps = appProvider.categoryApps[widget.category] ?? [];
          final error = appProvider.categoryAppsError;

          if (state == LoadingState.loading && apps.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading apps...'),
                ],
              ),
            );
          }

          if (state == LoadingState.error && apps.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Symbols.error,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load apps',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error ?? 'Unknown error occurred',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadData,
                    icon: const Icon(Symbols.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (apps.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Symbols.apps, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('No apps found in ${widget.category}'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: apps.length,
              itemBuilder: (context, index) {
                final app = apps[index];
                return AppListItem(
                  app: app,
                  showCategory:
                      false, // Don't show category since we're already in a category
                  onTap: () {
                    final screenshots = context
                        .read<AppProvider>()
                        .getScreenshots(app.packageName);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AppDetailsScreen(
                          app: app,
                          screenshots: screenshots.isNotEmpty
                              ? screenshots
                              : null,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
