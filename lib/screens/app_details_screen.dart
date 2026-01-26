import 'dart:io';

import 'package:florid/screens/permissions_screen.dart';
import 'package:florid/widgets/m_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/fdroid_app.dart';
import '../providers/app_provider.dart';
import '../providers/download_provider.dart';

class AppDetailsScreen extends StatefulWidget {
  final FDroidApp app;

  const AppDetailsScreen({super.key, required this.app});

  @override
  State<AppDetailsScreen> createState() => _AppDetailsScreenState();
}

class _AppDetailsScreenState extends State<AppDetailsScreen> {
  late Future<List<String>> _screenshotsFuture;

  @override
  void initState() {
    super.initState();
    // Fetch screenshots in the background
    _screenshotsFuture = context.read<AppProvider>().getScreenshots(
      widget.app.packageName,
      repositoryUrl: widget.app.repositoryUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    const double expandedHeight = 180;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: expandedHeight,
            pinned: true,
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final maxHeight = constraints.maxHeight;
                final collapseRange = expandedHeight - kToolbarHeight;
                final t = collapseRange <= 0
                    ? 1.0
                    : ((expandedHeight - maxHeight) / collapseRange).clamp(
                        0.0,
                        1.0,
                      );

                return FlexibleSpaceBar(
                  titlePadding: EdgeInsetsDirectional.only(
                    start: t < 1 ? 50 : 16,
                    bottom: 16,
                    end: 100,
                  ),
                  title: AnimatedOpacity(
                    opacity: t,
                    duration: const Duration(milliseconds: 150),
                    child: Row(
                      spacing: 8,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _AppDetailsIcon(app: widget.app),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            widget.app.name,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                    ),
                  ),
                );
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Symbols.share),
                onPressed: () {
                  Share.share(
                    'Check out ${widget.app.name} on F-Droid: https://f-droid.org/packages/${widget.app.packageName}/',
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
                // App info header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
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
                          Row(
                            spacing: 8,
                            children: [
                              Hero(
                                tag: 'app-icon-${widget.app.packageName}',
                                child: Material(
                                  child: SizedBox(
                                    width: 100,
                                    height: 100,

                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: _AppDetailsIcon(app: widget.app),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  spacing: 4,
                                  children: [
                                    Text(
                                      widget.app.name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                    Text(
                                      'by ${widget.app.authorName ?? 'Unknown'}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                    if (isInstalled)
                                      Chip(
                                        visualDensity: VisualDensity.compact,
                                        avatar: Icon(
                                          Symbols.check_circle,
                                          fill: 1,
                                        ),
                                        label: Text(
                                          'Installed${installedApp?.versionName != null ? ' (${installedApp!.versionName})' : ''}',
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          _DownloadSection(app: widget.app),
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
                ),

                if (widget.app.categories?.isNotEmpty == true) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(widget.app.categories!.first),
                    ),
                  ),
                ],
                // Description
                _DescriptionSection(app: widget.app),
                // Divider(),

                // Download section
                // _DownloadSection(app: app),

                // App details
                _AppInfoSection(app: widget.app),

                // Version info
                if (widget.app.latestVersion != null)
                  _VersionInfoSection(version: widget.app.latestVersion!)
                else
                  const _NoVersionInfoSection(),
                // All versions history
                if (widget.app.packages != null &&
                    widget.app.packages!.isNotEmpty)
                  _AllVersionsSection(app: widget.app)
                else
                  const SizedBox.shrink(),
                // Permissions
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.app.latestVersion == null
          ? null
          : BottomAppBar(
              child: Consumer2<DownloadProvider, AppProvider>(
                builder: (context, downloadProvider, appProvider, child) {
                  final version = widget.app.latestVersion!;
                  final isInstalled = appProvider.isAppInstalled(
                    widget.app.packageName,
                  );
                  final installedApp = appProvider.getInstalledApp(
                    widget.app.packageName,
                  );
                  final downloadInfo = downloadProvider.getDownloadInfo(
                    widget.app.packageName,
                    version.versionName,
                  );
                  final isDownloading =
                      downloadInfo?.status == DownloadStatus.downloading;
                  final isCancelled =
                      downloadInfo?.status == DownloadStatus.cancelled;
                  final fileExists = downloadInfo?.filePath != null
                      ? File(downloadInfo!.filePath!).existsSync()
                      : false;
                  final isDownloaded =
                      downloadInfo?.status == DownloadStatus.completed &&
                      downloadInfo?.filePath != null &&
                      !isCancelled &&
                      fileExists;

                  if (isDownloading) {
                    return SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.tonal(
                        onPressed: () {
                          downloadProvider.cancelDownload(
                            widget.app.packageName,
                            version.versionName,
                          );
                        },
                        child: const Text('Cancel Download'),
                      ),
                    );
                  }

                  if (isInstalled && installedApp != null) {
                    return Row(
                      spacing: 8,
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: FilledButton.tonalIcon(
                              onPressed: () async {
                                try {
                                  await downloadProvider.uninstallApp(
                                    widget.app.packageName,
                                  );
                                  await Future.delayed(
                                    const Duration(seconds: 1),
                                  );
                                  await appProvider.fetchInstalledApps();
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Uninstall failed: ${e.toString()}',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Symbols.delete_rounded, fill: 1),
                              label: const Text('Uninstall'),
                              style: FilledButton.styleFrom(
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.onError,
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.error,
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
                                      .openInstalledApp(widget.app.packageName);
                                  if (!opened && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Unable to open ${widget.app.name}.',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Open failed: ${e.toString()}',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Symbols.open_in_new_rounded),
                              label: const Text('Open'),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: () async {
                        if (isDownloaded) {
                          try {
                            final downloadInfo = downloadProvider
                                .getDownloadInfo(
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

                              await downloadProvider.installApk(
                                downloadInfo!.filePath!,
                              );
                              await Future.delayed(
                                const Duration(milliseconds: 100),
                              );
                              await appProvider.fetchInstalledApps();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${widget.app.name} installation started!',
                                    ),
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Installation failed: ${e.toString()}',
                                  ),
                                ),
                              );
                            }
                          }
                        } else {
                          final hasPermission = await downloadProvider
                              .requestPermissions();

                          if (!hasPermission) {
                            if (context.mounted) {
                              await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  icon: const Icon(Symbols.warning, size: 48),
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
                                          Navigator.of(context).pop(),
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
                            await downloadProvider.downloadApk(widget.app);

                            if (context.mounted) {
                              for (int i = 0; i < 15; i++) {
                                await Future.delayed(
                                  const Duration(milliseconds: 800),
                                );
                                await appProvider.fetchInstalledApps();
                                if (appProvider.isAppInstalled(
                                  widget.app.packageName,
                                )) {
                                  final downloadInfo = downloadProvider
                                      .getDownloadInfo(
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
                                  SnackBar(
                                    content: Text('Download failed: $errorMsg'),
                                  ),
                                );
                              }
                            }
                          }
                        }
                      },
                      icon: Icon(
                        isDownloaded
                            ? Symbols.install_mobile
                            : Symbols.download,
                      ),
                      label: Text(isDownloaded ? 'Install' : 'Download'),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _DownloadSection extends StatefulWidget {
  final FDroidApp app;

  const _DownloadSection({required this.app});

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
        final downloadInfo = downloadProvider.getDownloadInfo(
          widget.app.packageName,
          version.versionName,
        );
        final isDownloading =
            downloadInfo?.status == DownloadStatus.downloading;

        final progress = downloadProvider.getProgress(
          widget.app.packageName,
          version.versionName,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Expanded(
                  child: Card.outlined(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                      ),
                    ),
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
                              Symbols.apk_document_rounded,
                              size: 32,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            version.sizeString,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card.outlined(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                      ),
                    ),
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
                              ).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            version.versionName,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card.outlined(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                      ),
                    ),
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
                              ).colorScheme.onPrimaryContainer,
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
                                  ).colorScheme.onPrimaryContainer,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (isDownloading) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Downloading... ${(progress * 100).toInt()}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ).animate().fadeIn(duration: Duration(milliseconds: 300)),
                  if (downloadInfo != null && downloadInfo.totalBytes > 0)
                    Text(
                          '${downloadInfo.formattedBytesDownloaded} / ${downloadInfo.formattedTotalBytes}',
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
              if (downloadInfo != null)
                Text(
                      downloadInfo.formattedSpeed,
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
          ],
        );
      },
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
    final maxLines = _isExpanded ? null : 3;
    final description = widget.app.description;

    // Check if text would overflow with 3 lines
    final textPainter = TextPainter(
      text: TextSpan(
        text: description,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      maxLines: 3,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: MediaQuery.of(context).size.width - 32);
    final isOverflowing = textPainter.didExceedMaxLines;

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
          Stack(
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: maxLines,
                  overflow: _isExpanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (isOverflowing)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
                child: TextButton(
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
              ),
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
