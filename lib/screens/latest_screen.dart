import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../models/fdroid_app.dart';
import '../providers/app_provider.dart';
import '../providers/repositories_provider.dart';
import '../widgets/app_list_item.dart';
import 'app_details_screen.dart';

class LatestScreen extends StatefulWidget {
  const LatestScreen({super.key});

  @override
  State<LatestScreen> createState() => _LatestScreenState();
}

class _LatestScreenState extends State<LatestScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final appProvider = context.read<AppProvider>();
    final repositoriesProvider = context.read<RepositoriesProvider>();
    appProvider.fetchLatestApps(repositoriesProvider: repositoriesProvider);
  }

  Future<void> _onRefresh() async {
    final appProvider = context.read<AppProvider>();
    final repositoriesProvider = context.read<RepositoriesProvider>();
    await appProvider.fetchLatestApps(
      repositoriesProvider: repositoriesProvider,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final state = appProvider.latestAppsState;
        final apps = appProvider.latestApps;
        final error = appProvider.latestAppsError;
        return _buildBody(state, apps, error);
      },
    );
  }

  Widget _buildBody(LoadingState state, List<FDroidApp> apps, String? error) {
    if (state == LoadingState.loading && apps.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(year2023: false),
            SizedBox(height: 16),
            Text('Loading latest apps...'),
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
            SelectableText(
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Symbols.apps, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No apps found'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: apps.length,
        itemBuilder: (context, index) {
          final app = apps[index];
          return AppListItem(
            app: app,
            onTap: () async {
              final screenshots = await context
                  .read<AppProvider>()
                  .getScreenshots(app.packageName);
              if (!context.mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AppDetailsScreen(
                    app: app,
                    screenshots: screenshots.isNotEmpty ? screenshots : null,
                  ),
                ),
              );
            },
          ).animate().fadeIn(duration: 300.ms, delay: (10 * index).ms);
        },
      ),
    );
  }
}
