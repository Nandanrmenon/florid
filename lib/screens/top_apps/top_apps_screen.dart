import 'package:florid/l10n/app_localizations.dart';
import 'package:florid/models/fdroid_app.dart';
import 'package:florid/providers/app_provider.dart';
import 'package:florid/providers/repositories_provider.dart';
import 'package:florid/screens/app_details/app_details_screen.dart';
import 'package:florid/widgets/app_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

class TopAppsAllTimeScreen extends StatefulWidget {
  const TopAppsAllTimeScreen({super.key});

  @override
  State<TopAppsAllTimeScreen> createState() => _TopAppsAllTimeScreenState();
}

class _TopAppsAllTimeScreenState extends State<TopAppsAllTimeScreen>
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
    appProvider.fetchTopAppsAllTime(
      repositoriesProvider: repositoriesProvider,
      limit: 100,
    );
  }

  Future<void> _onRefresh() async {
    final appProvider = context.read<AppProvider>();
    final repositoriesProvider = context.read<RepositoriesProvider>();
    await appProvider.fetchTopAppsAllTime(
      repositoriesProvider: repositoriesProvider,
      limit: 100,
    );
  }

  String _formatDownloads(int downloads) {
    if (downloads >= 1000000) {
      return '${(downloads / 1000000).toStringAsFixed(1)}M';
    }
    if (downloads >= 1000) {
      return '${(downloads / 1000).toStringAsFixed(1)}K';
    }
    return downloads.toString();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final state = appProvider.topAppsAllTimeState;
        final apps = appProvider.topAppsAllTime;
        final error = appProvider.topAppsAllTimeError;
        return _buildBody(state, apps, error, appProvider);
      },
    );
  }

  Widget _buildBody(
    LoadingState state,
    List<FDroidApp> apps,
    String? error,
    AppProvider appProvider,
  ) {
    final localizations = AppLocalizations.of(context)!;

    if (state == LoadingState.loading && apps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(year2023: false),
            const SizedBox(height: 16),
            Text(localizations.loading_top_apps),
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
              icon: const Icon(Symbols.refresh),
              label: Text(localizations.try_again),
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
            Icon(
              Symbols.emoji_events,
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
          final downloads =
              appProvider.topAppsAllTimeDownloads[app.packageName] ?? 0;

          return Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  '${index + 1}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    AppListItem(
                      app: app,
                      showInstallStatus: true,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AppDetailsScreen(app: app),
                          ),
                        );
                      },
                    ).animate().fadeIn(
                      duration: 300.ms,
                      delay: (20 * index).ms,
                    ),
                    Positioned(
                      right: 12,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: Theme.of(context).colorScheme.surfaceContainer,
                        ),
                        child: Text(
                          _formatDownloads(downloads),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
