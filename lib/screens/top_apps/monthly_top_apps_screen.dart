import 'package:florid/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../models/fdroid_app.dart';
import '../../providers/app_provider.dart';
import '../../providers/repositories_provider.dart';
import '../../widgets/app_list_item.dart';
import '../app_details/app_details_screen.dart';

class TopAppsScreen extends StatefulWidget {
  const TopAppsScreen({super.key});

  @override
  State<TopAppsScreen> createState() => _TopAppsScreenState();
}

class _TopAppsScreenState extends State<TopAppsScreen>
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
    appProvider.fetchTopApps(
      repositoriesProvider: repositoriesProvider,
      limit: 100,
    );
  }

  Future<void> _onRefresh() async {
    final appProvider = context.read<AppProvider>();
    final repositoriesProvider = context.read<RepositoriesProvider>();
    await appProvider.fetchTopApps(
      repositoriesProvider: repositoriesProvider,
      limit: 100,
    );
  }

  String _formatDownloads(int downloads) {
    if (downloads >= 1000000) {
      return '${(downloads / 1000000).toStringAsFixed(1)}M';
    } else if (downloads >= 1000) {
      return '${(downloads / 1000).toStringAsFixed(1)}K';
    }
    return downloads.toString();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              localizations.monthly_top_apps,
              style: TextStyle(
                fontVariations: [
                  FontVariation('wght', 700),
                  FontVariation('ROND', 100),
                ],
                fontSize: 16,
              ),
            ),
            Text(
              localizations.from_izzyondroid,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          final state = appProvider.topAppsState;
          final apps = appProvider.topApps;
          final error = appProvider.topAppsError;
          return _buildBody(state, apps, error, appProvider);
        },
      ),
    );
  }

  Widget _buildBody(
    LoadingState state,
    List<FDroidApp> apps,
    String? error,
    AppProvider appProvider,
  ) {
    if (state == LoadingState.loading && apps.isEmpty) {
      final localizations = AppLocalizations.of(context)!;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(year2023: false),
            SizedBox(height: 16),
            Text(localizations.loading_top_apps),
          ],
        ),
      );
    }

    if (state == LoadingState.error && apps.isEmpty) {
      final localizations = AppLocalizations.of(context)!;
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
              localizations.failed_to_load_apps,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            SelectableText(
              error ?? localizations.unknown_error_occurred,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: Icon(Symbols.refresh),
              label: Text(localizations.try_again),
            ),
          ],
        ),
      );
    }

    if (apps.isEmpty) {
      final localizations = AppLocalizations.of(context)!;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Symbols.apps,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              localizations.no_apps_from_izzyondroid,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: apps.length,
        itemBuilder: (context, index) {
          final app = apps[index];

          return Row(
            children: [
              SizedBox(width: 8),
              Text('$index', style: Theme.of(context).textTheme.bodyMedium),
              SizedBox(width: 8),
              Expanded(
                child: AppListItem(
                  app: app,
                  showInstallStatus: true,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AppDetailsScreen(app: app),
                      ),
                    );
                  },
                ).animate().fadeIn(duration: 300.ms, delay: (20 * index).ms),
              ),
            ],
          );
        },
      ),
    );
  }
}
