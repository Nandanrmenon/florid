import 'package:florid/l10n/app_localizations.dart';
import 'package:florid/providers/app_provider.dart';
import 'package:florid/screens/app_details/app_details_screen.dart';
import 'package:florid/widgets/app_list_item.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen>
    with AutomaticKeepAliveClientMixin {
  static const String _gamesCategory = 'games';

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
    appProvider.fetchAppsByCategory(_gamesCategory);
  }

  Future<void> _onRefresh() async {
    final appProvider = context.read<AppProvider>();
    appProvider.categoryApps.remove(_gamesCategory);
    await appProvider.fetchAppsByCategory(_gamesCategory);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final localizations = AppLocalizations.of(context)!;

    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final state = appProvider.categoryAppsState;
        final apps = appProvider.categoryApps[_gamesCategory] ?? [];
        final error = appProvider.categoryAppsError;

        if (state == LoadingState.loading && apps.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(year2023: false),
                const SizedBox(height: 16),
                Text(localizations.loading_apps),
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
                  label: Text(localizations.retry),
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
                const Icon(
                  Symbols.sports_esports,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(localizations.no_apps_in_category('Games')),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 96),
                sliver: SliverList.builder(
                  itemCount: apps.length,
                  itemBuilder: (context, index) {
                    final app = apps[index];
                    return AppListItem(
                      app: app,
                      showInstallStatus: true,
                      showCategory: false,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AppDetailsScreen(app: app),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
