import 'package:florid/l10n/app_localizations.dart';
import 'package:florid/models/fdroid_app.dart';
import 'package:florid/providers/app_provider.dart';
import 'package:florid/providers/download_provider.dart';
import 'package:florid/providers/settings_provider.dart';
import 'package:florid/screens/app_details/app_details_screen.dart';
import 'package:florid/utils/menu_actions.dart';
import 'package:florid/widgets/app_list_item.dart';
import 'package:florid/widgets/changelog_preview.dart';
import 'package:florid/widgets/m_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:solar_icons/solar_icons.dart';

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  bool get wantKeepAlive => true;

  void _loadData() {
    final appProvider = context.read<AppProvider>();
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
    final settingsProvider = context.watch<SettingsProvider>();
    final isDarkKnight = settingsProvider.themeStyle == ThemeStyle.darkKnight;

    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final repositoryLoaded = appProvider.repository != null;
        final repositoryState = appProvider.repositoryState;
        final repositoryError = appProvider.repositoryError;
        final installedAppsState = appProvider.installedAppsState;
        final installedApps = appProvider.installedApps;

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
                  label: Text(AppLocalizations.of(context)!.retry),
                ),
              ],
            ),
          );
        }

        return FutureBuilder<List<FDroidApp>>(
          future: repositoryLoaded
              ? appProvider.getUpdatableApps()
              : Future.value(<FDroidApp>[]),
          builder: (context, snapshot) {
            final updatableApps = snapshot.data ?? <FDroidApp>[];

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
            final updatedPackageNames = updatableApps
                .map((app) => app.packageName)
                .toSet();
            final installedOnlyApps = allFDroidApps
                .where((app) => !updatedPackageNames.contains(app.packageName))
                .toList();
            final isDark = Theme.of(context).brightness == Brightness.dark;
            // final bottomPadding =
            //     settingsProvider.themeStyle == ThemeStyle.florid ||
            //         settingsProvider.themeStyle == ThemeStyle.darkKnight
            //     ? 96.0
            //     : 16.0;

            Widget content;
            if (repositoryState == LoadingState.loading && !repositoryLoaded) {
              content = Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(AppLocalizations.of(context)!.loading_repository),
                  ],
                ),
              );
            } else if (!repositoryLoaded &&
                repositoryState == LoadingState.error) {
              content = _buildRepositoryError(context, repositoryError);
            } else {
              content = _buildUnifiedList(
                context,
                appProvider,
                settingsProvider,
                updatableApps,
                installedOnlyApps,
                allFDroidApps,
                // bottomPadding,
              );
            }

            return Scaffold(
              body: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverAppBar(
                    snap: true,
                    floating: true,
                    backgroundColor: isDark
                        ? Theme.of(context).colorScheme.surfaceContainerLowest
                        : Theme.of(context).colorScheme.surface,
                    surfaceTintColor: isDark
                        ? Theme.of(context).colorScheme.surfaceContainerLowest
                        : Theme.of(context).colorScheme.surface,
                    title: Text(AppLocalizations.of(context)!.on_device),
                    scrolledUnderElevation: isDarkKnight ? 0 : null,
                    shape: LinearBorder(
                      bottom: LinearBorderEdge(),
                      side: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerLow,
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Symbols.refresh),
                        onPressed: _onRefresh,
                        tooltip: AppLocalizations.of(context)!.refresh,
                      ),
                    ],
                  ),
                ],
                body: RefreshIndicator(onRefresh: _onRefresh, child: content),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRepositoryError(BuildContext context, String? repositoryError) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 16,
          children: [
            Icon(
              Symbols.cloud_off,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            Text(
              'Unable to load repository',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (repositoryError != null)
              SelectableText(
                repositoryError.replaceAll('Exception: ', ''),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            Text(
              'Check your connection or repository settings, then try again.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Symbols.refresh),
                  label: Text(AppLocalizations.of(context)!.retry),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => MenuActions.showSettings(context),
                  icon: const Icon(Symbols.settings),
                  label: Text(AppLocalizations.of(context)!.settings),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnifiedList(
    BuildContext context,
    AppProvider appProvider,
    SettingsProvider settingsProvider,
    List<FDroidApp> updatableApps,
    List<FDroidApp> installedOnlyApps,
    List<FDroidApp> allFDroidApps,
    // double bottomPadding,
  ) {
    final widgets = <Widget>[];

    if (updatableApps.isNotEmpty) {
      widgets.add(
        MListHeader(
          icon: SolarIconsOutline.downloadMinimalistic,
          title: AppLocalizations.of(context)!.updates,
          subtitle:
              '${updatableApps.length} ${updatableApps.length == 1 ? 'update' : 'updates'} available',
          trailing: TextButton(
            onPressed: () => _updateAllApps(context, updatableApps),
            child: Text(AppLocalizations.of(context)!.update_all),
          ),
        ),
      );

      for (var index = 0; index < updatableApps.length; index++) {
        final app = updatableApps[index];
        final installedApp = appProvider.getInstalledApp(app.packageName);

        widgets.add(
          Card(
            child: Container(
              key: Key(app.packageName),
              child: Column(
                children: [
                  AppListItem(
                    app: app,
                    showInstallStatus: true,
                    onUpdate: () => _updateApp(context, app),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AppDetailsScreen(app: app),
                        ),
                      );
                    },
                  ),
                  if (installedApp != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(
                        children: [
                          Text(
                            'Update from ${installedApp.versionName ?? 'Unknown'}',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
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
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  if (app.latestVersion?.whatsNew != null &&
                      app.latestVersion!.whatsNew!.isNotEmpty &&
                      settingsProvider.showWhatsNew)
                    ChangelogPreview(text: app.latestVersion!.whatsNew),
                ],
              ).animate().fadeIn(duration: 300.ms),
            ),
          ),
        );
      }
    }

    if (updatableApps.isNotEmpty) {
      widgets.add(SizedBox(height: 16));
    }

    widgets.add(
      MListHeader(
        icon: SolarIconsOutline.devices,
        title: AppLocalizations.of(context)!.installed,
      ),
    );

    if (allFDroidApps.isEmpty) {
      widgets.add(
        Container(
          height: MediaQuery.of(context).size.height * 0.6,
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
    } else if (installedOnlyApps.isEmpty) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Text(
            'All installed F-Droid apps already have updates available.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    } else {
      for (var index = 0; index < installedOnlyApps.length; index++) {
        final app = installedOnlyApps[index];
        widgets.add(
          Card(
            clipBehavior: Clip.antiAlias,
            child: Container(
              key: Key(app.packageName),
              child: Column(
                children: [
                  AppListItem(
                    app: app,
                    showInstallStatus: false,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AppDetailsScreen(app: app),
                        ),
                      );
                    },
                  ),
                  if (app.latestVersion?.whatsNew != null &&
                      app.latestVersion!.whatsNew!.isNotEmpty &&
                      settingsProvider.showWhatsNew)
                    ChangelogPreview(text: app.latestVersion!.whatsNew),
                ],
              ).animate().fadeIn(duration: 300.ms),
            ),
          ),
        );
      }
    }

    return ListView(
      padding: EdgeInsets.all(8),
      physics: const AlwaysScrollableScrollPhysics(),
      children: widgets,
    );
  }

  Future<void> _updateApp(BuildContext context, FDroidApp app) async {
    final downloadProvider = context.read<DownloadProvider>();
    final appProvider = context.read<AppProvider>();

    final downloadInfo = downloadProvider.getDownloadInfo(
      app.packageName,
      app.latestVersion?.versionName ?? '',
    );
    if (downloadInfo?.status == DownloadStatus.downloading) {
      return;
    }

    try {
      await downloadProvider.downloadApk(app, requireInstallAuth: false);

      if (context.mounted) {
        await Future.delayed(const Duration(seconds: 3));
        await appProvider.fetchInstalledApps();
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
          ).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.update_failed_with_error(errorMsg),
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _updateAllApps(
    BuildContext context,
    List<FDroidApp> apps,
  ) async {
    if (apps.isEmpty) return;

    final downloadProvider = context.read<DownloadProvider>();
    final appProvider = context.read<AppProvider>();
    for (final app in apps) {
      try {
        downloadProvider.queueDownload(app);
      } catch (_) {
        // If queueing fails, continue with the remaining apps.
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            )!.starting_download_of_updates(apps.length),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    int successful = 0;
    int failed = 0;

    for (final app in apps) {
      final queuedInfo = downloadProvider.getDownloadInfo(
        app.packageName,
        app.latestVersion?.versionName ?? '',
      );
      if (queuedInfo?.status == DownloadStatus.cancelled) {
        continue;
      }

      try {
        downloadProvider.downloadApk(app, requireInstallAuth: false);
        successful++;

        if (context.mounted) {
          await Future.delayed(const Duration(seconds: 2));
          await appProvider.fetchInstalledApps();
        }

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
