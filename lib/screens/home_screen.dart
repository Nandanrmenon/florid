import 'package:florid/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../providers/repositories_provider.dart';
import '../widgets/app_list_item.dart';
import 'app_details_screen.dart';
import 'latest_screen.dart';
import 'recently_updated_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static const int _previewLimit = 5;

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
    appProvider.fetchRecentlyUpdatedApps(
      repositoriesProvider: repositoriesProvider,
    );
  }

  Future<void> _onRefresh() async {
    final appProvider = context.read<AppProvider>();
    final repositoriesProvider = context.read<RepositoriesProvider>();
    await Future.wait([
      appProvider.fetchLatestApps(repositoriesProvider: repositoriesProvider),
      appProvider.fetchRecentlyUpdatedApps(
        repositoriesProvider: repositoriesProvider,
      ),
    ]);
  }

  void _openLatestScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LatestScreen()),
    );
  }

  void _openRecentlyUpdatedScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RecentlyUpdatedScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final latestApps = appProvider.latestApps.take(_previewLimit).toList();
        final recentlyUpdatedApps = appProvider.recentlyUpdatedApps
            .take(_previewLimit)
            .toList();
        final isLoading =
            appProvider.latestAppsState == LoadingState.loading ||
            appProvider.recentlyUpdatedAppsState == LoadingState.loading;

        return RefreshIndicator(
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 24,
              children: [
                // Recently Updated Section
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    spacing: 4.0,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.recently_updated,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            TextButton.icon(
                              onPressed: _openRecentlyUpdatedScreen,
                              iconAlignment: IconAlignment.end,
                              icon: Icon(Symbols.arrow_forward),
                              label: Text(
                                AppLocalizations.of(context)!.show_more,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isLoading && recentlyUpdatedApps.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (recentlyUpdatedApps.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Symbols.update,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No recently updated apps',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: recentlyUpdatedApps.length,
                          itemBuilder: (context, index) {
                            final app = recentlyUpdatedApps[index];
                            return AppListItem(
                              app: app,
                              showInstallStatus: false,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AppDetailsScreen(app: app),
                                  ),
                                );
                              },
                            ).animate().fadeIn(
                              duration: 300.ms,
                              delay: (50 * index).ms,
                            );
                          },
                        ),
                    ],
                  ),
                ),
                Column(
                  spacing: 4.0,
                  children: [
                    // New Releases Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'New Releases',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          TextButton.icon(
                            onPressed: _openLatestScreen,
                            iconAlignment: IconAlignment.end,
                            icon: Icon(Symbols.arrow_forward),
                            label: Text(
                              AppLocalizations.of(context)!.show_more,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isLoading && latestApps.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (latestApps.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Symbols.apps,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No new apps',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: latestApps.length,
                        itemBuilder: (context, index) {
                          final app = latestApps[index];
                          return AppListItem(
                            app: app,
                            showInstallStatus: false,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AppDetailsScreen(app: app),
                                ),
                              );
                            },
                          ).animate().fadeIn(
                            duration: 300.ms,
                            delay: (50 * index).ms,
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
