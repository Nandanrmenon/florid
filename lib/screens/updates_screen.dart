import 'package:florid/utils/menu_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../models/fdroid_app.dart';
import '../providers/app_provider.dart';
import '../providers/download_provider.dart';
import '../widgets/app_list_item.dart';
import 'app_details_screen.dart';

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  void _loadData() {
    final appProvider = context.read<AppProvider>();
    // Load both repository data and installed apps
    appProvider.fetchRepository();
    appProvider.fetchInstalledApps();
  }

  Future<void> _onRefresh() async {
    final appProvider = context.read<AppProvider>();
    await Future.wait([appProvider.refreshAll()]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final repositoryLoaded = appProvider.repository != null;
        final installedAppsState = appProvider.installedAppsState;
        final installedApps = appProvider.installedApps;

        // Show loading if data is still being fetched
        if (!repositoryLoaded || installedAppsState == LoadingState.loading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(year2023: false),
                SizedBox(height: 16),
                Text('Checking for updates...'),
              ],
            ),
          );
        }

        // Show error if failed to load installed apps
        if (installedAppsState == LoadingState.error) {
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
                  'Failed to check installed apps',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Unable to access device app list',
                  textAlign: TextAlign.center,
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

        final updatableApps = appProvider.getUpdatableApps();

        // Get all F-Droid apps installed on device
        final allFDroidApps = installedApps
            .where(
              (installedApp) =>
                  appProvider.repository?.apps[installedApp.packageName] !=
                  null,
            )
            .map(
              (installedApp) =>
                  appProvider.repository!.apps[installedApp.packageName]!,
            )
            .toList();

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
            surfaceTintColor: Theme.of(context).colorScheme.surfaceContainerLow,
            title: const Text('Apps'),
            actions: [
              IconButton(
                onPressed: () {
                  _onRefresh();
                },
                icon: Icon(Symbols.refresh),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'settings':
                      MenuActions.showSettings(context);
                      break;
                    case 'about':
                      MenuActions.showAbout(context);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'settings',
                    child: ListTile(
                      leading: Icon(Symbols.settings),
                      title: Text('Settings'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'about',
                    child: ListTile(
                      leading: Icon(Symbols.info),
                      title: Text('About'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
            bottom: TabBar(
              dividerHeight: 0,
              controller: _tabController,
              tabs: [
                Tab(
                  text: updatableApps.isNotEmpty
                      ? 'Updates (${updatableApps.length})'
                      : 'Updates',
                ),
                Tab(text: 'On Device'),
              ],
            ),
          ),
          body: RefreshIndicator(
            onRefresh: _onRefresh,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Updates Only
                _buildUpdatesTab(context, appProvider, updatableApps),

                // Tab 2: All Installed F-Droid Apps
                _buildInstalledAppsTab(context, appProvider, allFDroidApps),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUpdatesTab(
    BuildContext context,
    AppProvider appProvider,
    List<FDroidApp> updatableApps,
  ) {
    if (updatableApps.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Symbols.check_circle, size: 64, color: Colors.green[400]),
              const SizedBox(height: 16),
              Text(
                'All apps are up to date!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'No updates available',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _updateAllApps(context, updatableApps),
        icon: const Icon(Symbols.system_update),
        label: const Text('Update All'),
      ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
      body: Column(
        children: [
          // Header
          Container(
            margin: EdgeInsets.only(top: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Material(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(99),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(Symbols.system_update),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${updatableApps.length} updates available',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Apps list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemCount: updatableApps.length,
              itemBuilder: (context, index) {
                final app = updatableApps[index];
                final installedApp = appProvider.getInstalledApp(
                  app.packageName,
                );

                return Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              AppListItem(
                                app: app,
                                showInstallStatus: false,
                                onTap: () async {
                                  final screenshots = await context
                                      .read<AppProvider>()
                                      .getScreenshots(app.packageName);
                                  if (!context.mounted) return;
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
                              ),
                              if (installedApp != null)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    12,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Update from ${installedApp.versionName ?? 'Unknown'}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                      ),
                                      Icon(
                                        Symbols.arrow_right_alt,
                                        size: 16,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                      Text(
                                        app.latestVersion?.versionName ??
                                            'Unknown',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Consumer<DownloadProvider>(
                          builder: (context, downloadProvider, _) {
                            final downloadInfo = downloadProvider
                                .getDownloadInfo(
                                  app.packageName,
                                  app.latestVersion?.versionName ?? '',
                                );
                            final isDownloading =
                                downloadInfo?.status ==
                                DownloadStatus.downloading;

                            if (isDownloading) {
                              final progress = downloadProvider.getProgress(
                                app.packageName,
                                app.latestVersion?.versionName ?? '',
                              );
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                    value: progress,
                                    year2023: false,
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      downloadProvider.cancelDownload(
                                        app.packageName,
                                        app.latestVersion?.versionName ?? '',
                                      );
                                    },
                                    icon: Icon(Symbols.close),
                                  ),
                                ],
                              );
                            }

                            return OutlinedButton(
                              onPressed: () => _updateApp(context, app),
                              child: const Text('Update'),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 300.ms, delay: (100 * index).ms);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstalledAppsTab(
    BuildContext context,
    AppProvider appProvider,
    List<FDroidApp> allFDroidApps,
  ) {
    if (allFDroidApps.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Symbols.check_circle, size: 64, color: Colors.green[400]),
              const SizedBox(height: 16),
              Text(
                'No F-Droid apps installed',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'No F-Droid apps are installed on this device',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: allFDroidApps.length,
      itemBuilder: (context, index) {
        final app = allFDroidApps[index];
        final installedApp = appProvider.getInstalledApp(app.packageName);
        final updatableApps = appProvider.getUpdatableApps();
        final hasUpdate = updatableApps.any(
          (updateApp) => updateApp.packageName == app.packageName,
        );

        return Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AppListItem(
                        app: app,
                        showInstallStatus: false,
                        onTap: () async {
                          final screenshots = await context
                              .read<AppProvider>()
                              .getScreenshots(app.packageName);
                          if (!context.mounted) return;
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
                      ),
                      if (installedApp != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Row(
                            children: [
                              if (hasUpdate) ...[
                                Text(
                                  'Update from ${installedApp.versionName ?? 'Unknown'}',
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                ),
                                Icon(
                                  Symbols.arrow_right_alt,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                Text(
                                  app.latestVersion?.versionName ?? 'Unknown',
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                ),
                              ] else ...[
                                Icon(
                                  Symbols.check_circle,
                                  size: 16,
                                  color: Colors.green[400],
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Up to date (${installedApp.versionName ?? 'Unknown'})',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Consumer<DownloadProvider>(
                  builder: (context, downloadProvider, _) {
                    final downloadInfo = downloadProvider.getDownloadInfo(
                      app.packageName,
                      app.latestVersion?.versionName ?? '',
                    );
                    final isDownloading =
                        downloadInfo?.status == DownloadStatus.downloading;

                    if (isDownloading) {
                      final progress = downloadProvider.getProgress(
                        app.packageName,
                        app.latestVersion?.versionName ?? '',
                      );
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            value: progress,
                            year2023: false,
                          ),
                          IconButton(
                            onPressed: () {
                              downloadProvider.cancelDownload(
                                app.packageName,
                                app.latestVersion?.versionName ?? '',
                              );
                            },
                            icon: Icon(Symbols.close),
                          ),
                        ],
                      );
                    }
                    if (hasUpdate) {
                      return OutlinedButton(
                        onPressed: () => _updateApp(context, app),
                        child: const Text('Update'),
                      );
                    } else {
                      return SizedBox(width: 8);
                    }
                  },
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 300.ms, delay: (100 * index).ms);
      },
    );
  }

  Future<void> _updateApp(BuildContext context, FDroidApp app) async {
    final downloadProvider = context.read<DownloadProvider>();

    // Check if already downloading
    final downloadInfo = downloadProvider.getDownloadInfo(
      app.packageName,
      app.latestVersion?.versionName ?? '',
    );
    if (downloadInfo?.status == DownloadStatus.downloading) {
      return; // Already downloading, don't start again
    }

    try {
      // Download the app (permission is handled internally by downloadProvider)
      await downloadProvider.downloadApk(app);

      // The download provider handles installation automatically
      // Just clean up the APK file after a delay
      if (context.mounted) {
        await Future.delayed(const Duration(seconds: 3));
        final finalDownloadInfo = downloadProvider.getDownloadInfo(
          app.packageName,
          app.latestVersion!.versionName,
        );
        if (finalDownloadInfo?.filePath != null) {
          await downloadProvider.deleteDownloadedFile(
            finalDownloadInfo!.filePath!,
          );
        }
      }
    } catch (e) {
      final errorMsg = e.toString();
      if (!errorMsg.contains('cancelled') && !errorMsg.contains('Cancelled')) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Update failed: $errorMsg')));
        }
      }
    }
  }

  Future<void> _updateAllApps(
    BuildContext context,
    List<FDroidApp> apps,
  ) async {
    if (apps.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Symbols.system_update, size: 48),
        title: const Text('Update All Apps?'),
        content: Text(
          'This will download and install ${apps.length} app updates.\n\n'
          'The downloads will happen one at a time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Update All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final downloadProvider = context.read<DownloadProvider>();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Starting download of ${apps.length} updates...'),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // Download apps one by one
    int successful = 0;
    int failed = 0;

    for (final app in apps) {
      try {
        await downloadProvider.downloadApk(app);
        successful++;

        // Clean up APK after installation
        await Future.delayed(const Duration(seconds: 2));
        final downloadInfo = downloadProvider.getDownloadInfo(
          app.packageName,
          app.latestVersion!.versionName,
        );
        if (downloadInfo?.filePath != null) {
          await downloadProvider.deleteDownloadedFile(downloadInfo!.filePath!);
        }
      } catch (e) {
        final errorMsg = e.toString();
        if (!errorMsg.contains('cancelled') &&
            !errorMsg.contains('Cancelled')) {
          failed++;
        }
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Updates complete: $successful successful${failed > 0 ? ', $failed failed' : ''}',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
