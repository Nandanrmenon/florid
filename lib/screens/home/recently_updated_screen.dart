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

class RecentlyUpdatedScreen extends StatefulWidget {
  const RecentlyUpdatedScreen({super.key});

  @override
  State<RecentlyUpdatedScreen> createState() => _RecentlyUpdatedScreenState();
}

class _RecentlyUpdatedScreenState extends State<RecentlyUpdatedScreen>
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
    appProvider.fetchRecentlyUpdatedApps(
      repositoriesProvider: repositoriesProvider,
    );
  }

  Future<void> _onRefresh() async {
    final appProvider = context.read<AppProvider>();
    final repositoriesProvider = context.read<RepositoriesProvider>();
    await appProvider.fetchRecentlyUpdatedApps(
      repositoriesProvider: repositoriesProvider,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final state = appProvider.recentlyUpdatedAppsState;
        final apps = appProvider.recentlyUpdatedApps;
        final error = appProvider.recentlyUpdatedAppsError;
        return _buildBody(state, apps, error);
      },
    );
  }

  Widget _buildBody(LoadingState state, List<FDroidApp> apps, String? error) {
    if (state == LoadingState.loading && apps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(year2023: false),
            SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.loading_recently_updated_apps),
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
              AppLocalizations.of(context)!.failed_to_load_apps,
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
              label: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      );
    }

    if (apps.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Symbols.update, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No recently updated apps',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: Text(AppLocalizations.of(context)!.recently_updated),
              titleTextStyle: TextStyle(
                fontFamily: 'Google Sans Flex',
                fontSize: 18,
                fontVariations: [
                  FontVariation('wght', 700),
                  FontVariation('ROND', 100),
                ],
              ),
              floating: true,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final app = apps[index];
                  return AppListItem(
                    app: app,
                    showInstallStatus: false,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AppDetailsScreen(app: app),
                        ),
                      );
                    },
                  ).animate().fadeIn(duration: 300.ms, delay: (10 * index).ms);
                }, childCount: apps.length),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
