import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../models/fdroid_app.dart';
import '../providers/app_provider.dart';
import '../providers/download_provider.dart';

class AppListItem extends StatelessWidget {
  final FDroidApp app;
  final VoidCallback? onTap;
  final bool showCategory;
  final bool showInstallStatus;

  const AppListItem({
    super.key,
    required this.app,
    this.onTap,
    this.showCategory = true,
    this.showInstallStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      onLongPress: () => _showQuickViewModal(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      // minLeadingWidth: 64,
      leading: Consumer2<AppProvider, DownloadProvider>(
        builder: (context, appProvider, downloadProvider, _) {
          final isInstalled = appProvider.isAppInstalled(app.packageName);
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
                  duration: const Duration(milliseconds: 300),
                  child: SizedBox(
                    width: 86,
                    height: 86,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: isDownloading ? progress : null,
                        strokeWidth: 2,
                        year2023: false,
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
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  child: _MultiIcon(app: app),
                ),
              ],
            ),
          );
        },
      ),
      title: Text(
        app.name,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(app.summary, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Visibility(
        visible: showInstallStatus,
        child: Consumer<AppProvider>(
          builder: (context, appProvider, _) {
            final isInstalled = appProvider.isAppInstalled(app.packageName);
            if (isInstalled) {
              return Icon(Symbols.check_circle, weight: 400);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
      dense: true,
    );
  }

  void _showQuickViewModal(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isDismissible: true,
      builder: (context) => _QuickViewModal(app: app, onViewDetails: onTap),
    );
  }
}

class _MultiIcon extends StatefulWidget {
  final FDroidApp app;
  const _MultiIcon({required this.app});

  @override
  State<_MultiIcon> createState() => _MultiIconState();
}

class _MultiIconState extends State<_MultiIcon> {
  late List<String> _candidates;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _candidates = widget.app.iconUrls;
  }

  void _tryNext() {
    if (!mounted) return;
    if (_index < _candidates.length - 1) {
      setState(() {
        _index++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_index >= _candidates.length) {
      // No more URLs to try, show fallback
      return Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Icon(Symbols.android, color: theme.colorScheme.onSurfaceVariant),
      );
    }

    final url = _candidates[_index];

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: theme.colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, year2023: false),
        ),
      ),
      errorWidget: (context, url, error) {
        // Try next URL on error
        Future.microtask(_tryNext);
        return Container(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            Symbols.image_not_supported,
            color: theme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
        );
      },
      // Suppress error logs
      errorListener: (error) {
        // Silently catch errors - no logging
      },
    );
  }
}

class _DownloadButton extends StatelessWidget {
  final FDroidApp app;

  const _DownloadButton({required this.app});

  @override
  Widget build(BuildContext context) {
    if (app.latestVersion == null) {
      return const SizedBox.shrink();
    }

    return Consumer<DownloadProvider>(
      builder: (context, downloadProvider, child) {
        final version = app.latestVersion!;
        final isDownloading = downloadProvider.isDownloading(
          app.packageName,
          version.versionName,
        );
        final isDownloaded = downloadProvider.isDownloaded(
          app.packageName,
          version.versionName,
        );
        final progress = downloadProvider.getProgress(
          app.packageName,
          version.versionName,
        );

        if (isDownloading) {
          return SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              year2023: false,
            ),
          );
        }

        return IconButton(
          onPressed: () async {
            if (isDownloaded) {
              // Install APK
              try {
                final downloadInfo = downloadProvider.getDownloadInfo(
                  app.packageName,
                  version.versionName,
                );
                if (downloadInfo?.filePath != null) {
                  // Request install permission first
                  final hasPermission = await downloadProvider
                      .requestInstallPermission();
                  if (!hasPermission) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Install permission is required to install APK files',
                          ),
                        ),
                      );
                    }
                    return;
                  }

                  await downloadProvider.installApk(downloadInfo!.filePath!);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${app.name} installation started!'),
                      ),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Installation failed: ${e.toString()}'),
                    ),
                  );
                }
              }
            } else {
              // Download APK
              try {
                await downloadProvider.downloadApk(app);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${app.name} downloaded successfully!'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Download failed: ${e.toString()}')),
                  );
                }
              }
            }
          },
          icon: Icon(isDownloaded ? Symbols.install_mobile : Symbols.download),
          tooltip: isDownloaded ? 'Install' : 'Download',
        );
      },
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

        return Column(
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
                                year2023: false,
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
                              color: theme.colorScheme.surfaceContainerHighest,
                            ),
                            child: _MultiIcon(app: app),
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
                    Icon(Symbols.arrow_right_alt_rounded),
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
                      label: const Text('Installed'),
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
                        label: const Text('View Details'),
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
                                label: const Text('Cancel'),
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
                                              const SnackBar(
                                                content: Text(
                                                  'Install permission required',
                                                ),
                                              ),
                                            );
                                          }
                                          return;
                                        }

                                        await downloadProvider.installApk(
                                          downloadInfo!.filePath!,
                                        );
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '${app.name} installation started!',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Installation failed: ${e.toString()}',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  } else {
                                    // Download
                                    try {
                                      await downloadProvider.downloadApk(app);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '${app.name} download started!',
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Download failed: ${e.toString()}',
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
                                  isDownloaded ? 'Install' : 'Download',
                                ),
                              ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
