import 'package:florid/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:solar_icons/solar_icons.dart';

import '../models/fdroid_app.dart';
import '../providers/app_provider.dart';
import '../providers/download_provider.dart';
import 'app_details_icon.dart';

class AppListItem extends StatelessWidget {
  final FDroidApp app;
  final String? heroTag;
  final VoidCallback? onTap;
  final VoidCallback? onUpdate;
  final bool showCategory;
  final bool showInstallStatus;
  final bool showFavorite;
  final bool showDescription;
  final bool showRanking;
  final String? rankingNumber;

  const AppListItem({
    super.key,
    required this.app,
    this.heroTag,
    this.onTap,
    this.onUpdate,
    this.showCategory = true,
    this.showInstallStatus = true,
    this.showFavorite = false,
    this.showDescription = true,
    this.showRanking = false,
    this.rankingNumber,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    return InkWell(
      onTap: onTap,
      onLongPress: () => _showQuickViewModal(context),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.only(
          left: 4.0,
          top: 4.0,
          bottom: 4.0,
          right: 16.0,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
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
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showRanking)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          '$rankingNumber',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedOpacity(
                            opacity: isDownloading ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: SizedBox(
                              width: 86,
                              height: 86,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: isDownloading ? progress : null,
                                  strokeWidth: 2,
                                  backgroundColor:
                                      theme.colorScheme.surfaceContainerHighest,
                                ),
                              ),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            width: isDownloading ? 24 : 48,
                            height: isDownloading ? 24 : 48,
                            clipBehavior: Clip.antiAlias,
                            decoration: const BoxDecoration(),
                            child: Hero(
                              tag: heroTag ?? app.packageName,
                              child: AppDetailsIcon(app: app),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    app.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (showDescription) ...[
                    Text(
                      app.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showInstallStatus || showFavorite) ...[
              const SizedBox(width: 12),
              Consumer2<AppProvider, DownloadProvider>(
                builder: (context, appProvider, downloadProvider, _) {
                  final isFavorite = appProvider.isFavorite(app.packageName);

                  return FutureBuilder<FDroidVersion?>(
                    future: appProvider.getLatestVersion(app),
                    builder: (context, snapshot) {
                      final latestVersion = snapshot.data;
                      final isInstalled = appProvider.isAppInstalled(
                        app.packageName,
                      );
                      final installedApp = appProvider.getInstalledApp(
                        app.packageName,
                      );
                      final isDownloading =
                          latestVersion != null &&
                          downloadProvider.isDownloading(
                            app.packageName,
                            latestVersion.versionName,
                          );
                      final isQueued =
                          latestVersion != null &&
                          downloadProvider.isQueued(
                            app.packageName,
                            latestVersion.versionName,
                          );

                      // Check for real updates: not just rebuilds with same versionName or SHA256
                      final hasUpdate =
                          isInstalled &&
                          installedApp != null &&
                          installedApp.versionCode != null &&
                          latestVersion != null &&
                          installedApp.versionCode! <
                              latestVersion.versionCode &&
                          !(installedApp.sha256 != null &&
                              installedApp.sha256!.isNotEmpty &&
                              installedApp.sha256 == latestVersion.hash) &&
                          !(installedApp.versionName != null &&
                              installedApp.versionName ==
                                  latestVersion.versionName);

                      final statusWidget = showInstallStatus
                          ? (isDownloading || isQueued)
                                ? IconButton.filledTonal(
                                    onPressed: () =>
                                        downloadProvider.cancelDownload(
                                          app.packageName,
                                          latestVersion.versionName,
                                        ),
                                    icon: const Icon(Symbols.close),
                                    tooltip: 'Cancel download',
                                  )
                                : hasUpdate
                                ? IconButton.filledTonal(
                                    onPressed: onUpdate,
                                    icon: Icon(
                                      SolarIconsBold.downloadMinimalistic,
                                    ),
                                    tooltip: 'Update',
                                  )
                                : isInstalled
                                ? Icon(
                                    SolarIconsBold.checkCircle,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  )
                                : const SizedBox.shrink()
                          : const SizedBox.shrink();

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (showInstallStatus) statusWidget,
                          if (showFavorite)
                            IconButton(
                              tooltip: isFavorite
                                  ? localizations.remove_from_favourites
                                  : localizations.add_to_favourites,
                              icon: Icon(
                                Symbols.favorite_rounded,
                                fill: isFavorite ? 1 : 0,
                                color: isFavorite ? Colors.red : null,
                              ),
                              onPressed: () {
                                appProvider.toggleFavorite(app.packageName);
                              },
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showQuickViewModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      builder: (context) => _QuickViewModal(app: app, onViewDetails: onTap),
    );
  }
}

class _QuickViewModal extends StatelessWidget {
  final FDroidApp app;
  final VoidCallback? onViewDetails;

  const _QuickViewModal({required this.app, this.onViewDetails});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return Consumer2<AppProvider, DownloadProvider>(
      builder: (context, appProvider, downloadProvider, _) {
        final isInstalled = appProvider.isAppInstalled(app.packageName);
        final version = app.latestVersion;
        final isDownloading = version != null
            ? downloadProvider.isDownloading(
                app.packageName,
                version.versionName,
              )
            : false;
        final isDownloaded = version != null
            ? downloadProvider.isDownloaded(
                app.packageName,
                version.versionName,
              )
            : false;
        final progress = version != null
            ? downloadProvider.getProgress(app.packageName, version.versionName)
            : 0.0;

        return Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with app icon and info
              InkWell(
                onTap: onViewDetails != null
                    ? () {
                        Navigator.pop(context);
                        onViewDetails!();
                      }
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    spacing: 16,
                    children: [
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedOpacity(
                              opacity: isDownloading ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 300),
                              child: SizedBox(
                                width: 64,
                                height: 64,
                                child: CircularProgressIndicator(
                                  value: isDownloading ? progress : null,
                                  strokeWidth: 4,
                                  backgroundColor:
                                      theme.colorScheme.surfaceContainerHighest,
                                ),
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              width: isDownloading ? 32 : 48,
                              height: isDownloading ? 32 : 48,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                              ),
                              child: AppDetailsIcon(app: app),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 4,
                          children: [
                            Text(
                              app.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              app.packageName,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (version != null)
                              Text(
                                'v${version.versionName}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(SolarIconsOutline.arrowRight),
                    ],
                  ),
                ),
              ),
              // Status badges
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (isInstalled)
                      Chip(
                        label: Text(localizations.installed),
                        avatar: const Icon(Symbols.check_circle, size: 18),
                        backgroundColor: theme.colorScheme.primaryContainer,
                        labelStyle: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    if (version != null && app.license.isNotEmpty)
                      Chip(
                        label: Text(app.license),
                        backgroundColor: theme.colorScheme.secondaryContainer,
                        labelStyle: TextStyle(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                  ],
                ),
              ),
              // Action buttons
              SafeArea(
                bottom: true,
                child: Padding(
                  padding: const EdgeInsets.only(
                    bottom: 16.0,
                    left: 16.0,
                    right: 16.0,
                    top: 8.0,
                  ),
                  child: Row(
                    spacing: 8,
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: onViewDetails != null
                              ? () {
                                  Navigator.pop(context);
                                  onViewDetails!();
                                }
                              : null,
                          icon: const Icon(Symbols.info),
                          label: Text(localizations.view_details),
                        ),
                      ),
                      if (version != null)
                        Expanded(
                          child: isDownloading
                              ? FilledButton.tonalIcon(
                                  onPressed: () {
                                    downloadProvider.cancelDownload(
                                      app.packageName,
                                      version.versionName,
                                    );
                                  },
                                  style: FilledButton.styleFrom(
                                    foregroundColor:
                                        theme.colorScheme.onErrorContainer,
                                    backgroundColor:
                                        theme.colorScheme.errorContainer,
                                  ),
                                  icon: const Icon(Symbols.close),
                                  label: Text(localizations.cancel),
                                )
                              : FilledButton.icon(
                                  onPressed: () async {
                                    if (isDownloaded) {
                                      // Install
                                      try {
                                        final downloadInfo = downloadProvider
                                            .getDownloadInfo(
                                              app.packageName,
                                              version.versionName,
                                            );
                                        if (downloadInfo?.filePath != null) {
                                          final hasPermission =
                                              await downloadProvider
                                                  .requestInstallPermission();
                                          if (!hasPermission) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    localizations
                                                        .install_permission_required,
                                                  ),
                                                ),
                                              );
                                            }
                                            return;
                                          }

                                          await downloadProvider.installApk(
                                            downloadInfo!.filePath!,
                                            app.packageName,
                                            version.versionName,
                                            app.name,
                                            antiFeatures: app.antiFeatures,
                                          );
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  localizations
                                                      .installation_started(
                                                        app.name,
                                                      ),
                                                ),
                                              ),
                                            );
                                            await appProvider
                                                .fetchInstalledApps();
                                          }
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                localizations
                                                    .installation_failed_with_error(
                                                      e.toString(),
                                                    ),
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    } else {
                                      // Download
                                      try {
                                        await downloadProvider.downloadApk(
                                          app,
                                          requireInstallAuth: !isInstalled,
                                        );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                localizations.download_started(
                                                  app.name,
                                                ),
                                              ),
                                            ),
                                          );
                                          await appProvider
                                              .fetchInstalledApps();
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                localizations
                                                    .download_failed_with_error(
                                                      e.toString(),
                                                    ),
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  icon: Icon(
                                    isDownloaded
                                        ? Symbols.install_mobile
                                        : Symbols.download,
                                  ),
                                  label: Text(
                                    isDownloaded
                                        ? localizations.install
                                        : localizations.download,
                                  ),
                                ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
