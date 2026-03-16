import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:florid/l10n/app_localizations.dart';
import 'package:florid/screens/app_details/developer_apps_screen.dart';
import 'package:florid/screens/app_details/permissions_screen.dart';
import 'package:florid/widgets/changelog_preview.dart';
import 'package:florid/widgets/list_icon.dart';
import 'package:florid/widgets/m_list.dart';
import 'package:florid/widgets/markup_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants.dart';
import '../../models/fdroid_app.dart';
import '../../providers/app_provider.dart';
import '../../providers/download_provider.dart';
import '../../providers/repositories_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/izzy_stats_service.dart';

class AppDetailsScreen extends StatefulWidget {
  final FDroidApp app;

  const AppDetailsScreen({super.key, required this.app});

  @override
  State<AppDetailsScreen> createState() => _AppDetailsScreenState();
}

class _AppDetailsScreenState extends State<AppDetailsScreen>
    with WidgetsBindingObserver {
  late Future<List<String>> _screenshotsFuture;
  late Future<IzzyStats> _statsFuture;
  late Future<FDroidApp> _enrichedAppFuture;
  bool _isInstalling = false;
  bool _pendingInstallStateRefresh = false;
  bool _isInstallMonitorRunning = false;
  bool _isCollapsed = false;
  late ScrollController _scrollController;
  final double expandedBarHeight = 300;
  final double collapsedBarHeight = kMinInteractiveDimension;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController = ScrollController();
    // Start with lightweight futures to keep route transition smooth.
    _screenshotsFuture = Future.value(const <String>[]);
    _statsFuture = context.read<IzzyStatsService>().fetchStatsForPackage(
      widget.app.packageName,
    );
    _enrichedAppFuture = Future.value(widget.app);

    // Defer heavier work until first frame is rendered.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _screenshotsFuture = context.read<AppProvider>().getScreenshots(
          widget.app.packageName,
          repositoryUrl: widget.app.repositoryUrl,
        );
        _enrichedAppFuture = context
            .read<AppProvider>()
            .enrichAppWithRepositories(
              widget.app,
              context.read<RepositoriesProvider>(),
            );
      });
    });
  }

  /// Background cleanup task that waits for installation and auto-deletes APK
  Future<void> _startBackgroundCleanup(
    AppProvider appProvider,
    DownloadProvider downloadProvider,
    SettingsProvider settings,
  ) async {
    // Poll for installation completion in background.
    // Keep this window long enough for slow/manual install confirmation flows.
    final deadline = DateTime.now().add(const Duration(minutes: 2));
    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 800));
      await appProvider.fetchInstalledApps();
      if (appProvider.isAppInstalled(widget.app.packageName)) {
        _pendingInstallStateRefresh = false;
        // App installed, clean up if auto-delete enabled
        if (settings.autoDeleteApk) {
          final latestVersion = await appProvider.getLatestVersion(widget.app);
          if (latestVersion != null) {
            final downloadInfo = downloadProvider.getDownloadInfo(
              widget.app.packageName,
              latestVersion.versionName,
            );
            if (downloadInfo?.filePath != null) {
              try {
                await downloadProvider.deleteDownloadedFile(
                  downloadInfo!.filePath!,
                );
              } catch (e) {
                debugPrint('Failed to auto-delete APK: $e');
              }
            }
          }
        }
        break;
      }
    }
  }

  Future<void> _ensureInstallStateRefresh() async {
    if (!mounted || _isInstallMonitorRunning) return;
    _isInstallMonitorRunning = true;
    try {
      await _startBackgroundCleanup(
        context.read<AppProvider>(),
        context.read<DownloadProvider>(),
        context.read<SettingsProvider>(),
      );
    } finally {
      _isInstallMonitorRunning = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted || state != AppLifecycleState.resumed) return;

    context.read<AppProvider>().fetchInstalledApps();
    if (_pendingInstallStateRefresh) {
      _ensureInstallStateRefresh();
    }
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

    return FutureBuilder<String?>(
      future: downloadProvider.getAppSource(app.packageName),
      builder: (context, snapshot) {
        // Use tracked repository if available, otherwise use app's default repository
        final defaultRepoUrl = snapshot.data ?? app.repositoryUrl;

        final button = AnimatedSwitcher(
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
                            context.read<SettingsProvider>(),
                            appProvider,
                            isDownloaded,
                            version,
                            defaultRepoUrl,
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
                      context.read<SettingsProvider>(),
                      appProvider,
                      isDownloaded,
                      version,
                      defaultRepoUrl,
                    ),
                    icon: Icon(
                      isDownloaded ? Symbols.install_mobile : Symbols.download,
                    ),
                    label: Text(isDownloaded ? 'Install' : 'Download'),
                  ),
                ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isInstalling) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
            ],
            if (!_isInstalling) button,
          ],
        );
      },
    );
  }

  Future<void> _handleInstall(
    BuildContext context,
    DownloadProvider downloadProvider,
    SettingsProvider settingsProvider,
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
            final settings = context.read<SettingsProvider>();
            if (settings.installMethod == InstallMethod.shizuku) {
              await _handleShizukuUnavailable(context, settings);
              return;
            }
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

          setState(() {
            _isInstalling = true;
            _pendingInstallStateRefresh = true;
          });
          try {
            await downloadProvider.installApk(
              downloadInfo!.filePath!,
              widget.app.packageName,
              downloadInfo.versionName,
              widget.app.name,
              antiFeatures: widget.app.antiFeatures,
            );
            await appProvider.waitForInstalled(widget.app.packageName);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${widget.app.name} installation started!'),
                ),
              );
            }
          } finally {
            if (mounted) {
              setState(() {
                _isInstalling = false;
              });
            }
            await Future.delayed(const Duration(seconds: 2));
            await appProvider.fetchInstalledApps();
            _startBackgroundCleanup(
              appProvider,
              downloadProvider,
              context.read<SettingsProvider>(),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isInstalling = false;
          });
        }
        if (context.mounted) {
          print('Installation failed: $e');
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
        // Create a copy of the app with the selected repository URL and only the filtered version
        // This ensures we download the correct version respecting the per-app unstable preference
        final appWithVersion = widget.app
            .copyWithVersion(version)
            .copyWith(repositoryUrl: repositoryUrl);
        await downloadProvider.downloadApk(appWithVersion);

        if (context.mounted) {
          final settings = context.read<SettingsProvider>();

          // Provider owns auto-install. Here we only reflect state and refresh UI.
          if (settings.autoInstallApk) {
            if (mounted) {
              setState(() {
                _isInstalling = true;
                _pendingInstallStateRefresh = true;
              });
            }
            _ensureInstallStateRefresh();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(
                      context,
                    )!.installing_app(widget.app.name),
                  ),
                ),
              );
            }
            return;
          }

          // Only run this polling loop when NOT auto-installing
          // (i.e., when download completes but auto-install is disabled)
          // This avoids UI hanging during auto-install
          for (int i = 0; i < 15; i++) {
            await Future.delayed(const Duration(milliseconds: 800));
            await appProvider.fetchInstalledApps();
            if (appProvider.isAppInstalled(widget.app.packageName)) {
              final latestVersion = await appProvider.getLatestVersion(
                widget.app,
              );
              if (latestVersion != null) {
                final downloadInfo = downloadProvider.getDownloadInfo(
                  widget.app.packageName,
                  latestVersion.versionName,
                );
                if (downloadInfo?.filePath != null && settings.autoDeleteApk) {
                  await downloadProvider.deleteDownloadedFile(
                    downloadInfo!.filePath!,
                  );
                }
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
                content: Text(
                  AppLocalizations.of(
                    context,
                  )!.download_failed_with_error(errorMsg),
                ),
              ),
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

    // Get the tracked repository for this app (if any)
    final trackedRepo = await downloadProvider.getAppSource(app.packageName);

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDownloaded
                              ? AppLocalizations.of(
                                  context,
                                )!.install_from_repository
                              : AppLocalizations.of(
                                  context,
                                )!.download_from_repository,
                          style: Theme.of(dialogContext).textTheme.titleLarge,
                        ),
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.choose_repository_for_action(
                            isDownloaded
                                ? AppLocalizations.of(context)!.install
                                : AppLocalizations.of(context)!.download,
                          ),
                          style: Theme.of(dialogContext).textTheme.labelMedium,
                        ),
                        if (trackedRepo != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Builder(
                              builder: (context) {
                                final trackedRepoSource = availableRepos
                                    .firstWhere(
                                      (r) => r.url == trackedRepo,
                                      orElse: () => RepositorySource(
                                        name: AppLocalizations.of(
                                          context,
                                        )!.unknown,
                                        url: trackedRepo,
                                      ),
                                    );
                                return Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.previously_installed_from(
                                    trackedRepoSource.name,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(dialogContext)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          dialogContext,
                                        ).colorScheme.primary,
                                      ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            MListViewBuilder(
              itemCount: availableRepos.length,
              itemBuilder: (index) {
                final repo = availableRepos[index];
                final isPrimary = repo.url == app.repositoryUrl;
                final isTracked =
                    trackedRepo != null && repo.url == trackedRepo;
                return MListItemData(
                  selected: isPrimary || isTracked,
                  leading: (isPrimary || isTracked)
                      ? Icon(Symbols.check)
                      : null,
                  title: repo.name,
                  subtitle: isTracked
                      ? AppLocalizations.of(
                          context,
                        )!.previously_installed_from_here
                      : null,
                  onTap: () {
                    Navigator.of(dialogContext).pop();
                    _handleInstall(
                      context,
                      downloadProvider,
                      context.read<SettingsProvider>(),
                      appProvider,
                      isDownloaded,
                      version,
                      repo.url,
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
                        AppLocalizations.of(context)!.default_repository,
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
                child: Text(AppLocalizations.of(context)!.cancel),
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
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _shareApp() async {
    await SharePlus.instance.share(
      ShareParams(
        text: AppLocalizations.of(
          context,
        )!.check_out_on_fdroid(widget.app.name, widget.app.packageName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkKnight =
        context.read<SettingsProvider>().themeStyle == ThemeStyle.darkKnight;
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Compute collapsed state synchronously but schedule state change
        // after the current frame to avoid calling setState during layout.
        final newCollapsed =
            _scrollController.hasClients &&
            _scrollController.offset > (expandedBarHeight - collapsedBarHeight);
        if (newCollapsed != _isCollapsed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _isCollapsed = newCollapsed;
            });
          });
        }
        return false;
      },
      child: Scaffold(
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: expandedBarHeight,
              backgroundColor: _isCollapsed
                  ? Theme.of(context).colorScheme.surface
                  : Colors.transparent,
              leading: BackButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(
                    Theme.of(context).colorScheme.surface,
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Feature graphic background if available
                    if (widget.app.featureGraphic != null &&
                        widget.app.featureGraphic!.isNotEmpty)
                      Positioned.fill(
                        child: Image.network(
                          widget.app.featureGraphic!,
                          fit: BoxFit.fitHeight,
                          errorBuilder: (context, error, stackTrace) {
                            return Container();
                          },
                        ),
                      ),
                    // Gradient overlay
                    if (widget.app.featureGraphic != null &&
                        widget.app.featureGraphic!.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Theme.of(context).colorScheme.surface,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    if (widget.app.featureGraphic == null ||
                        widget.app.featureGraphic!.isEmpty)
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              isDarkKnight
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerLow
                                  : Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                              Theme.of(context).colorScheme.surface,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    // Content
                    SafeArea(
                      child: Column(
                        // mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        spacing: 16.0,
                        children: [
                          SizedBox(
                            height: 128,
                            width: 128,
                            child: Material(
                              elevation: 1,
                              borderRadius: BorderRadius.circular(24),
                              clipBehavior: Clip.antiAlias,
                              child: AppDetailsIcon(app: widget.app),
                            ),
                          ),
                          Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32.0,
                                ),
                                child: Text(
                                  widget.app.name,
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontVariations: [
                                      FontVariation('wght', 700),
                                      FontVariation('ROND', 100),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32.0,
                                ),
                                child: InkWell(
                                  onTap: widget.app.authorName != null
                                      ? () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  DeveloperAppsScreen(
                                                    developerName:
                                                        widget.app.authorName!,
                                                  ),
                                            ),
                                          );
                                        }
                                      : null,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Text(
                                    AppLocalizations.of(context)!.by_author(
                                      widget.app.authorName ??
                                          AppLocalizations.of(context)!.unknown,
                                    ),
                                    maxLines: 2,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontVariations: [
                                        FontVariation('wght', 700),
                                        FontVariation('ROND', 100),
                                      ],
                                      decoration: widget.app.authorName != null
                                          ? TextDecoration.underline
                                          : null,
                                      decorationStyle:
                                          TextDecorationStyle.dotted,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              title: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isCollapsed ? 1 : 0,
                child: Row(
                  spacing: 16.0,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 32,
                      width: 32,
                      child: Material(
                        elevation: 2,
                        borderRadius: BorderRadius.circular(8),
                        clipBehavior: Clip.antiAlias,
                        child: AppDetailsIcon(app: widget.app),
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
                            AppLocalizations.of(context)!.by_author(
                              widget.app.authorName ??
                                  AppLocalizations.of(context)!.unknown,
                            ),
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
              ),
              actions: [
                Consumer<AppProvider>(
                  builder: (context, appProvider, _) {
                    final isFavorite = appProvider.isFavorite(
                      widget.app.packageName,
                    );
                    return IconButton(
                      tooltip: isFavorite
                          ? AppLocalizations.of(context)!.remove_from_favourites
                          : AppLocalizations.of(context)!.add_to_favourites,
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(
                          Theme.of(context).colorScheme.surface,
                        ),
                      ),
                      icon: Icon(
                        Symbols.favorite_rounded,
                        fill: isFavorite ? 1 : 0,
                        color: isFavorite ? Colors.red : null,
                      ),
                      onPressed: () {
                        appProvider.toggleFavorite(widget.app.packageName);
                      },
                    );
                  },
                ),
                IconButton(
                  tooltip: AppLocalizations.of(context)!.share,
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                      Theme.of(context).colorScheme.surface,
                    ),
                  ),
                  icon: Icon(Symbols.share),
                  onPressed: () {
                    _shareApp();
                  },
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
                            // Progress indicator
                            FutureBuilder<IzzyStats>(
                              future: _statsFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const SizedBox.shrink();
                                }
                                if (snapshot.hasError ||
                                    snapshot.data == null) {
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

                            // Install/Update button
                            _InstallActionsSection(
                              app: widget.app,
                              enrichedAppFuture: _enrichedAppFuture,
                              buildInstallButton: _buildInstallButton,
                            ).animate().fadeIn(
                              delay: Duration(milliseconds: 300),
                              duration: Duration(milliseconds: 300),
                            ),

                            // Short Info
                            Consumer2<DownloadProvider, AppProvider>(
                              builder:
                                  (
                                    context,
                                    downloadProvider,
                                    appProvider,
                                    child,
                                  ) {
                                    return FutureBuilder<FDroidVersion?>(
                                      future: appProvider.getLatestVersion(
                                        widget.app,
                                      ),
                                      builder: (context, snapshot) {
                                        final version = snapshot.data;
                                        if (version == null) {
                                          return const SizedBox.shrink();
                                        }
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          spacing: 16.0,
                                          children: [
                                            _ShortInfoRow(
                                              app: widget.app,
                                              version: version,
                                              statsFuture: _statsFuture,
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                            ).animate().fadeIn(
                              delay: Duration(milliseconds: 300),
                              duration: Duration(milliseconds: 300),
                            ),

                            // Changelog preview
                            FutureBuilder<FDroidVersion?>(
                              future: appProvider.getLatestVersion(widget.app),
                              builder: (context, snapshot) {
                                final latestVersion = snapshot.data;
                                if (latestVersion?.whatsNew != null &&
                                    latestVersion!.whatsNew!.isNotEmpty) {
                                  return ChangelogPreview(
                                    text: latestVersion.whatsNew,
                                  ).animate().fadeIn(
                                    delay: Duration(milliseconds: 300),
                                    duration: Duration(milliseconds: 300),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
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

                  // Include unstable versions toggle (only show if unstable versions exist)
                  IncludeUnstableSection(app: widget.app).animate().fadeIn(
                    delay: Duration(milliseconds: 300),
                    duration: Duration(milliseconds: 300),
                  ),

                  _DetailsSheetsSection(app: widget.app).animate().fadeIn(
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
                  AppExtraInfoSection(app: widget.app).animate().fadeIn(
                    delay: Duration(milliseconds: 300),
                    duration: Duration(milliseconds: 300),
                  ),

                  // Permissions
                  SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
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

class _DetailsSheetsSection extends StatelessWidget {
  final FDroidApp app;

  const _DetailsSheetsSection({required this.app});

  void _showAppInfoSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) => SafeArea(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: _AppInfoSection(app: app),
          ),
        ),
      ),
    );
  }

  void _showVersionInfoSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        builder: (context, scrollController) => SafeArea(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: FutureBuilder<FDroidVersion?>(
              future: context.read<AppProvider>().getLatestVersion(app),
              builder: (context, snapshot) {
                final version = snapshot.data;
                if (version == null) {
                  return const _NoVersionInfoSection();
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MListHeader(
                      title: AppLocalizations.of(context)!.version_information,
                    ),
                    MListView(
                      items: [
                        MListItemData(
                          title: AppLocalizations.of(context)!.version_name,
                          subtitle: version.versionName,
                          onTap: () {},
                        ),
                        MListItemData(
                          title: AppLocalizations.of(context)!.version_code,
                          subtitle: version.versionCode.toString(),
                          onTap: () {},
                        ),
                        MListItemData(
                          title: AppLocalizations.of(context)!.size,
                          subtitle: version.sizeString,
                          onTap: () {},
                        ),
                        if (version.minSdkVersion != null)
                          MListItemData(
                            title: AppLocalizations.of(context)!.min_sdk,
                            subtitle: version.minSdkVersion!,
                            onTap: () {},
                          ),
                        if (version.targetSdkVersion != null)
                          MListItemData(
                            title: AppLocalizations.of(context)!.target_sdk,
                            subtitle: version.targetSdkVersion!,
                            onTap: () {},
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showAllVersionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            controller: scrollController,
            child: _AllVersionsSection(app: app),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MListView(
      items: [
        MListItemData(
          title: AppLocalizations.of(context)!.app_information,
          subtitle: '',
          leading: const ListIcon(iconData: Symbols.info),
          suffix: const Icon(Symbols.arrow_forward),
          onTap: () => _showAppInfoSheet(context),
        ),
        MListItemData(
          title: AppLocalizations.of(context)!.version_information,
          subtitle: '',
          leading: const ListIcon(iconData: Symbols.license),
          suffix: const Icon(Symbols.arrow_forward),
          onTap: () => _showVersionInfoSheet(context),
        ),
        MListItemData(
          title: AppLocalizations.of(context)!.all_versions,
          subtitle: '',
          leading: const ListIcon(iconData: Symbols.history),
          suffix: const Icon(Symbols.arrow_forward),
          onTap: () => _showAllVersionsSheet(context),
        ),
      ],
    );
  }
}

class _DownloadSectionState extends State<_DownloadSection> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        return FutureBuilder<FDroidVersion?>(
          future: appProvider.getLatestVersion(widget.app),
          builder: (context, snapshot) {
            final latestVersion = snapshot.data;

            if (latestVersion == null) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
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
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
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
                final version = latestVersion;

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
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ).animate().fadeIn(
                                duration: Duration(milliseconds: 300),
                              ),
                              if (activeDownloadInfo.totalBytes > 0)
                                Text(
                                      '${activeDownloadInfo.formattedBytesDownloaded} / ${activeDownloadInfo.formattedTotalBytes}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                    )
                                    .animate()
                                    .fadeIn(
                                      duration: Duration(milliseconds: 300),
                                    )
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
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
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
                          LinearProgressIndicator(value: progress)
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
                  ],
                );
              },
            );
          },
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
              CircularProgressIndicator(),
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

class _InstallActionsSection extends StatelessWidget {
  final FDroidApp app;
  final Future<FDroidApp> enrichedAppFuture;
  final Widget Function(
    BuildContext context,
    DownloadProvider downloadProvider,
    AppProvider appProvider,
    bool isDownloaded,
    FDroidVersion version,
    FDroidApp app,
  )
  buildInstallButton;

  const _InstallActionsSection({
    required this.app,
    required this.enrichedAppFuture,
    required this.buildInstallButton,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<DownloadProvider, AppProvider>(
      builder: (context, downloadProvider, appProvider, child) {
        return FutureBuilder<FDroidVersion?>(
          future: appProvider.getLatestVersion(app),
          builder: (context, snapshot) {
            final version = snapshot.data;
            if (version == null) {
              return const SizedBox.shrink();
            }

            final isInstalled = appProvider.isAppInstalled(app.packageName);
            final installedApp = appProvider.getInstalledApp(app.packageName);

            // Check if ANY version of this app is downloading
            DownloadInfo? activeDownloadInfo;
            bool isDownloading = false;

            if (app.packages != null) {
              for (var pkg in app.packages!.values) {
                final info = downloadProvider.getDownloadInfo(
                  app.packageName,
                  pkg.versionName,
                );
                if (info?.status == DownloadStatus.downloading) {
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
                  app.packageName,
                  version.versionName,
                );
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

            if (isDownloading && activeDownloadInfo != null) {
              // Find the version name that's downloading
              String downloadingVersionName = version.versionName;
              if (app.packages != null) {
                for (var pkg in app.packages!.values) {
                  final info = downloadProvider.getDownloadInfo(
                    app.packageName,
                    pkg.versionName,
                  );
                  if (info?.status == DownloadStatus.downloading) {
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
                      app.packageName,
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
                  version.versionCode > installedApp.versionCode!;

              if (hasUpdate) {
                // Show Update button
                // Hide uninstall/open buttons for Florid itself
                final isFloridApp = app.packageName == 'com.nahnah.florid';
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
                                final hasPermission = await downloadProvider
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
                                  await downloadProvider.downloadApk(app);

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Downloading ${app.name} update...',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Update failed: $e'),
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Symbols.upgrade),
                              label: Text(AppLocalizations.of(context)!.update),
                            ),
                          ),
                        ),
                        if (!isFloridApp)
                          SizedBox(
                            height: 48,
                            child: FilledButton.tonalIcon(
                              onPressed: () async {
                                try {
                                  final opened = await appProvider
                                      .openInstalledApp(app.packageName);
                                  if (!opened && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Unable to open ${app.name}.',
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
                              label: Text(AppLocalizations.of(context)!.open),
                            ),
                          ),
                        if (!isFloridApp)
                          SizedBox(
                            height: 48,
                            child: FilledButton.tonal(
                              onPressed: () async {
                                try {
                                  await downloadProvider.uninstallApp(
                                    app.packageName,
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
              // Hide buttons for Florid itself
              final isFloridApp = app.packageName == 'com.nahnah.florid';
              if (isFloridApp) {
                return const SizedBox.shrink();
              }
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
                              app.packageName,
                            );
                            await Future.delayed(const Duration(seconds: 1));
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
                        label: Text(AppLocalizations.of(context)!.uninstall),
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
                            final opened = await appProvider.openInstalledApp(
                              app.packageName,
                            );
                            if (!opened && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Unable to open ${app.name}.'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Open failed: ${e.toString()}'),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Symbols.open_in_new_rounded),
                        label: Text(AppLocalizations.of(context)!.open),
                      ),
                    ),
                  ),
                ],
              );
            }

            return FutureBuilder<FDroidApp>(
              future: enrichedAppFuture,
              builder: (context, snapshot) {
                // Use enriched app if available and loaded, otherwise fall back to app
                final enrichedApp =
                    snapshot.connectionState == ConnectionState.done &&
                        snapshot.hasData
                    ? snapshot.data!
                    : app;

                // Log error if enrichment failed
                if (snapshot.hasError) {
                  debugPrint('Error enriching app: ${snapshot.error}');
                }

                return SizedBox(
                  width: double.infinity,
                  child: buildInstallButton(
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
        );
      },
    );
  }
}

class _ShortInfoRow extends StatelessWidget {
  final FDroidApp app;
  final FDroidVersion version;
  final Future<IzzyStats> statsFuture;

  const _ShortInfoRow({
    required this.app,
    required this.version,
    required this.statsFuture,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 8,
      children: [
        Expanded(
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
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  version.sizeString,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          width: 2,
          color: Theme.of(context).colorScheme.outlineVariant,
          height: 32,
        ),
        Expanded(
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
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    version.versionName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          width: 2,
          color: Theme.of(context).colorScheme.outlineVariant,
          height: 32,
        ),
        FutureBuilder<IzzyStats>(
          future: statsFuture,
          builder: (context, statsSnapshot) {
            final stats = statsSnapshot.data;
            if (stats?.hasAny != true) {
              return Expanded(
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
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        app.license,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Expanded(
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
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      stats!.last365Days != null
                          ? _formatCount(stats.last365Days!)
                          : 'N/A',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AppInfoSection extends StatelessWidget {
  final FDroidApp app;

  const _AppInfoSection({required this.app});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        return FutureBuilder<FDroidVersion?>(
          future: appProvider.getLatestVersion(app),
          builder: (context, snapshot) {
            final latestVersion = snapshot.data;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: 16,
              children: [
                if (app.antiFeatures != null)
                  Column(
                    spacing: 4,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MListHeader(title: 'Anti-features'),
                      Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: app.antiFeatures?.isNotEmpty == true
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  spacing: 16,
                                  children: app.antiFeatures!
                                      .map(
                                        (antiFeature) => Text(
                                          '- $antiFeature',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.error,
                                              ),
                                        ),
                                      )
                                      .toList(),
                                )
                              : Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.no_antifeature_listed,
                                ),
                        ),
                      ),
                    ],
                  ),
                Column(
                  spacing: 4,
                  children: [
                    MListHeader(
                      title: AppLocalizations.of(context)!.app_information,
                    ),
                    MListView(
                      items: [
                        MListItemData(
                          leading: ListIcon(iconData: Symbols.package_rounded),
                          title: AppLocalizations.of(context)!.package_name,
                          subtitle: app.packageName,
                          onTap: () {},
                        ),
                        MListItemData(
                          leading: ListIcon(iconData: Symbols.license_rounded),
                          title: AppLocalizations.of(context)!.license,
                          subtitle: app.license,
                          onTap: () {},
                        ),
                        if (app.added != null)
                          MListItemData(
                            leading: ListIcon(iconData: Symbols.add),
                            title: AppLocalizations.of(context)!.added,
                            subtitle: _formatDate(app.added!),
                            onTap: () {},
                          ),
                        if (app.added != null)
                          MListItemData(
                            leading: ListIcon(iconData: Symbols.update),
                            title: AppLocalizations.of(context)!.last_updated,
                            subtitle: _formatDate(app.lastUpdated!),
                            onTap: () {},
                          ),
                        if (latestVersion?.permissions?.isNotEmpty == true)
                          MListItemData(
                            leading: ListIcon(iconData: Symbols.security),
                            title: AppLocalizations.of(context)!.permissions,
                            subtitle: '(${latestVersion!.permissions!.length})',
                            suffix: Icon(Symbols.arrow_forward),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PermissionsScreen(
                                    permissions: latestVersion.permissions!,
                                    appName: app.name,
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 4.0,
      children: [
        MListHeader(
          title: 'Description',
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
              if (_isExpanded) {
                _animationController.forward();
              } else {
                _animationController.reverse();
              }
            });
          },
          trailing: Icon(
            _isExpanded ? Symbols.expand_less : Symbols.expand_more,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  colors: [Colors.black, Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(bounds);
              },
              blendMode: _isExpanded ? BlendMode.dst : BlendMode.dstIn,
              child: MarkupContent(
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
                  "p": Style(
                    margin: Margins.only(bottom: 8),
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  "ul": Style(
                    margin: Margins.only(bottom: 8),
                    padding: HtmlPaddings.only(left: 20),
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  "ol": Style(
                    margin: Margins.only(bottom: 8),
                    padding: HtmlPaddings.only(left: 20),
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  "li": Style(
                    margin: Margins.only(bottom: 4),
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  "a": Style(
                    color: Theme.of(context).colorScheme.primary,
                    textDecoration: TextDecoration.underline,
                  ),
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class IncludeUnstableSection extends StatefulWidget {
  final FDroidApp app;
  const IncludeUnstableSection({super.key, required this.app});

  @override
  State<IncludeUnstableSection> createState() => _IncludeUnstableSectionState();
}

class _IncludeUnstableSectionState extends State<IncludeUnstableSection> {
  @override
  Widget build(BuildContext context) {
    if (widget.app.packages != null &&
        widget.app.packages!.values.any((v) => v.isUnstable)) {
      return FutureBuilder<bool>(
        future: context.read<AppProvider>().getIncludeUnstable(
          widget.app.packageName,
        ),
        builder: (context, snapshot) {
          final includeUnstable = snapshot.data ?? false;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child:
                Card.outlined(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Symbols.science,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Include unstable versions',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                'Show beta, alpha, and prerelease versions for this app',
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
                        Switch(
                          value: includeUnstable,
                          onChanged: (value) async {
                            await context
                                .read<AppProvider>()
                                .setIncludeUnstable(
                                  widget.app.packageName,
                                  value,
                                );
                            // Rebuild the widget to reflect the change
                            if (mounted) {
                              setState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(
                  delay: Duration(milliseconds: 300),
                  duration: Duration(milliseconds: 300),
                ),
          );
        },
      );
    }
    return const SizedBox.shrink();
  }
}

class _VersionInfoSection extends StatefulWidget {
  final FDroidVersion version;

  const _VersionInfoSection({required this.version});

  @override
  State<_VersionInfoSection> createState() => _VersionInfoSectionState();
}

class _VersionInfoSectionState extends State<_VersionInfoSection> {
  bool _showMinAndroid = true;
  bool _showTargetAndroid = true;

  String _androidVersionName(int sdk) {
    return kAndroidSdkVersions[sdk] ?? 'Android (SDK $sdk)';
  }

  String _androidVersionLabel(String sdkValue) {
    final sdk = int.tryParse(sdkValue);
    if (sdk == null) {
      return 'Android (SDK $sdkValue)';
    }
    return _androidVersionName(sdk);
  }

  @override
  Widget build(BuildContext context) {
    final version = widget.version;

    buildVersionInfoModel() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                        title: _showMinAndroid
                            ? 'Minimum Android Version'
                            : 'Min SDK',
                        subtitle: _showMinAndroid
                            ? _androidVersionLabel(version.minSdkVersion!)
                            : version.minSdkVersion!,
                        onTap: () {
                          setState(() {
                            _showMinAndroid = !_showMinAndroid;
                          });
                        },
                      ),
                    if (version.targetSdkVersion != null)
                      MListItemData(
                        title: _showTargetAndroid
                            ? 'Target Android Version'
                            : 'Target SDK',
                        subtitle: _showTargetAndroid
                            ? _androidVersionLabel(version.targetSdkVersion!)
                            : version.targetSdkVersion!,
                        onTap: () {
                          setState(() {
                            _showTargetAndroid = !_showTargetAndroid;
                          });
                        },
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MListView(
          items: [
            MListItemData(
              title: AppLocalizations.of(context)!.version_information,
              subtitle: '',
              leading: Icon(Symbols.info),
              onTap: () {
                buildVersionInfoModel();
              },
              suffix: Icon(Symbols.arrow_forward),
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

class AppExtraInfoSection extends StatefulWidget {
  final FDroidApp app;
  const AppExtraInfoSection({super.key, required this.app});

  @override
  State<AppExtraInfoSection> createState() => _AppExtraInfoSectionState();
}

class _AppExtraInfoSectionState extends State<AppExtraInfoSection> {
  List<MapEntry<String, String>> _buildDonationItems() {
    final entries = <MapEntry<String, String>>[];
    final seen = <String>{};

    void addEntry(String label, String? rawLink) {
      final link = rawLink?.trim();
      if (link == null || link.isEmpty) return;
      if (seen.contains(link)) return;
      seen.add(link);
      entries.add(MapEntry(label, link));
    }

    void parseDonateField(String? rawDonate) {
      if (rawDonate == null) return;
      final raw = rawDonate.trim();
      if (raw.isEmpty) return;

      String normalizeLabel(String key) {
        final normalizedKey = key.trim().toLowerCase();
        if (normalizedKey.contains('bitcoin')) return 'Bitcoin';
        if (normalizedKey.contains('flattr')) return 'Flattr';
        if (normalizedKey.contains('liberapay')) return 'Liberapay';
        if (normalizedKey.contains('collective')) return 'Open Collective';
        return 'Donate';
      }

      void parseSingleEntry(String line) {
        var value = line.trim();
        if (value.isEmpty) return;

        value = value
            .replaceAll('{', '')
            .replaceAll('}', '')
            .replaceAll('"', '')
            .replaceAll("'", '')
            .trim();
        if (value.isEmpty) return;

        final match = RegExp(
          r'^([A-Za-z][A-Za-z0-9_ ]{0,40})\s*[:=]\s*(.+)$',
        ).firstMatch(value);
        if (match != null) {
          final key = match.group(1)?.trim() ?? '';
          final parsedValue = match.group(2)?.trim() ?? '';
          if (parsedValue.isNotEmpty && !parsedValue.startsWith('//')) {
            addEntry(normalizeLabel(key), parsedValue);
            return;
          }
        }

        addEntry('Donate', value);
      }

      // Map-like format from metadata can become:
      // {regular: https://..., bitcoin: bitcoin:..., liberapay: https://...}
      if (raw.startsWith('{') && raw.endsWith('}')) {
        final body = raw.substring(1, raw.length - 1);
        final pairs = body.split(',');
        for (final pair in pairs) {
          parseSingleEntry(pair);
        }
        return;
      }

      // List-like format from metadata can become: [https://..., https://...]
      if (raw.startsWith('[') && raw.endsWith(']')) {
        final inner = raw.substring(1, raw.length - 1);
        final values = inner
            .split(',')
            .map((e) => e.trim().replaceAll('"', '').replaceAll("'", ''))
            .where((e) => e.isNotEmpty);
        for (final value in values) {
          parseSingleEntry(value);
        }
        return;
      }

      // Multi-line fallback
      final byLines = raw
          .split(RegExp(r'\r?\n'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (byLines.length > 1) {
        for (final value in byLines) {
          parseSingleEntry(value);
        }
        return;
      }

      parseSingleEntry(raw);
    }

    parseDonateField(widget.app.donate);
    addEntry('Bitcoin', widget.app.bitcoin);
    addEntry('Flattr', widget.app.flattrID);

    return entries;
  }

  Uri? _resolveDonationUri(String label, String rawValue) {
    var value = rawValue.trim();
    if (value.isEmpty) return null;

    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      value = value.substring(1, value.length - 1).trim();
    }

    final direct = Uri.tryParse(value);
    if (direct != null && direct.hasScheme) {
      return direct;
    }

    final lowerLabel = label.toLowerCase();

    if (lowerLabel.contains('bitcoin')) {
      final maybeAddress = value.replaceAll('bitcoin:', '').trim();
      if (maybeAddress.isEmpty) return null;
      return Uri.parse('bitcoin:$maybeAddress');
    }

    if (lowerLabel.contains('flattr')) {
      if (value.startsWith('@')) {
        value = value.substring(1);
      }
      return Uri.parse('https://flattr.com/@$value');
    }

    if (lowerLabel.contains('liberapay')) {
      if (value.startsWith('@')) {
        value = value.substring(1);
      }
      return Uri.parse('https://liberapay.com/$value');
    }

    if (lowerLabel.contains('collective')) {
      if (value.startsWith('@')) {
        value = value.substring(1);
      }
      return Uri.parse('https://opencollective.com/$value');
    }

    return Uri.tryParse('https://$value');
  }

  Future<void> _openDonateLink(
    BuildContext context,
    String label,
    String link,
  ) async {
    final launchUri = _resolveDonationUri(label, link);
    if (launchUri == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Invalid donation link: $link')));
      }
      return;
    }

    final opened = await launchUrl(
      launchUri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open donation link: $link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final donationItems = _buildDonationItems();
    if (donationItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        MListView(
          items: [
            if (widget.app.webSite != null)
              MListItemData(
                leading: ListIcon(iconData: Symbols.public),
                title: AppLocalizations.of(context)!.website,
                onTap: () async {
                  if (widget.app.webSite != null) {
                    await launchUrl(Uri.parse(widget.app.webSite!));
                  }
                },
                suffix: Icon(Symbols.open_in_new_rounded),
              ),
            if (widget.app.sourceCode != null)
              MListItemData(
                leading: ListIcon(iconData: Symbols.code),
                title: AppLocalizations.of(context)!.source_code,
                onTap: () async {
                  if (widget.app.webSite != null) {
                    await launchUrl(Uri.parse(widget.app.sourceCode!));
                  }
                },
                suffix: Icon(Symbols.open_in_new_rounded),
              ),
            if (widget.app.issueTracker != null)
              MListItemData(
                leading: ListIcon(iconData: Symbols.bug_report),
                title: AppLocalizations.of(context)!.issue_tracker,
                onTap: () async {
                  if (widget.app.webSite != null) {
                    await launchUrl(Uri.parse(widget.app.issueTracker!));
                  }
                },
                suffix: Icon(Symbols.open_in_new_rounded),
              ),
          ],
        ),
        SizedBox(height: 16),
        MListHeader(
          icon: Symbols.volunteer_activism_rounded,
          title: AppLocalizations.of(context)!.support_the_developer,
        ),
        MListView(
          items: [
            for (final item in donationItems)
              MListItemData(
                title: item.key,
                subtitle: item.value,
                suffix: const Icon(Symbols.open_in_new_rounded),
                onTap: () => _openDonateLink(context, item.key, item.value),
              ),
          ],
        ),
      ],
    );
  }
}

class AppDetailsIcon extends StatefulWidget {
  final FDroidApp app;
  const AppDetailsIcon({super.key, required this.app});

  @override
  State<AppDetailsIcon> createState() => _AppDetailsIconState();
}

class _AppDetailsIconState extends State<AppDetailsIcon> {
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
        color: Colors.white.withValues(alpha: 0.2),
        child: const Icon(Symbols.android, color: Colors.white, size: 40),
      );
    }

    if (_index >= _candidates.length) {
      return Container(
        color: Colors.white.withValues(alpha: 0.2),
        child: const Icon(Symbols.apps, color: Colors.white, size: 40),
      );
    }

    final url = _candidates[_index];
    return CachedNetworkImage(
      imageUrl: url,
      cacheKey: '${widget.app.packageName}:$url',
      imageBuilder: (context, imageProvider) => Image(
        image: imageProvider,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
      ),
      errorWidget: (context, _, _) {
        // Move to next candidate or fallback.
        _next();
        return Container(
          color: Colors.white.withValues(alpha: 0.2),
          child: const Icon(
            Symbols.broken_image,
            color: Colors.white,
            size: 40,
          ),
        );
      },
      placeholder: (context, _) => Container(
        color: Colors.white.withValues(alpha: 0.2),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
      // Suppress per-attempt error spam for fallback candidates.
      errorListener: (_) {},
    );
  }
}

class _AllVersionsSection extends StatelessWidget {
  final FDroidApp app;

  const _AllVersionsSection({required this.app});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        return FutureBuilder<List<Object?>>(
          future: Future.wait([
            appProvider.getIncludeUnstable(app.packageName),
            appProvider.getSupportedAbis(),
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox.shrink();
            }

            final includeUnstable = (snapshot.data?[0] as bool?) ?? false;
            final supportedAbis =
                (snapshot.data?[1] as List<String>?) ?? const <String>[];

            var versions = app.packages?.values.toList() ?? [];
            if (versions.isEmpty) return const SizedBox.shrink();

            if (!includeUnstable) {
              versions = versions.where((v) => !v.isUnstable).toList();
              if (versions.isEmpty) return const SizedBox.shrink();
            }

            bool isUniversal(FDroidVersion v) =>
                v.nativecode == null || v.nativecode!.isEmpty;

            bool supportsDevice(FDroidVersion v) {
              if (isUniversal(v)) return true;
              if (supportedAbis.isEmpty) return true;
              return v.nativecode!.any((abi) => supportedAbis.contains(abi));
            }

            // Filter out incompatible ABIs; if none remain, fall back to show all
            final compatible = versions.where(supportsDevice).toList();
            if (compatible.isNotEmpty) {
              versions = compatible;
            }

            versions.sort((a, b) => b.versionCode.compareTo(a.versionCode));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8.0,
              children: [
                MListHeader(title: 'All Versions'),
                MListViewBuilder(
                  itemCount: versions.length,
                  itemBuilder: (index) {
                    final version = versions[index];
                    final isLatest = version == versions.first;
                    final compatibleAbi = supportsDevice(version);
                    final installedApp = appProvider.getInstalledApp(
                      app.packageName,
                    );
                    final isInstalledVersion =
                        appProvider.isAppInstalled(app.packageName) &&
                        installedApp != null &&
                        (installedApp.versionCode != null
                            ? installedApp.versionCode == version.versionCode
                            : installedApp.versionName == version.versionName);
                    return MListItemData(
                      title: version.versionName,
                      subtitle: version.sizeString,
                      suffix: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isInstalledVersion)
                            IconButton.filledTonal(
                              style: FilledButton.styleFrom(
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.errorContainer,
                              ),
                              onPressed: () async {
                                try {
                                  await context
                                      .read<DownloadProvider>()
                                      .uninstallApp(app.packageName);
                                  await Future.delayed(
                                    const Duration(milliseconds: 100),
                                  );
                                  await appProvider.fetchInstalledApps();
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Uninstall failed: $e'),
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Symbols.delete_rounded, fill: 1),
                            )
                          else ...[
                            IconButton(
                              onPressed: compatibleAbi
                                  ? () async {
                                      final url = version.downloadUrl(
                                        app.repositoryUrl,
                                      );
                                      await launchUrl(Uri.parse(url));
                                    }
                                  : null,
                              icon: const Icon(Symbols.open_in_new_rounded),
                            ),
                            IconButton.filledTonal(
                              onPressed: compatibleAbi
                                  ? () async {
                                      try {
                                        final appWithVersion = app
                                            .copyWithVersion(version);
                                        await context
                                            .read<DownloadProvider>()
                                            .downloadApk(appWithVersion);
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Download failed: $e',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  : null,
                              icon: const Icon(Symbols.download),
                            ),
                          ],
                        ],
                      ),
                      selected: isLatest,
                      onTap: () {
                        // Scroll to the tapped version's section
                        // This requires a more complex setup with GlobalKeys or a scroll controller
                        // For simplicity, we'll just show a snackbar here
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Tapped on version ${version.versionName}',
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}

enum _ShizukuAction { switchToSystem, cancel }

Future<void> _handleShizukuUnavailable(
  BuildContext context,
  SettingsProvider settings,
) async {
  final action = await showDialog<_ShizukuAction>(
    context: context,
    builder: (context) => SimpleDialog(
      contentPadding: EdgeInsets.all(24),
      title: const Text('Shizuku is not running'),
      children: [
        Text(
          'Start the Shizuku app to continue, or switch to the system installer instead.',
        ),
        SizedBox(height: 16),
        Column(
          spacing: 2.0,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              onPressed: () async {
                try {
                  final appProvider = context.read<AppProvider>();
                  await appProvider.openInstalledApp(
                    'moe.shizuku.privileged.api',
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Unable to open Shizuku app'),
                      ),
                    );
                  }
                }
              },
              child: Text(AppLocalizations.of(context)!.open_shizuku),
            ),
            FilledButton.tonal(
              onPressed: () =>
                  Navigator.of(context).pop(_ShizukuAction.switchToSystem),
              child: Text(AppLocalizations.of(context)!.use_system_installer),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(_ShizukuAction.cancel),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
          ],
        ),
      ],
    ),
  );

  if (action == _ShizukuAction.switchToSystem) {
    await settings.setInstallMethod(InstallMethod.system);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Switched to system installer')),
      );
    }
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
    if (widget.screenshots.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8.0,
      children: [
        SizedBox(
          height: 400,
          child: CarouselView.weighted(
            flexWeights: const [2, 2],
            shrinkExtent: 250,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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

              return Builder(
                builder: (context) {
                  return Material(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
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
                              const CircularProgressIndicator(),
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
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.black38,
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
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Image.network(
                _getScreenshotUrl(screenshot),
                filterQuality: FilterQuality.high,
                fit: BoxFit.contain,
                height: double.infinity,
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
          );
        },
      ),
    );
  }
}
