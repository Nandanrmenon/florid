import 'package:florid/l10n/app_localizations.dart';
import 'package:florid/providers/download_provider.dart';
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
import 'top_apps_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static const int _previewLimit = 6;

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
    appProvider.fetchTopApps(
      repositoriesProvider: repositoriesProvider,
      limit: 100,
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
      appProvider.fetchTopApps(
        repositoriesProvider: repositoriesProvider,
        limit: 100,
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

  void _openTopAppsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TopAppsScreen()),
    );
  }

  bool _isIzzyOnDroidEnabled(RepositoriesProvider repositoriesProvider) {
    return repositoriesProvider.repositories.any(
      (repo) => repo.name == 'IzzyOnDroid' && repo.isEnabled,
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
        final isDarkKnight =
            settingsProvider.themeStyle == ThemeStyle.darkKnight;

        final repositoriesProvider = context.read<RepositoriesProvider>();

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
                        IconButton(
                          onPressed: _openRecentlyUpdatedScreen,
                          icon: Icon(Symbols.arrow_forward),
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
                    SizedBox(
                      height: 180,
                      child: Material(
                        child: GridView.builder(
                          scrollDirection: Axis.horizontal,

                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 0.3,
                              ),
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
                      ),
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
                    IconButton(
                      onPressed: _openLatestScreen,
                      icon: Icon(Symbols.arrow_forward),
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

        Widget buildTopAppsSection() {
          final allTopApps = appProvider.topApps;
          final carouselApps = allTopApps.take(_previewLimit).toList();
          final listApps = allTopApps
              .skip(_previewLimit)
              .take(_previewLimit)
              .toList();
          final isTopAppsLoading =
              appProvider.topAppsState == LoadingState.loading;

          return Column(
            spacing: 16.0,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly Top Apps',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'from IzzyOnDroid',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: _openTopAppsScreen,
                      icon: Icon(Symbols.arrow_forward),
                    ),
                  ],
                ),
              ),
              if (isTopAppsLoading && carouselApps.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.0),
                  child: Center(
                    child: CircularProgressIndicator(year2023: false),
                  ),
                )
              else if (carouselApps.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Symbols.apps, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'No apps from IzzyOnDroid',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                SizedBox(
                  height: 200,
                  child: CarouselView(
                    itemExtent: 350,
                    itemSnapping: true,
                    shrinkExtent: 100,
                    onTap: (index) => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            AppDetailsScreen(app: carouselApps[index]),
                      ),
                    ),
                    children: carouselApps.asMap().entries.map((entry) {
                      final app = entry.value;
                      return Material(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                isDarkKnight
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerLow
                                    : Theme.of(context).colorScheme.tertiary
                                          .withValues(alpha: 0.5),
                                // Theme.of(context).colorScheme.tertiary,
                                isDarkKnight
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerLowest
                                    : Theme.of(context).colorScheme.tertiary,
                              ],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 24,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Consumer2<AppProvider, DownloadProvider>(
                                  builder: (context, appProvider, downloadProvider, _) {
                                    final version = app.latestVersion;
                                    final isDownloading = version != null
                                        ? downloadProvider.isDownloading(
                                            app.packageName,
                                            version.versionName,
                                          )
                                        : false;
                                    final progress = version != null
                                        ? downloadProvider.getProgress(
                                            app.packageName,
                                            version.versionName,
                                          )
                                        : 0.0;
                                    return SizedBox(
                                      width: 72,
                                      height: 72,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          AnimatedOpacity(
                                            opacity: isDownloading ? 1.0 : 0.0,
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            child: SizedBox(
                                              width: 86,
                                              height: 86,
                                              child: Center(
                                                child: CircularProgressIndicator(
                                                  value: isDownloading
                                                      ? progress
                                                      : null,
                                                  strokeWidth: 2,
                                                  backgroundColor:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .surfaceContainerHighest,
                                                ),
                                              ),
                                            ),
                                          ),
                                          AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            curve: Curves.easeInOut,
                                            width: isDownloading ? 24 : 48,
                                            height: isDownloading ? 24 : 48,
                                            clipBehavior: Clip.antiAlias,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                            ),
                                            child: MultiIcon(app: app),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),

                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        app.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontVariations: [
                                            FontVariation('wght', 700),
                                            FontVariation('ROND', 100),
                                          ],
                                          fontSize: 18,
                                          color: isDarkKnight
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.onSurface
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.onPrimary,
                                        ),
                                      ),
                                      if (appProvider.topAppsDownloads
                                          .containsKey(app.packageName))
                                        Text(
                                          '${_formatDownloads(appProvider.topAppsDownloads[app.packageName]!)} downloads',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontVariations: [
                                              FontVariation('wght', 400),
                                              FontVariation('ROND', 0),
                                            ],
                                            color: isDarkKnight
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface
                                                : Theme.of(
                                                    context,
                                                  ).colorScheme.onPrimary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                if (listApps.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: listApps.length,
                    itemBuilder: (context, index) {
                      final app = listApps[index];
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
            ],
          );
        }

        return RefreshIndicator(
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
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
                      SizedBox(height: 4),
                      if (settingsProvider.showKeepAndroidOpenCard)
                        Padding(
                              padding: const EdgeInsets.only(
                                left: 8.0,
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
                      if (_isIzzyOnDroidEnabled(repositoriesProvider))
                        buildTopAppsSection(),
                      buildRecentSection(),
                      buildNewReleasesSection(),

                      if (isFlorid || isDarkKnight) const SizedBox(height: 86),
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
