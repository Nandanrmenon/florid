import 'dart:async';

import 'package:florid/l10n/app_localizations.dart';
import 'package:florid/providers/download_provider.dart';
import 'package:florid/providers/settings_provider.dart';
import 'package:florid/screens/settings/repositories_screen.dart';
import 'package:florid/widgets/app_details_icon.dart';
import 'package:florid/widgets/m_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/app_provider.dart';
import '../../providers/repositories_provider.dart';
import '../../utils/responsive.dart';
import '../../widgets/app_list_item.dart';
import '../app_details/app_details_screen.dart';
import '../top_apps/monthly_top_apps_screen.dart';
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

  static const int _previewLimit = 6;
  static const double _topAppsCarouselItemExtent = 350;
  static const Duration _topAppsAutoScrollInterval = Duration(seconds: 8);

  int _topAppsCarouselIndex = 0;
  int _topAppsCarouselItemCount = 0;
  Timer? _topAppsAutoScrollTimer;
  final CarouselController _topAppsCarouselController = CarouselController(
    initialItem: 0,
  );

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

  void _setTopAppsCarouselIndex(int newIndex, int itemCount) {
    if (itemCount <= 0) {
      return;
    }

    final clampedIndex = newIndex.clamp(0, itemCount - 1);
    if (clampedIndex != _topAppsCarouselIndex) {
      setState(() {
        _topAppsCarouselIndex = clampedIndex;
      });
    }
  }

  bool _onTopAppsCarouselScroll(
    ScrollNotification notification,
    int itemCount,
  ) {
    if (itemCount <= 0) {
      return false;
    }

    final currentIndex =
        (notification.metrics.pixels / _topAppsCarouselItemExtent).round();
    _setTopAppsCarouselIndex(currentIndex, itemCount);
    return false;
  }

  void _syncTopAppsAutoScroll(int itemCount) {
    _topAppsCarouselItemCount = itemCount;

    if (itemCount <= 1) {
      _stopTopAppsAutoScroll();
      return;
    }

    if (_topAppsAutoScrollTimer != null) {
      return;
    }

    _topAppsAutoScrollTimer = Timer.periodic(_topAppsAutoScrollInterval, (_) {
      if (!mounted || _topAppsCarouselItemCount <= 1) {
        return;
      }

      final nextIndex = (_topAppsCarouselIndex + 1) % _topAppsCarouselItemCount;
      _setTopAppsCarouselIndex(nextIndex, _topAppsCarouselItemCount);
      _topAppsCarouselController.animateToItem(
        nextIndex,
        duration: const Duration(milliseconds: 450),
        curve: Curves.decelerate,
      );
    });
  }

  void _stopTopAppsAutoScroll() {
    _topAppsAutoScrollTimer?.cancel();
    _topAppsAutoScrollTimer = null;
    _topAppsCarouselItemCount = 0;
  }

  @override
  void dispose() {
    _stopTopAppsAutoScroll();
    _topAppsCarouselController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer3<AppProvider, SettingsProvider, RepositoriesProvider>(
      builder: (context, appProvider, settingsProvider, repositoriesProvider, child) {
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

        Widget buildRecentSection() {
          return LayoutBuilder(
            builder: (context, constraints) => Padding(
              padding: EdgeInsets.only(
                top: Responsive.isLargeWidth(constraints.maxWidth) ? 8.0 : 0,
              ),
              child: Column(
                spacing: 4.0,
                children: [
                  MListHeader(
                    title: AppLocalizations.of(context)!.recently_updated,
                    onTap: _openRecentlyUpdatedScreen,
                    trailing: Icon(Symbols.arrow_forward),
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
                              AppLocalizations.of(
                                context,
                              )!.no_recently_updated_apps,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 200,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                                key: ValueKey(app.packageName),
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
              MListHeader(
                title: AppLocalizations.of(context)!.latest_apps,
                onTap: _openLatestScreen,
                trailing: Icon(Symbols.arrow_forward),
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
                          AppLocalizations.of(context)!.no_new_apps,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Card(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: latestApps.length,
                    itemBuilder: (context, index) {
                      final app = latestApps[index];
                      return AppListItem(
                        key: ValueKey(app.packageName),
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
          _syncTopAppsAutoScroll(carouselApps.length);
          final isTopAppsLoading =
              appProvider.topAppsState == LoadingState.loading;
          final activeTopAppIndex = carouselApps.isEmpty
              ? 0
              : _topAppsCarouselIndex.clamp(0, carouselApps.length - 1);

          return Column(
            spacing: 4.0,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MListHeader(
                title: AppLocalizations.of(context)!.monthly_top_apps,
                subtitle: AppLocalizations.of(context)!.from_izzyondroid,
                onTap: _openTopAppsScreen,
                trailing: Icon(Symbols.arrow_forward),
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
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            Symbols.sync,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppLocalizations.of(context)!.sync_required,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.izzyondroid_sync_required_message,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          FilledButton.tonalIcon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const RepositoriesScreen(),
                                ),
                              );
                            },
                            icon: Icon(Symbols.settings),
                            label: Text(
                              AppLocalizations.of(context)!.go_to_settings,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else ...[
                SizedBox(
                  height: 200,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) => _onTopAppsCarouselScroll(
                      notification,
                      carouselApps.length,
                    ),
                    child: CarouselView.weighted(
                      controller: _topAppsCarouselController,
                      itemSnapping: true,
                      flexWeights: [1],
                      onTap: (index) {
                        _setTopAppsCarouselIndex(index, carouselApps.length);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                AppDetailsScreen(app: carouselApps[index]),
                          ),
                        );
                      },
                      children: carouselApps.asMap().entries.map((entry) {
                        final app = entry.value;
                        final hasFeatureGraphic =
                            app.featureGraphic != null &&
                            app.featureGraphic!.isNotEmpty;
                        return Material(
                          child: Container(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        isDarkKnight
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.surfaceContainerLow
                                            : Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainer
                                                  .withValues(alpha: 0.5),
                                        isDarkKnight
                                            ? Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerLowest
                                            : Theme.of(
                                                context,
                                              ).colorScheme.surfaceContainer,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                ),
                                if (hasFeatureGraphic)
                                  Positioned(
                                    child: ShaderMask(
                                      shaderCallback: (bounds) {
                                        return LinearGradient(
                                          colors: [
                                            Colors.black26,
                                            Colors.black45,
                                            Colors.black87,
                                          ],
                                          stops: const [0.5, 0.8, 1.0],
                                          begin: Alignment(-1, 0),
                                          end: Alignment(1, -1),
                                        ).createShader(bounds);
                                      },
                                      blendMode: BlendMode.dstIn,
                                      child: Image.network(
                                        app.featureGraphic!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) {
                                          return const SizedBox.shrink();
                                        },
                                      ),
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 24,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Consumer2<AppProvider, DownloadProvider>(
                                        builder:
                                            (
                                              context,
                                              appProvider,
                                              downloadProvider,
                                              _,
                                            ) {
                                              final version = app.latestVersion;
                                              final isDownloading =
                                                  version != null
                                                  ? downloadProvider
                                                        .isDownloading(
                                                          app.packageName,
                                                          version.versionName,
                                                        )
                                                  : false;
                                              final progress = version != null
                                                  ? downloadProvider
                                                        .getProgress(
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
                                                      opacity: isDownloading
                                                          ? 1.0
                                                          : 0.0,
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
                                                                Theme.of(
                                                                      context,
                                                                    )
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
                                                      width: isDownloading
                                                          ? 24
                                                          : 48,
                                                      height: isDownloading
                                                          ? 24
                                                          : 48,
                                                      clipBehavior:
                                                          Clip.antiAlias,
                                                      decoration:
                                                          BoxDecoration(),
                                                      child: AppDetailsIcon(
                                                        app: app,
                                                      ),
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
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
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
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                if (carouselApps.length > 1)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4.0, bottom: 2.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(carouselApps.length, (index) {
                          final isActive = index == activeTopAppIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: isActive ? 18 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(
                                      context,
                                    ).colorScheme.outlineVariant,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                if (listApps.isNotEmpty)
                  Card(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: listApps.length,
                      itemBuilder: (context, index) {
                        final app = listApps[index];
                        return AppListItem(
                          key: ValueKey(app.packageName),
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
                  _stopTopAppsAutoScroll();
                  return Row(
                    children: [
                      Expanded(child: buildRecentSection()),
                      Expanded(child: buildNewReleasesSection()),
                    ],
                  ); // Tablet or large screen layout
                } else {
                  if (!_isIzzyOnDroidEnabled(repositoriesProvider) ||
                      !settingsProvider.showMonthlyTopApps) {
                    _stopTopAppsAutoScroll();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 16,
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
                                        AppLocalizations.of(
                                          context,
                                        )!.keep_android_open,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.keep_android_open_message,
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
                                            child: Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.ignore,
                                            ),
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
                                            label: Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.learn_more,
                                            ),
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
                      if (_isIzzyOnDroidEnabled(repositoriesProvider) &&
                          settingsProvider.showMonthlyTopApps)
                        buildTopAppsSection()
                            .animate(delay: Duration(milliseconds: 100))
                            .fadeIn(duration: 300.ms),
                      buildRecentSection()
                          .animate(delay: Duration(milliseconds: 100))
                          .fadeIn(duration: 300.ms),
                      buildNewReleasesSection()
                          .animate(delay: Duration(milliseconds: 100))
                          .fadeIn(duration: 300.ms),

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
