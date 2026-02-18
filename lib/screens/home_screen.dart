import 'package:florid/l10n/app_localizations.dart';
import 'package:florid/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/app_provider.dart';
import '../providers/repositories_provider.dart';
import '../utils/responsive.dart';
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

    return Consumer2<AppProvider, SettingsProvider>(
      builder: (context, appProvider, settingsProvider, child) {
        final latestApps = appProvider.latestApps.take(_previewLimit).toList();
        final recentlyUpdatedApps = appProvider.recentlyUpdatedApps
            .take(_previewLimit)
            .toList();
        final isLoading =
            appProvider.latestAppsState == LoadingState.loading ||
            appProvider.recentlyUpdatedAppsState == LoadingState.loading;
        final isFlorid = settingsProvider.themeStyle == ThemeStyle.florid;

        Widget buildRecentSection() {
          return LayoutBuilder(
            builder: (context, constraints) => Padding(
              padding: EdgeInsets.only(
                top: Responsive.isLargeWidth(constraints.maxWidth) ? 8.0 : 0,
              ),
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
                          label: Text(AppLocalizations.of(context)!.show_more),
                        ),
                      ],
                    ),
                  ),
                  if (isLoading && recentlyUpdatedApps.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.0),
                      child: Center(
                        child: CircularProgressIndicator(year2023: false),
                      ),
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
          );
        }

        Widget buildNewReleasesSection() {
          return Column(
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _openLatestScreen,
                      iconAlignment: IconAlignment.end,
                      icon: Icon(Symbols.arrow_forward),
                      label: Text(AppLocalizations.of(context)!.show_more),
                    ),
                  ],
                ),
              ),
              if (isLoading && latestApps.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.0),
                  child: Center(
                    child: CircularProgressIndicator(year2023: false),
                  ),
                )
              else if (latestApps.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Symbols.apps, size: 48, color: Colors.grey[400]),
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
                            builder: (context) => AppDetailsScreen(app: app),
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
          );
        }

        return RefreshIndicator(
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (Responsive.isLargeWidth(constraints.maxWidth)) {
                  return Row(
                    children: [
                      Expanded(child: buildRecentSection()),
                      Expanded(child: buildNewReleasesSection()),
                    ],
                  ); // Tablet or large screen layout
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 24,
                    children: [
                      if (settingsProvider.showKeepAndroidOpenCard)
                        Padding(
                              padding: const EdgeInsets.only(
                                left: 8.0,
                                top: 16,
                                right: 8,
                              ),
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    spacing: 12.0,
                                    children: [
                                      Text(
                                        'Keep Android Open',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      Text(
                                        'From 2026/2027 onward, Google will require developer verification for all Android apps on certified devices, including those installed outside of the Play Store.',
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        spacing: 4.0,
                                        children: [
                                          TextButton(
                                            onPressed: () async {
                                              await settingsProvider
                                                  .setShowKeepAndroidOpenCard(
                                                    false,
                                                  );
                                            },
                                            style: TextButton.styleFrom(
                                              foregroundColor: Theme.of(
                                                context,
                                              ).colorScheme.error,
                                            ),
                                            child: Text('Ignore'),
                                          ),
                                          FilledButton.tonalIcon(
                                            onPressed: () {
                                              canLaunchUrl(
                                                Uri.parse(
                                                  'https://keepandroidopen.org/',
                                                ),
                                              ).then((canLaunch) {
                                                if (canLaunch) {
                                                  launchUrl(
                                                    Uri.parse(
                                                      'https://keepandroidopen.org/',
                                                    ),
                                                  );
                                                }
                                              });
                                            },
                                            label: Text('Learn More'),
                                            icon: Icon(Symbols.open_in_new),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                            .animate(delay: Duration(milliseconds: 100))
                            .fadeIn(duration: 300.ms),
                      buildRecentSection(),
                      buildNewReleasesSection(),
                      if (isFlorid) const SizedBox(height: 86),
                    ],
                  ); // Phone layout
                }
              },
            ),
          ),
        );
      },
    );
  }
}
