import 'dart:io';

import 'package:florid/screens/permissions_screen.dart';
import 'package:florid/widgets/changelog_preview.dart';
import 'package:florid/widgets/m_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/fdroid_app.dart';
import '../providers/app_provider.dart';
import '../providers/download_provider.dart';
import '../providers/repositories_provider.dart';
import '../services/izzy_stats_service.dart';

class AppDetailsScreen extends StatefulWidget {
  final FDroidApp app;

  const AppDetailsScreen({super.key, required this.app});

  @override
  State<AppDetailsScreen> createState() => _AppDetailsScreenState();
}

class _AppDetailsScreenState extends State<AppDetailsScreen> {
  late Future<List<String>> _screenshotsFuture;
  late Future<IzzyStats> _statsFuture;
  late Future<FDroidApp> _enrichedAppFuture;

  @override
  void initState() {
    super.initState();
    // Fetch screenshots in the background
    _screenshotsFuture = context.read<AppProvider>().getScreenshots(
      widget.app.packageName,
      repositoryUrl: widget.app.repositoryUrl,
    );
    _statsFuture = context.read<IzzyStatsService>().fetchStatsForPackage(
      widget.app.packageName,
    );
    // Enrich app with repository information
    _enrichedAppFuture = context.read<AppProvider>().enrichAppWithRepositories(
      widget.app,
      context.read<RepositoriesProvider>(),
    );
  }

  Widget _buildInstallButton(
    BuildContext context,
    DownloadProvider downloadProvider,
    AppProvider appProvider,
    bool isDownloaded,
    FDroidVersion version,
    FDroidApp app,
  ) {
    final availableRepos = app.availableRepositories;
    final hasMultipleRepos =
        availableRepos != null && availableRepos.length > 1;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: hasMultipleRepos
          ? Row(
              key: const ValueKey('split-button'),
              spacing: 2,
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: () => _handleInstall(
                        context,
                        downloadProvider,
                        appProvider,
                        isDownloaded,
                        version,
                        app.repositoryUrl,
                      ),
                      icon: Icon(
                        isDownloaded
                            ? Symbols.install_mobile
                            : Symbols.download,
                      ),
                      label: Text(isDownloaded ? 'Install' : 'Download'),
                      style: FilledButton.styleFrom(),
                    ),
                  ),
                ),
                SizedBox(
                  height: 48,
                  child: IconButton.filledTonal(
                    onPressed: () => _showRepositorySelection(
                      context,
                      downloadProvider,
                      appProvider,
                      isDownloaded,
                      version,
                      app,
                    ),
                    icon: Icon(Symbols.keyboard_arrow_down),
                  ),
                ),
              ],
            )
          : SizedBox(
              key: const ValueKey('simple-button'),
              height: 48,
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _handleInstall(
                  context,
                  downloadProvider,
                  appProvider,
                  isDownloaded,
                  version,
                  app.repositoryUrl,
                ),
                icon: Icon(
                  isDownloaded ? Symbols.install_mobile : Symbols.download,
                ),
                label: Text(isDownloaded ? 'Install' : 'Download'),
              ),
            ),
    );
  }

  Future<void> _handleInstall(
    BuildContext context,
    DownloadProvider downloadProvider,
    AppProvider appProvider,
    bool isDownloaded,
    FDroidVersion version,
    String repositoryUrl,
  ) async {
    if (isDownloaded) {
      try {
        final downloadInfo = downloadProvider.getDownloadInfo(
          widget.app.packageName,
          version.versionName,
        );
        if (downloadInfo?.filePath != null) {
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
          await Future.delayed(const Duration(milliseconds: 100));
          await appProvider.fetchInstalledApps();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${widget.app.name} installation started!'),
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Installation failed: ${e.toString()}')),
          );
        }
      }
    } else {
      final hasPermission = await downloadProvider.requestPermissions();

      if (!hasPermission) {
        if (context.mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              icon: const Icon(Symbols.warning, size: 48),
              title: const Text('Storage Permission Required'),
              content: const Text(
                'Florid needs storage permission to download APK files.\n\n'
                'To enable:\n'
                '1. Go to Settings (button below)\n'
                '2. Find "Permissions"\n'
                '3. Enable "Files and media" or "Storage"\n\n'
                'Then try downloading again.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await openAppSettings();
                  },
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
        }
        return;
      }

      try {
        // Create a copy of the app with the selected repository URL
        final appWithRepo = widget.app.copyWith(repositoryUrl: repositoryUrl);
        await downloadProvider.downloadApk(appWithRepo);

        if (context.mounted) {
          for (int i = 0; i < 15; i++) {
            await Future.delayed(const Duration(milliseconds: 800));
            await appProvider.fetchInstalledApps();
            if (appProvider.isAppInstalled(widget.app.packageName)) {
              final downloadInfo = downloadProvider.getDownloadInfo(
                widget.app.packageName,
                widget.app.latestVersion!.versionName,
              );
              if (downloadInfo?.filePath != null) {
                await downloadProvider.deleteDownloadedFile(
                  downloadInfo!.filePath!,
                );
              }
              break;
            }
          }
        }
      } catch (e) {
        final errorMsg = e.toString();
        if (!errorMsg.contains('cancelled') &&
            !errorMsg.contains('Cancelled')) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Download failed: $errorMsg')),
            );
          }
        }
      }
    }
  }

  Future<void> _showRepositorySelection(
    BuildContext context,
    DownloadProvider downloadProvider,
    AppProvider appProvider,
    bool isDownloaded,
    FDroidVersion version,
    FDroidApp app,
  ) async {
    final availableRepos = app.availableRepositories;
    if (availableRepos == null || availableRepos.isEmpty) return;

    // Capture the mounted context before showing dialog
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    await showModalBottomSheet(
      context: context,
      builder: (dialogContext) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8.0,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDownloaded
                            ? 'Install from Repository'
                            : 'Download from Repository',
                        style: Theme.of(dialogContext).textTheme.titleLarge,
                      ),
                      Text(
                        'You can choose which repository to use to '
                        '${isDownloaded ? 'install' : 'download'} this app.',
                        style: Theme.of(dialogContext).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            MListViewBuilder(
              itemCount: availableRepos.length,
              itemBuilder: (index) {
                final isPrimary =
                    availableRepos[index].url == app.repositoryUrl;
                return MListItemData(
                  selected: isPrimary,
                  leading: isPrimary ? Icon(Symbols.check) : null,
                  title: availableRepos[index].name,
                  onTap: () {
                    Navigator.of(dialogContext).pop();
                    _handleInstall(
                      context,
                      downloadProvider,
                      appProvider,
                      isDownloaded,
                      version,
                      availableRepos[index].url,
                    );
                  },
                  suffix: Visibility(
                    visible: isPrimary,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          dialogContext,
                        ).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Default',
                        style: Theme.of(dialogContext).textTheme.labelSmall
                            ?.copyWith(
                              color: Theme.of(
                                dialogContext,
                              ).colorScheme.onPrimaryContainer,
                            ),
                      ),
                    ),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: FilledButton.tonal(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            pinned: true,
            centerTitle: false,
            title: Row(
              spacing: 16.0,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 48,
                  width: 48,
                  child: Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(8),
                    clipBehavior: Clip.antiAlias,
                    child: _AppDetailsIcon(app: widget.app),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.app.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20,
                          fontVariations: [
                            FontVariation('wght', 700),
                            FontVariation('ROND', 100),
                          ],
                        ),
                      ),
                      Text(
                        'by ${widget.app.authorName ?? 'Unknown'}',
                        style: TextStyle(
                          fontSize: 12,
                          fontVariations: [FontVariation('ROND', 100)],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Symbols.share),
                onPressed: () {
                  SharePlus.instance.share(
                    ShareParams(
                      text:
                          'Check out ${widget.app.name} on F-Droid: https://f-droid.org/packages/${widget.app.packageName}/',
                    ),
                  );
                },
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  switch (value) {
                    case 'website':
                      if (widget.app.webSite != null) {
                        await launchUrl(Uri.parse(widget.app.webSite!));
                      }
                      break;
                    case 'source':
                      if (widget.app.sourceCode != null) {
                        await launchUrl(Uri.parse(widget.app.sourceCode!));
                      }
                      break;
                    case 'issues':
                      if (widget.app.issueTracker != null) {
                        await launchUrl(Uri.parse(widget.app.issueTracker!));
                      }
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (widget.app.webSite != null)
                    const PopupMenuItem(
                      value: 'website',
                      child: ListTile(
                        leading: Icon(Symbols.public),
                        title: Text('Website'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  if (widget.app.sourceCode != null)
                    const PopupMenuItem(
                      value: 'source',
                      child: ListTile(
                        leading: Icon(Symbols.code),
                        title: Text('Source Code'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  if (widget.app.issueTracker != null)
                    const PopupMenuItem(
                      value: 'issues',
                      child: ListTile(
                        leading: Icon(Symbols.bug_report),
                        title: Text('Issue Tracker'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                ],
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                // What's New preview from version.whatsNew
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 16,
                  ),
                  child: Consumer<AppProvider>(
                    builder: (context, appProvider, _) {
                      final isInstalled = appProvider.isAppInstalled(
                        widget.app.packageName,
                      );
                      final installedApp = appProvider.getInstalledApp(
                        widget.app.packageName,
                      );

                      return Column(
                        spacing: 16,
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Consumer2<DownloadProvider, AppProvider>(
                            builder: (context, downloadProvider, appProvider, child) {
                              final version = widget.app.latestVersion!;
                              final isInstalled = appProvider.isAppInstalled(
                                widget.app.packageName,
                              );
                              final installedApp = appProvider.getInstalledApp(
                                widget.app.packageName,
                              );

                              // Check if ANY version of this app is downloading
                              DownloadInfo? activeDownloadInfo;
                              bool isDownloading = false;

                              if (widget.app.packages != null) {
                                for (var pkg in widget.app.packages!.values) {
                                  final info = downloadProvider.getDownloadInfo(
                                    widget.app.packageName,
                                    pkg.versionName,
                                  );
                                  if (info?.status ==
                                      DownloadStatus.downloading) {
                                    activeDownloadInfo = info;
                                    isDownloading = true;
                                    break;
                                  }
                                }
                              }

                              // If no version is downloading, check the latest version for install/download buttons
                              final downloadInfo =
                                  activeDownloadInfo ??
                                  downloadProvider.getDownloadInfo(
                                    widget.app.packageName,
                                    version.versionName,
                                  );
                              final isCancelled =
                                  downloadInfo?.status ==
                                  DownloadStatus.cancelled;
                              final fileExists = downloadInfo?.filePath != null
                                  ? File(downloadInfo!.filePath!).existsSync()
                                  : false;
                              final isDownloaded =
                                  downloadInfo?.status ==
                                      DownloadStatus.completed &&
                                  downloadInfo?.filePath != null &&
                                  !isCancelled &&
                                  fileExists;

                              if (isDownloading && activeDownloadInfo != null) {
                                // Find the version name that's downloading
                                String downloadingVersionName =
                                    version.versionName;
                                if (widget.app.packages != null) {
                                  for (var pkg in widget.app.packages!.values) {
                                    final info = downloadProvider
                                        .getDownloadInfo(
                                          widget.app.packageName,
                                          pkg.versionName,
                                        );
                                    if (info?.status ==
                                        DownloadStatus.downloading) {
                                      downloadingVersionName = pkg.versionName;
                                      break;
                                    }
                                  }
                                }

                                return SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: FilledButton.tonal(
                                    onPressed: () {
                                      downloadProvider.cancelDownload(
                                        widget.app.packageName,
                                        downloadingVersionName,
                                      );
                                    },
                                    child: const Text('Cancel Download'),
                                  ),
                                );
                              }

                              if (isInstalled && installedApp != null) {
                                // Check if update is available
                                final hasUpdate =
                                    installedApp.versionCode != null &&
                                    widget.app.latestVersion!.versionCode >
                                        installedApp.versionCode!;

                                if (hasUpdate) {
                                  // Show Update button
                                  return Column(
                                    spacing: 8,
                                    children: [
                                      Row(
                                        spacing: 8,
                                        children: [
                                          Expanded(
                                            child: SizedBox(
                                              height: 48,
                                              child: FilledButton.icon(
                                                onPressed: () async {
                                                  final hasPermission =
                                                      await downloadProvider
                                                          .requestPermissions();

                                                  if (!hasPermission) {
                                                    if (context.mounted) {
                                                      await showDialog(
                                                        context: context,
                                                        builder: (context) => AlertDialog(
                                                          icon: const Icon(
                                                            Symbols.warning,
                                                            size: 48,
                                                          ),
                                                          title: const Text(
                                                            'Storage Permission Required',
                                                          ),
                                                          content: const Text(
                                                            'Florid needs storage permission to download APK files.\n\n'
                                                            'To enable:\n'
                                                            '1. Go to Settings (button below)\n'
                                                            '2. Find "Permissions"\n'
                                                            '3. Enable "Files and media" or "Storage"\n\n'
                                                            'Then try downloading again.',
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.of(
                                                                    context,
                                                                  ).pop(),
                                                              child: const Text(
                                                                'Cancel',
                                                              ),
                                                            ),
                                                            FilledButton(
                                                              onPressed: () async {
                                                                Navigator.of(
                                                                  context,
                                                                ).pop();
                                                                await openAppSettings();
                                                              },
                                                              child: const Text(
                                                                'Open Settings',
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    }
                                                    return;
                                                  }

                                                  try {
                                                    await downloadProvider
                                                        .downloadApk(
                                                          widget.app,
                                                        );

                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            'Downloading ${widget.app.name} update...',
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
                                                            'Update failed: $e',
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                                icon: const Icon(
                                                  Symbols.upgrade,
                                                ),
                                                label: const Text('Update'),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            height: 48,
                                            child: FilledButton.tonalIcon(
                                              onPressed: () async {
                                                try {
                                                  final opened =
                                                      await appProvider
                                                          .openInstalledApp(
                                                            widget
                                                                .app
                                                                .packageName,
                                                          );
                                                  if (!opened &&
                                                      context.mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Unable to open ${widget.app.name}.',
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
                                                          'Open failed: ${e.toString()}',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                              icon: const Icon(
                                                Symbols.open_in_new_rounded,
                                              ),
                                              label: const Text('Open'),
                                            ),
                                          ),
                                          SizedBox(
                                            height: 48,
                                            child: FilledButton.tonal(
                                              onPressed: () async {
                                                try {
                                                  await downloadProvider
                                                      .uninstallApp(
                                                        widget.app.packageName,
                                                      );
                                                  await Future.delayed(
                                                    const Duration(seconds: 1),
                                                  );
                                                  await appProvider
                                                      .fetchInstalledApps();
                                                } catch (e) {
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Uninstall failed: ${e.toString()}',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                              // label: const Text('Uninstall'),
                                              style: FilledButton.styleFrom(
                                                foregroundColor: Theme.of(
                                                  context,
                                                ).colorScheme.onErrorContainer,
                                                backgroundColor: Theme.of(
                                                  context,
                                                ).colorScheme.errorContainer,
                                              ),
                                              child: const Icon(
                                                Symbols.delete_rounded,
                                                fill: 1,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                }

                                // No update available, show normal buttons
                                return Row(
                                  spacing: 8,
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 48,
                                        child: FilledButton.tonalIcon(
                                          onPressed: () async {
                                            try {
                                              await downloadProvider
                                                  .uninstallApp(
                                                    widget.app.packageName,
                                                  );
                                              await Future.delayed(
                                                const Duration(seconds: 1),
                                              );
                                              await appProvider
                                                  .fetchInstalledApps();
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Uninstall failed: ${e.toString()}',
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          icon: const Icon(
                                            Symbols.delete_rounded,
                                            fill: 1,
                                          ),
                                          label: const Text('Uninstall'),
                                          style: FilledButton.styleFrom(
                                            foregroundColor: Theme.of(
                                              context,
                                            ).colorScheme.onErrorContainer,
                                            backgroundColor: Theme.of(
                                              context,
                                            ).colorScheme.errorContainer,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: SizedBox(
                                        height: 48,
                                        child: FilledButton.icon(
                                          onPressed: () async {
                                            try {
                                              final opened = await appProvider
                                                  .openInstalledApp(
                                                    widget.app.packageName,
                                                  );
                                              if (!opened && context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Unable to open ${widget.app.name}.',
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
                                                      'Open failed: ${e.toString()}',
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          icon: const Icon(
                                            Symbols.open_in_new_rounded,
                                          ),
                                          label: const Text('Open'),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }

                              // return SizedBox(
                              //   width: double.infinity,
                              return FutureBuilder<FDroidApp>(
                                future: _enrichedAppFuture,
                                builder: (context, snapshot) {
                                  // Use enriched app if available and loaded, otherwise fall back to widget.app
                                  final enrichedApp =
                                      snapshot.connectionState ==
                                              ConnectionState.done &&
                                          snapshot.hasData
                                      ? snapshot.data!
                                      : widget.app;

                                  // Log error if enrichment failed
                                  if (snapshot.hasError) {
                                    debugPrint(
                                      'Error enriching app: ${snapshot.error}',
                                    );
                                  }

                                  return SizedBox(
                                    width: double.infinity,
                                    child: _buildInstallButton(
                                      context,
                                      downloadProvider,
                                      appProvider,
                                      isDownloaded,
                                      version,
                                      enrichedApp,
                                    ),
                                  );
                                },
                              );
                            },
                          ).animate().fadeIn(
                            delay: Duration(milliseconds: 300),
                            duration: Duration(milliseconds: 300),
                          ),
                          if (widget.app.latestVersion?.whatsNew != null &&
                              widget.app.latestVersion!.whatsNew!.isNotEmpty)
                            ChangelogPreview(
                              text: widget.app.latestVersion!.whatsNew,
                            ).animate().fadeIn(
                              delay: Duration(milliseconds: 300),
                              duration: Duration(milliseconds: 300),
                            ),
                          if (isInstalled)
                            Chip(
                              visualDensity: VisualDensity.compact,
                              avatar: Icon(Symbols.check_circle, fill: 1),
                              label: Text(
                                'Installed${installedApp?.versionName != null ? ' (${installedApp!.versionName})' : ''}',
                              ),
                            ).animate().fadeIn(
                              delay: Duration(milliseconds: 300),
                              duration: Duration(milliseconds: 300),
                            ),

                          FutureBuilder<IzzyStats>(
                            future: _statsFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const SizedBox.shrink();
                              }
                              if (snapshot.hasError || snapshot.data == null) {
                                return const SizedBox.shrink();
                              }
                              final stats = snapshot.data!;
                              return _DownloadSection(
                                app: widget.app,
                                stats: stats,
                              );
                            },
                          ).animate().fadeIn(
                            delay: Duration(milliseconds: 300),
                            duration: Duration(milliseconds: 300),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // Screenshots section
                FutureBuilder<List<String>>(
                  future: _screenshotsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    }

                    final screenshots = snapshot.data ?? [];
                    if (screenshots.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return _ScreenshotsSection(
                      app: widget.app,
                      screenshots: screenshots,
                    );
                  },
                ).animate().fadeIn(
                  delay: Duration(milliseconds: 300),
                  duration: Duration(milliseconds: 300),
                ),

                if (widget.app.categories?.isNotEmpty == true) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(widget.app.categories!.first),
                    ),
                  ).animate().fadeIn(
                    delay: Duration(milliseconds: 300),
                    duration: Duration(milliseconds: 300),
                  ),
                ],
                // Description
                _DescriptionSection(app: widget.app).animate().fadeIn(
                  delay: Duration(milliseconds: 300),
                  duration: Duration(milliseconds: 300),
                ),

                // App details
                _AppInfoSection(app: widget.app).animate().fadeIn(
                  delay: Duration(milliseconds: 300),
                  duration: Duration(milliseconds: 300),
                ),

                FutureBuilder<IzzyStats>(
                  future: _statsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const _IzzyStatsLoadingCard();
                    }
                    if (snapshot.hasError) {
                      return const _IzzyStatsInfoCard(
                        message:
                            'Unable to load IzzyOnDroid download stats right now.',
                      );
                    }

                    final stats = snapshot.data;
                    if (stats == null || !stats.hasAny) {
                      return const SizedBox.shrink();
                    }

                    return _IzzyStatsSection(
                      packageName: widget.app.packageName,
                      stats: stats,
                    );
                  },
                ).animate().fadeIn(
                  delay: Duration(milliseconds: 300),
                  duration: Duration(milliseconds: 300),
                ),

                // Version info
                if (widget.app.latestVersion != null)
                  _VersionInfoSection(
                    version: widget.app.latestVersion!,
                  ).animate().fadeIn(
                    delay: Duration(milliseconds: 300),
                    duration: Duration(milliseconds: 300),
                  )
                else
                  const _NoVersionInfoSection().animate().fadeIn(
                    delay: Duration(milliseconds: 300),
                    duration: Duration(milliseconds: 300),
                  ),
                // All versions history
                if (widget.app.packages != null &&
                    widget.app.packages!.isNotEmpty)
                  _AllVersionsSection(app: widget.app).animate().fadeIn(
                    delay: Duration(milliseconds: 300),
                    duration: Duration(milliseconds: 300),
                  )
                else
                  const SizedBox.shrink(),
                // Permissions
                SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadSection extends StatefulWidget {
  final FDroidApp app;
  final IzzyStats? stats;

  const _DownloadSection({required this.app, this.stats});

  @override
  State<_DownloadSection> createState() => _DownloadSectionState();
}

class _DownloadSectionState extends State<_DownloadSection> {
  @override
  Widget build(BuildContext context) {
    if (widget.app.latestVersion == null) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.warning,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'No Version Available',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'This app doesn\'t have any downloadable versions available.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      );
    }

    return Consumer2<DownloadProvider, AppProvider>(
      builder: (context, downloadProvider, appProvider, child) {
        final version = widget.app.latestVersion!;

        // Check if ANY version of this app is downloading
        DownloadInfo? activeDownloadInfo;
        bool isDownloading = false;
        String downloadingVersionName = version.versionName;

        if (widget.app.packages != null) {
          for (var pkg in widget.app.packages!.values) {
            final info = downloadProvider.getDownloadInfo(
              widget.app.packageName,
              pkg.versionName,
            );
            if (info?.status == DownloadStatus.downloading) {
              activeDownloadInfo = info;
              isDownloading = true;
              downloadingVersionName = pkg.versionName;
              break;
            }
          }
        }

        final progress = isDownloading
            ? downloadProvider.getProgress(
                widget.app.packageName,
                downloadingVersionName,
              )
            : 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16.0,
          children: [
            if (isDownloading && activeDownloadInfo != null) ...[
              Column(
                spacing: 4.0,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Downloading... ${(progress * 100).toInt()}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ).animate().fadeIn(duration: Duration(milliseconds: 300)),
                      if (activeDownloadInfo.totalBytes > 0)
                        Text(
                              '${activeDownloadInfo.formattedBytesDownloaded} / ${activeDownloadInfo.formattedTotalBytes}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            )
                            .animate()
                            .fadeIn(duration: Duration(milliseconds: 300))
                            .slideY(
                              begin: 0.5,
                              end: 0,
                              duration: Duration(milliseconds: 300),
                            ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                        activeDownloadInfo.formattedSpeed,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: Duration(milliseconds: 300))
                      .slideY(
                        begin: 0.5,
                        end: 0,
                        duration: Duration(milliseconds: 300),
                      ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: progress, year2023: false)
                      .animate()
                      .fadeIn(duration: Duration(milliseconds: 300))
                      .slideY(
                        begin: 0.5,
                        end: 0,
                        duration: Duration(milliseconds: 300),
                      ),
                ],
              ),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Expanded(
                  child: Card.outlined(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        spacing: 8,
                        children: [
                          SizedBox(
                            height: 32,
                            child: Icon(
                              Symbols.download,
                              size: 32,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            version.sizeString,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card.outlined(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        spacing: 8,
                        children: [
                          SizedBox(
                            height: 32,
                            child: Icon(
                              Symbols.code_rounded,
                              size: 32,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            version.versionName,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (widget.stats?.hasAny != true)
                  Expanded(
                    child: Card.outlined(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          spacing: 8,
                          children: [
                            SizedBox(
                              height: 32,
                              child: Icon(
                                Symbols.license_rounded,
                                size: 32,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              widget.app.license,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (widget.stats?.hasAny == true)
                  Expanded(
                    child: Card.outlined(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          spacing: 8,
                          children: [
                            SizedBox(
                              height: 32,
                              child: Icon(
                                Symbols.chart_data,
                                size: 32,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              widget.stats!.last365Days != null
                                  ? _formatCount(widget.stats!.last365Days!)
                                  : 'N/A',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _IzzyStatsSection extends StatelessWidget {
  final String packageName;
  final IzzyStats stats;

  const _IzzyStatsSection({required this.packageName, required this.stats});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final captionStyle = textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              Row(
                spacing: 8,
                children: [
                  Icon(
                    Symbols.query_stats,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  Text(
                    'Downloads stats',
                    style: textTheme.labelMedium?.copyWith(
                      // fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                spacing: 8,
                children: [
                  _IzzyStatTile(
                    label: 'Last day',
                    value: stats.lastDay,
                    icon: Symbols.calendar_clock_rounded,
                  ),
                  _IzzyStatTile(
                    label: 'Last 30 days',
                    value: stats.last30Days,
                    icon: Symbols.event_available,
                  ),
                  _IzzyStatTile(
                    label: 'Last 365 days',
                    value: stats.last365Days,
                    icon: Symbols.timeline_rounded,
                  ),
                ],
              ),
              Text(
                'Stats are pulled from IzzyOnDroid mirrors for $packageName when available.',
                style: captionStyle,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IzzyStatTile extends StatelessWidget {
  final String label;
  final int? value;
  final IconData icon;

  const _IzzyStatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final subColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        Row(
          spacing: 6,
          children: [
            Icon(icon, size: 18, color: subColor),
            Text(label, style: textTheme.bodySmall?.copyWith(color: subColor)),
          ],
        ),
        Text(
          value != null ? _formatCount(value!) : 'Not available',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

String _formatCount(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  return value.toString();
}

class _IzzyStatsLoadingCard extends StatelessWidget {
  const _IzzyStatsLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Card.outlined(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            spacing: 12,
            children: [
              CircularProgressIndicator(year2023: false),
              Expanded(
                child: Text(
                  'Loading IzzyOnDroid download stats...',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IzzyStatsInfoCard extends StatelessWidget {
  final String message;

  const _IzzyStatsInfoCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card.outlined(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            spacing: 12,
            children: [
              Icon(Symbols.query_stats, color: color),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppInfoSection extends StatelessWidget {
  final FDroidApp app;

  const _AppInfoSection({required this.app});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MListHeader(title: 'App Information'),
        MListView(
          items: [
            MListItemData(
              leading: Icon(
                Symbols.package_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: 'Package Name',
              subtitle: app.packageName,
              onTap: () {},
            ),
            MListItemData(
              leading: Icon(
                Symbols.license_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: 'License',
              subtitle: app.license,
              onTap: () {},
            ),
            if (app.added != null)
              MListItemData(
                leading: Icon(
                  Symbols.add,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: 'Added',
                subtitle: _formatDate(app.added!),
                onTap: () {},
              ),
            if (app.added != null)
              MListItemData(
                leading: Icon(
                  Symbols.update,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: 'Last Updated',
                subtitle: _formatDate(app.lastUpdated!),
                onTap: () {},
              ),
            if (app.latestVersion?.permissions?.isNotEmpty == true)
              MListItemData(
                leading: Icon(
                  Symbols.security,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: 'Permissions ',
                subtitle: '(${app.latestVersion!.permissions!.length})',
                suffix: Icon(Symbols.arrow_forward),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PermissionsScreen(
                        permissions: app.latestVersion!.permissions!,
                        appName: app.name,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _DescriptionSection extends StatefulWidget {
  final FDroidApp app;

  const _DescriptionSection({required this.app});

  @override
  State<_DescriptionSection> createState() => _DescriptionSectionState();
}

class _DescriptionSectionState extends State<_DescriptionSection>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final description = widget.app.description;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Text(
            'Description',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Html(
              data: description,
              shrinkWrap: true,
              style: {
                "body": Style(
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                  fontSize: FontSize(
                    Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14,
                  ),
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  maxLines: _isExpanded ? null : 3,
                  textOverflow: _isExpanded ? null : TextOverflow.ellipsis,
                ),
                "p": Style(margin: Margins.only(bottom: 8)),
                "a": Style(
                  color: Theme.of(context).colorScheme.primary,
                  textDecoration: TextDecoration.underline,
                ),
              },
              onLinkTap: (url, attributes, element) {
                if (url != null) {
                  launchUrl(Uri.parse(url));
                }
              },
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
                if (_isExpanded) {
                  _animationController.forward();
                } else {
                  _animationController.reverse();
                }
              });
            },
            child: Text(_isExpanded ? 'Show less' : 'Show more'),
          ),
        ],
      ),
    );
  }
}

class _VersionInfoSection extends StatelessWidget {
  final FDroidVersion version;

  const _VersionInfoSection({required this.version});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MListHeader(title: 'Version Information'),
        MListView(
          items: [
            MListItemData(
              title: 'Version Name',
              subtitle: version.versionName,
              onTap: () {},
            ),
            MListItemData(
              title: 'Version Code',
              subtitle: version.versionCode.toString(),
              onTap: () {},
            ),
            MListItemData(
              title: 'Size',
              subtitle: version.sizeString,
              onTap: () {},
            ),
            if (version.minSdkVersion != null)
              MListItemData(
                title: 'Min SDK',
                subtitle: version.minSdkVersion!,
                onTap: () {},
              ),
            if (version.targetSdkVersion != null)
              MListItemData(
                title: 'Target SDK',
                subtitle: version.targetSdkVersion!,
                onTap: () {},
              ),
          ],
        ),
      ],
    );
  }
}

class _NoVersionInfoSection extends StatelessWidget {
  const _NoVersionInfoSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Version Information',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Icon(
                  Symbols.info,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'No Version Information Available',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This app doesn\'t have detailed version information in the F-Droid repository.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppDetailsIcon extends StatefulWidget {
  final FDroidApp app;
  const _AppDetailsIcon({required this.app});

  @override
  State<_AppDetailsIcon> createState() => _AppDetailsIconState();
}

class _AppDetailsIconState extends State<_AppDetailsIcon> {
  late List<String> _candidates;
  int _index = 0;
  bool _showFallback = false;

  @override
  void initState() {
    super.initState();
    _candidates = widget.app.iconUrls;
  }

  void _next() {
    if (!mounted) return;

    // Always use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Move through all candidates before showing a fallback
      if (_index < _candidates.length - 1) {
        setState(() {
          _index++;
        });
      } else {
        setState(() {
          _showFallback = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showFallback) {
      return Container(
        color: Colors.white.withOpacity(0.2),
        child: const Icon(Symbols.android, color: Colors.white, size: 40),
      );
    }

    if (_index >= _candidates.length) {
      return Container(
        color: Colors.white.withOpacity(0.2),
        child: const Icon(Symbols.apps, color: Colors.white, size: 40),
      );
    }

    final url = _candidates[_index];
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Move to next candidate or fallback
        _next();
        return Container(
          color: Colors.white.withOpacity(0.2),
          child: const Icon(
            Symbols.broken_image,
            color: Colors.white,
            size: 40,
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.white.withOpacity(0.2),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              year2023: false,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        );
      },
    );
  }
}

class _AllVersionsSection extends StatelessWidget {
  final FDroidApp app;

  const _AllVersionsSection({required this.app});

  @override
  Widget build(BuildContext context) {
    final versions = app.packages?.values.toList() ?? [];
    if (versions.isEmpty) return const SizedBox.shrink();

    // Sort versions by version code descending
    versions.sort((a, b) => b.versionCode.compareTo(a.versionCode));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8.0,
      children: [
        MListHeader(title: 'All Versions'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              ...versions.map((version) {
                final isLatest = version == versions.first;

                return Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: isLatest
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: isLatest
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1,
                          )
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  version.versionName,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'Code: ${version.versionCode}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          if (isLatest)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Latest',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimary,
                                    ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Size: ${version.sizeString}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Released: ${_formatDate(version.added)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _VersionDownloadButton(app: app, version: version),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _VersionDownloadButton extends StatelessWidget {
  final FDroidApp app;
  final FDroidVersion version;

  const _VersionDownloadButton({required this.app, required this.version});

  @override
  Widget build(BuildContext context) {
    return Consumer2<DownloadProvider, AppProvider>(
      builder: (context, downloadProvider, appProvider, child) {
        final isInstalled = appProvider.isAppInstalled(app.packageName);
        final installedApp = appProvider.getInstalledApp(app.packageName);
        final downloadInfo = downloadProvider.getDownloadInfo(
          app.packageName,
          version.versionName,
        );
        final isDownloading =
            downloadInfo?.status == DownloadStatus.downloading;
        final isCancelled = downloadInfo?.status == DownloadStatus.cancelled;
        final fileExists = downloadInfo?.filePath != null
            ? File(downloadInfo!.filePath!).existsSync()
            : false;
        final isDownloaded =
            downloadInfo?.status == DownloadStatus.completed &&
            downloadInfo?.filePath != null &&
            !isCancelled &&
            fileExists;
        final progress = downloadProvider.getProgress(
          app.packageName,
          version.versionName,
        );

        if (isInstalled && installedApp != null) {
          return Row(
            spacing: 8,
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () async {
                    try {
                      await downloadProvider.uninstallApp(app.packageName);
                      await Future.delayed(const Duration(milliseconds: 100));
                      await appProvider.fetchInstalledApps();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Uninstall failed: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Symbols.delete_rounded, fill: 1, size: 18),
                  label: const Text('Uninstall'),
                  style: FilledButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onError,
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    try {
                      final opened = await appProvider.openInstalledApp(
                        app.packageName,
                      );
                      if (!opened && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to open ${app.name}')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  icon: const Icon(Symbols.open_in_new_rounded, size: 18),
                  label: const Text('Open'),
                ),
              ),
            ],
          );
        }

        if (isDownloading) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Downloading... ${(progress * 100).toInt()}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      downloadProvider.cancelDownload(
                        app.packageName,
                        version.versionName,
                      );
                    },
                    icon: const Icon(Symbols.close, size: 18),
                    label: const Text('Cancel'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progress, year2023: false),
            ],
          );
        }

        if (isDownloaded) {
          return FilledButton.icon(
            onPressed: () async {
              final hasPermission = await downloadProvider
                  .requestInstallPermission();
              if (!hasPermission) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Install permission is required'),
                    ),
                  );
                }
                return;
              }

              try {
                if (downloadInfo.filePath != null) {
                  await downloadProvider.installApk(downloadInfo.filePath!);
                  await Future.delayed(const Duration(milliseconds: 100));
                  await appProvider.fetchInstalledApps();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Installing ${app.name}...')),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Installation failed: $e')),
                  );
                }
              }
            },
            icon: const Icon(Symbols.install_mobile, size: 18),
            label: const Text('Install'),
          );
        }

        return FilledButton.tonalIcon(
          onPressed: () async {
            final hasPermission = await downloadProvider.requestPermissions();
            if (!hasPermission) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Storage permission is required'),
                  ),
                );
              }
              return;
            }

            try {
              await downloadProvider.downloadApk(app.copyWithVersion(version));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Downloading ${version.versionName}...'),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
              }
            }
          },
          icon: const Icon(Symbols.download, size: 18),
          label: const Text('Download'),
        );
      },
    );
  }
}

class _ScreenshotsSection extends StatefulWidget {
  final FDroidApp app;
  final List<String> screenshots;

  const _ScreenshotsSection({required this.app, required this.screenshots});

  @override
  State<_ScreenshotsSection> createState() => _ScreenshotsSectionState();
}

class _ScreenshotsSectionState extends State<_ScreenshotsSection> {
  String _getScreenshotUrl(String screenshot) {
    var path = screenshot.trim();
    while (path.startsWith('/')) {
      path = path.substring(1);
    }
    // Handle if already a full URL
    if (path.startsWith('http')) {
      return path;
    }
    return '${widget.app.repositoryUrl}/$path';
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Screenshots Section - Count: ${widget.screenshots.length}');
    for (var i = 0; i < widget.screenshots.length; i++) {
      debugPrint('Screenshot $i: ${widget.screenshots[i]}');
    }

    if (widget.screenshots.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8.0,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Screenshots',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        SizedBox(
          height: 500,
          child: CarouselView(
            // flexWeights: const [2, 1],
            itemExtent: 250,
            shrinkExtent: 250,
            onTap: (index) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => _FullScreenScreenshots(
                    app: widget.app,
                    screenshots: widget.screenshots,
                    initialIndex: index,
                  ),
                ),
              );
            },
            children: widget.screenshots.asMap().entries.map((entry) {
              final screenshot = entry.value;
              final url = _getScreenshotUrl(screenshot);
              debugPrint('Loading screenshot from URL: $url');

              return Builder(
                builder: (context) {
                  return Material(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    child: Image.network(
                      url,
                      fit: BoxFit.fitWidth,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('Screenshot error: $error');
                        debugPrint('StackTrace: $stackTrace');
                        return Container(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Symbols.broken_image),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Failed to load',
                                  style: Theme.of(context).textTheme.bodySmall,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(year2023: false),
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                child: Text(
                                  '${(loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1) * 100).toInt()}%',
                                  style: Theme.of(context).textTheme.bodySmall,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _FullScreenScreenshots extends StatefulWidget {
  final FDroidApp app;
  final List<String> screenshots;
  final int initialIndex;

  const _FullScreenScreenshots({
    required this.app,
    required this.screenshots,
    required this.initialIndex,
  });

  @override
  State<_FullScreenScreenshots> createState() => _FullScreenScreenshotsState();
}

class _FullScreenScreenshotsState extends State<_FullScreenScreenshots> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _getScreenshotUrl(String screenshot) {
    var path = screenshot.trim();
    while (path.startsWith('/')) {
      path = path.substring(1);
    }
    // Handle if already a full URL
    if (path.startsWith('http')) {
      return path;
    }
    return '${widget.app.repositoryUrl}/$path';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        elevation: 0,
        title: Text(
          '${_currentIndex + 1} / ${widget.screenshots.length}',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Symbols.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemCount: widget.screenshots.length,
        itemBuilder: (context, index) {
          final screenshot = widget.screenshots[index];
          return SafeArea(
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    _getScreenshotUrl(screenshot),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[900],
                        child: const Center(
                          child: Icon(
                            Symbols.broken_image,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          year2023: false,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
