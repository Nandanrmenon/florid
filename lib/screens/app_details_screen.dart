import 'dart:io';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/fdroid_app.dart';
import '../providers/app_provider.dart';
import '../providers/download_provider.dart';
import 'permissions_screen.dart';

class AppDetailsScreen extends StatelessWidget {
  final FDroidApp app;
  final List<String>? screenshots;

  const AppDetailsScreen({super.key, required this.app, this.screenshots});

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
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _AppDetailsIcon(app: app),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            app.name,
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
                    'Check out ${app.name} on F-Droid: https://f-droid.org/packages/${app.packageName}/',
                  );
                },
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  switch (value) {
                    case 'website':
                      if (app.webSite != null) {
                        await launchUrl(Uri.parse(app.webSite!));
                      }
                      break;
                    case 'source':
                      if (app.sourceCode != null) {
                        await launchUrl(Uri.parse(app.sourceCode!));
                      }
                      break;
                    case 'issues':
                      if (app.issueTracker != null) {
                        await launchUrl(Uri.parse(app.issueTracker!));
                      }
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (app.webSite != null)
                    const PopupMenuItem(
                      value: 'website',
                      child: ListTile(
                        leading: Icon(Symbols.public),
                        title: Text('Website'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  if (app.sourceCode != null)
                    const PopupMenuItem(
                      value: 'source',
                      child: ListTile(
                        leading: Icon(Symbols.code),
                        title: Text('Source Code'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  if (app.issueTracker != null)
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16,
                children: [
                  // App info header
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Consumer<AppProvider>(
                      builder: (context, appProvider, _) {
                        final isInstalled = appProvider.isAppInstalled(
                          app.packageName,
                        );
                        final installedApp = appProvider.getInstalledApp(
                          app.packageName,
                        );

                        return Column(
                          spacing: 16,
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Row(
                              spacing: 8,
                              children: [
                                Hero(
                                  tag: 'app-icon-${app.packageName}',
                                  child: Material(
                                    child: SizedBox(
                                      width: 100,
                                      height: 100,

                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: _AppDetailsIcon(app: app),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    spacing: 4,
                                    children: [
                                      Text(
                                        app.name,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge,
                                      ),
                                      Text(
                                        'by ${app.authorName ?? 'Unknown'}',
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

                            _DownloadSection(app: app),
                          ],
                        );
                      },
                    ),
                  ),

                  // Screenshots section
                  if (screenshots?.isNotEmpty == true)
                    _ScreenshotsSection(screenshots: screenshots!)
                  else
                    const SizedBox.shrink(),

                  if (app.categories?.isNotEmpty == true) ...[
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(app.categories!.first),
                    ),
                  ],
                  // Description
                  _DescriptionSection(app: app),
                  Divider(),

                  // Download section
                  // _DownloadSection(app: app),

                  // App details
                  _AppInfoSection(app: app),
                  Divider(),

                  // Version info
                  if (app.latestVersion != null)
                    _VersionInfoSection(version: app.latestVersion!)
                  else
                    const _NoVersionInfoSection(),
                  if (app.latestVersion != null) Divider(),
                  // All versions history
                  if (app.packages != null && app.packages!.isNotEmpty)
                    _AllVersionsSection(app: app)
                  else
                    const SizedBox.shrink(),
                  if (app.packages != null && app.packages!.isNotEmpty)
                    Divider(),
                  // Permissions section
                  if (app.latestVersion?.permissions?.isNotEmpty == true)
                    ListTile(
                      leading: Icon(
                        Symbols.security,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        'Permissions (${app.latestVersion!.permissions!.length})',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      trailing: const Icon(Symbols.arrow_forward),
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
                    )
                  else
                    const SizedBox.shrink(),

                  if (app.latestVersion?.permissions?.isNotEmpty == true)
                    Divider(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
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
        final isInstalled = appProvider.isAppInstalled(widget.app.packageName);
        final installedApp = appProvider.getInstalledApp(
          widget.app.packageName,
        );
        final downloadInfo = downloadProvider.getDownloadInfo(
          widget.app.packageName,
          version.versionName,
        );
        final isDownloading =
            downloadInfo?.status == DownloadStatus.downloading;
        final isCancelled = downloadInfo?.status == DownloadStatus.cancelled;

        // Check if file actually exists on disk (not just marked as completed)
        // Use FutureBuilder to handle async file existence check
        final fileExists = downloadInfo?.filePath != null
            ? File(downloadInfo!.filePath!).existsSync()
            : false;

        final isDownloaded =
            downloadInfo?.status == DownloadStatus.completed &&
            downloadInfo?.filePath != null &&
            !isCancelled &&
            fileExists;
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
            const SizedBox(height: 16),
            if (isDownloading)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 16,
                children: [
                  Text(
                    'Downloading... ${(progress * 100).toInt()}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  LinearProgressIndicator(
                    value: progress,
                    year2023: false,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: () {
                      downloadProvider.cancelDownload(
                        widget.app.packageName,
                        version.versionName,
                      );
                    },
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              )
            else if (isInstalled && installedApp != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    spacing: 8,
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            try {
                              await downloadProvider.uninstallApp(
                                widget.app.packageName,
                              );
                              // Give system a moment to complete uninstall, then refresh
                              await Future.delayed(const Duration(seconds: 1));
                              await appProvider.fetchInstalledApps();
                              // if (context.mounted) {
                              //   ScaffoldMessenger.of(context).showSnackBar(
                              //     SnackBar(
                              //       content: Text(
                              //         '${widget.app.name} uninstall initiated',
                              //       ),
                              //     ),
                              //   );
                              // }
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
                          icon: const Icon(Symbols.delete),
                          label: const Text('Uninstall'),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final opened = await appProvider.openInstalledApp(
                                widget.app.packageName,
                              );
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
                          icon: const Icon(Symbols.open_in_new),
                          label: const Text('Open'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (isDownloaded) {
                      // Install APK
                      try {
                        final downloadInfo = downloadProvider.getDownloadInfo(
                          widget.app.packageName,
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

                          await downloadProvider.installApk(
                            downloadInfo!.filePath!,
                          );
                          // Refresh installed apps after successful install (allow system to register)
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
                      // Download APK - request permission first
                      final hasPermission = await downloadProvider
                          .requestPermissions();

                      if (!hasPermission) {
                        if (context.mounted) {
                          // Show dialog explaining how to grant permission
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
                        await downloadProvider.downloadApk(widget.app);
                        // No success message - auto-install handles feedback

                        // Poll for app installation to complete (auto-install is async)
                        if (context.mounted) {
                          // Wait up to ~12 seconds for the system to register the app
                          for (int i = 0; i < 15; i++) {
                            await Future.delayed(
                              const Duration(milliseconds: 800),
                            );
                            await appProvider.fetchInstalledApps();
                            if (appProvider.isAppInstalled(
                              widget.app.packageName,
                            )) {
                              // App installed successfully, delete the APK file
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
                        // Only show error if not cancelled
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
                    isDownloaded ? Symbols.install_mobile : Symbols.download,
                  ),
                  label: Text(isDownloaded ? 'Install' : 'Download'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    disabledForegroundColor: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant,
                    disabledBackgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
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
        Text(
          'App Information',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        _InfoRow('Package Name', app.packageName),
        _InfoRow('License', app.license),
        if (app.added != null) _InfoRow('Added', _formatDate(app.added!)),
        if (app.lastUpdated != null)
          _InfoRow('Last Updated', _formatDate(app.lastUpdated!)),
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
  late Animation<double> _heightAnimation;

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

    return Column(
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
        Text(
          'Version Information',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        _InfoRow('Version Name', version.versionName),
        _InfoRow('Version Code', version.versionCode.toString()),
        _InfoRow('Size', version.sizeString),
        if (version.minSdkVersion != null)
          _InfoRow('Min SDK', version.minSdkVersion!),
        if (version.targetSdkVersion != null)
          _InfoRow('Target SDK', version.targetSdkVersion!),
        _InfoRow('Added', _formatDate(version.added)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _NoVersionInfoSection extends StatelessWidget {
  const _NoVersionInfoSection();

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
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

      children: [
        Text(
          'All Versions',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
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
                                color: Theme.of(context).colorScheme.onPrimary,
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
              ],
            ),
          );
        }),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _ScreenshotsSection extends StatelessWidget {
  final List<String> screenshots;

  const _ScreenshotsSection({required this.screenshots});

  String _getScreenshotUrl(String screenshot) {
    var path = screenshot.trim();
    while (path.startsWith('/')) {
      path = path.substring(1);
    }
    // Handle if already a full URL
    if (path.startsWith('http')) {
      return path;
    }
    return 'https://f-droid.org/repo/$path';
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Screenshots Section - Count: ${screenshots.length}');
    for (var i = 0; i < screenshots.length; i++) {
      debugPrint('Screenshot $i: ${screenshots[i]}');
    }

    if (screenshots.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Screenshots',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 300,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: screenshots.length,
            itemBuilder: (context, index) {
              final screenshot = screenshots[index];
              final url = _getScreenshotUrl(screenshot);
              debugPrint('Loading screenshot from URL: $url');

              return Padding(
                padding: EdgeInsets.only(
                  right: index != screenshots.length - 1 ? 12 : 0,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Material(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => _FullScreenScreenshots(
                              screenshots: screenshots,
                              initialIndex: index,
                            ),
                          ),
                        );
                      },
                      child: AspectRatio(
                        aspectRatio: 9 / 16,
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          cacheWidth: 300,
                          cacheHeight: 600,
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint('Screenshot error: $error');
                            debugPrint('StackTrace: $stackTrace');
                            return Container(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainer,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Symbols.broken_image),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      'Failed to load',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
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
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainer,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(
                                    year2023: false,
                                  ),
                                  const SizedBox(height: 12),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: Text(
                                      '${(loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1) * 100).toInt()}%',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FullScreenScreenshots extends StatefulWidget {
  final List<String> screenshots;
  final int initialIndex;

  const _FullScreenScreenshots({
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
    return 'https://f-droid.org/repo/$path';
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
            child: Center(
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: Container(
                  color: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      _getScreenshotUrl(screenshot),
                      fit: BoxFit.cover,
                      cacheWidth: 1080,
                      cacheHeight: 1920,
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
            ),
          );
        },
      ),
    );
  }
}
