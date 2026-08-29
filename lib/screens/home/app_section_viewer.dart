import 'package:florid/l10n/app_localizations.dart';
import 'package:florid/models/fdroid_app.dart';
import 'package:florid/providers/app_provider.dart';
import 'package:florid/providers/download_provider.dart';
import 'package:florid/providers/settings_provider.dart';
import 'package:florid/screens/app_details/app_details_screen.dart';
import 'package:florid/widgets/app_list_item.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:solar_icons/solar_icons.dart';

class AppSectionViewer extends StatefulWidget {
  const AppSectionViewer({
    super.key,
    required this.title,
    required this.stateSelector,
    required this.appsSelector,
    required this.errorSelector,
    required this.onRefresh,
    required this.loadingMessage,
    required this.emptyMessage,
    required this.emptyIcon,
    this.subtitle,
    this.loadOnInit = true,
    this.showInstallStatus = false,
    this.showRank = false,
    this.showDownloadBadge = false,
    this.showAppBar = true,
    this.onUpdate,
    this.downloadsSelector,
    this.addFloridBottomSpacing = false,
  });

  final String title;
  final String? subtitle;
  final LoadingState Function(AppProvider appProvider) stateSelector;
  final List<FDroidApp> Function(AppProvider appProvider) appsSelector;
  final String? Function(AppProvider appProvider) errorSelector;
  final Future<void> Function(BuildContext context) onRefresh;
  final String loadingMessage;
  final String emptyMessage;
  final IconData emptyIcon;
  final bool loadOnInit;
  final bool showInstallStatus;
  final bool showRank;
  final bool showDownloadBadge;
  final bool showAppBar;
  final Future<void> Function(BuildContext context, FDroidApp app)? onUpdate;
  final Map<String, int> Function(AppProvider appProvider)? downloadsSelector;
  final bool addFloridBottomSpacing;

  @override
  State<AppSectionViewer> createState() => _AppSectionViewerState();
}

class _AppSectionViewerState extends State<AppSectionViewer>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.loadOnInit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onRefresh(context);
      });
    }
  }

  String _formatDownloads(int downloads) {
    if (downloads >= 1000000) {
      return '${(downloads / 1000000).toStringAsFixed(1)}M';
    }
    if (downloads >= 1000) {
      return '${(downloads / 1000).toStringAsFixed(1)}K';
    }
    return downloads.toString();
  }

  Future<void> _defaultUpdateApp(BuildContext context, FDroidApp app) async {
    final downloadProvider = context.read<DownloadProvider>();
    final downloadInfo = downloadProvider.getDownloadInfo(
      app.packageName,
      app.latestVersion?.versionName ?? '',
    );
    if (downloadInfo?.status == DownloadStatus.downloading) {
      return;
    }

    try {
      await downloadProvider.downloadApk(app);

      if (context.mounted) {
        await Future.delayed(const Duration(seconds: 3));
        final finalDownloadInfo = downloadProvider.getDownloadInfo(
          app.packageName,
          app.latestVersion?.versionName ?? '',
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

  Widget _buildTitle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: const TextStyle(
            fontFamily: 'Google Sans Flex',
            fontSize: 16,
            fontVariations: [
              FontVariation('wght', 700),
              FontVariation('ROND', 100),
            ],
          ),
        ),
        if (widget.subtitle != null)
          Text(
            widget.subtitle!,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  Widget _buildError(
    BuildContext context,
    AppLocalizations localizations,
    String? error,
  ) {
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
            localizations.failed_to_load_apps,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          SelectableText(
            error ?? localizations.unknown_error_occurred,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => widget.onRefresh(context),
            icon: const Icon(Symbols.refresh),
            label: Text(localizations.try_again),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.emptyIcon,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            widget.emptyMessage,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildAppListItem(
    BuildContext context,
    FDroidApp app,
    int index,
    Map<String, int> downloadsByPackage,
  ) {
    return Row(
      children: [
        Expanded(
          child: Stack(
            children: [
              AppListItem(
                key: ValueKey(app.packageName),
                app: app,
                showRanking: widget.showRank,
                rankingNumber: '${index + 1}',
                showInstallStatus: widget.showInstallStatus,
                onUpdate: () {
                  final updateHandler = widget.onUpdate;
                  if (updateHandler != null) {
                    updateHandler(context, app);
                    return;
                  }
                  _defaultUpdateApp(context, app);
                },
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AppDetailsScreen(app: app),
                    ),
                  );
                },
              ).animate().fadeIn(duration: 300.ms, delay: (10 * index).ms),
              if (widget.showDownloadBadge &&
                  downloadsByPackage.containsKey(app.packageName))
                Positioned(
                  right: 12,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Theme.of(context).colorScheme.surfaceContainer,
                    ),
                    child: Text(
                      _formatDownloads(downloadsByPackage[app.packageName]!),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final localizations = AppLocalizations.of(context)!;

    return Consumer2<AppProvider, SettingsProvider>(
      builder: (context, appProvider, settingsProvider, child) {
        final state = widget.stateSelector(appProvider);
        final apps = widget.appsSelector(appProvider);
        final error = widget.errorSelector(appProvider);
        final downloadsByPackage =
            widget.downloadsSelector?.call(appProvider) ??
            const <String, int>{};
        final isFlorid = settingsProvider.themeStyle == ThemeStyle.florid;
        final isDarkKnight =
            settingsProvider.themeStyle == ThemeStyle.darkKnight;
        final bottomPadding =
            widget.addFloridBottomSpacing && (isFlorid || isDarkKnight)
            ? 100.0
            : 8.0;

        final hasApps = apps.isNotEmpty;
        return Scaffold(
          body: hasApps
              ? RefreshIndicator(
                  onRefresh: () => widget.onRefresh(context),
                  child: CustomScrollView(
                    slivers: [
                      if (widget.showAppBar)
                        SliverAppBar(
                          floating: true,
                          leading: IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: Icon(SolarIconsOutline.altArrowLeft),
                          ),
                          title: _buildTitle(context),
                        ),
                      SliverPadding(
                        padding: EdgeInsets.only(
                          left: 8,
                          right: 8,
                          top: 8,
                          bottom: bottomPadding,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final app = apps[index];
                            return _buildAppListItem(
                              context,
                              app,
                              index,
                              downloadsByPackage,
                            );
                          }, childCount: apps.length),
                        ),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    if (widget.showAppBar)
                      SliverAppBar(
                        floating: true,
                        leading: IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: Icon(SolarIconsOutline.altArrowLeft),
                        ),
                        title: _buildTitle(context),
                      ),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: state == LoadingState.loading
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const M3EContainedLoadingIndicator(

                                  ),
                                  const SizedBox(height: 16),
                                  Text(widget.loadingMessage),
                                ],
                              ),
                            )
                          : state == LoadingState.error
                          ? _buildError(context, localizations, error)
                          : _buildEmpty(context),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
