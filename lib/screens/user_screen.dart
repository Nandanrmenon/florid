import 'package:florid/l10n/app_localizations.dart';
import 'package:florid/models/fdroid_app.dart';
import 'package:florid/providers/app_provider.dart';
import 'package:florid/providers/download_provider.dart';
import 'package:florid/providers/settings_provider.dart';
import 'package:florid/screens/app_details_screen.dart';
import 'package:florid/screens/settings_screen.dart';
import 'package:florid/utils/menu_actions.dart';
import 'package:florid/widgets/app_list_item.dart';
import 'package:florid/widgets/changelog_preview.dart';
import 'package:florid/widgets/f_tabbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    final appProvider = context.read<AppProvider>();
    // Load both repository data and installed apps
    appProvider.fetchRepository();
    appProvider.fetchInstalledApps();
  }

  Widget _buildFavoritesTab(
    BuildContext context,
    AppProvider appProvider,
    SettingsProvider settingsProvider,
    List<FDroidApp> favoriteApps,
    List<FDroidApp> updatableApps,
    bool repositoryLoaded,
    LoadingState repositoryState,
    String? repositoryError,
  ) {
    if (repositoryState == LoadingState.loading && !repositoryLoaded) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(year2023: false),
            SizedBox(height: 12),
            Text('Loading repository…'),
          ],
        ),
      );
    }

    if (!repositoryLoaded && repositoryState == LoadingState.error) {
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
                    label: const Text('Retry'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => MenuActions.showSettings(context),
                    icon: const Icon(Symbols.settings),
                    label: const Text('Settings'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (favoriteApps.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Symbols.favorite_rounded,
                size: 64,
                fill: 1,
                color: Colors.pink[600],
              ).animate().scaleXY(
                delay: Duration(milliseconds: 100),
                duration: 500.ms,
                curve: Curves.elasticInOut,
              ),
              const SizedBox(height: 16),
              Text(
                    'No favourites yet',
                    style: Theme.of(context).textTheme.headlineSmall,
                  )
                  .animate()
                  .scaleXY(delay: Duration(milliseconds: 100), duration: 200.ms)
                  .fade(delay: Duration(milliseconds: 100), duration: 500.ms),
              const SizedBox(height: 8),
              Text(
                    'Tap the star on any app to save it here',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  )
                  .animate()
                  .scaleXY(delay: Duration(milliseconds: 300), duration: 200.ms)
                  .fade(delay: Duration(milliseconds: 200), duration: 500.ms),
            ],
          ),
        ),
      );
    }

    final bottomPadding = settingsProvider.themeStyle == ThemeStyle.florid
        ? 96.0
        : 16.0;

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(8, 8, 8, bottomPadding),
      itemCount: favoriteApps.length,
      itemBuilder: (context, index) {
        final app = favoriteApps[index];
        final hasUpdate = updatableApps.any(
          (updateApp) => updateApp.packageName == app.packageName,
        );
        return Card(
          elevation: 0,
          child: Column(
            children: [
              AppListItem(
                app: app,
                showInstallStatus: true,
                showFavorite: true,
                onUpdate: hasUpdate ? () => _updateApp(context, app) : null,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AppDetailsScreen(app: app),
                    ),
                  );
                },
              ),
              if (app.latestVersion?.whatsNew != null &&
                  app.latestVersion!.whatsNew!.isNotEmpty)
                ChangelogPreview(text: app.latestVersion!.whatsNew),
            ],
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

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final repositoryLoaded = appProvider.repository != null;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar.medium(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
            surfaceTintColor: Theme.of(context).colorScheme.surfaceContainerLow,
            title: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onPrimaryContainer,
                  child: settingsProvider.userName.isNotEmpty
                      ? Text(
                          settingsProvider.userName
                              .trim()
                              .substring(0, 1)
                              .toUpperCase(),
                        )
                      : const Icon(Symbols.person),
                ),
                const SizedBox(width: 12),
                Text(
                  settingsProvider.userName.isNotEmpty
                      ? settingsProvider.userName
                      : 'User',
                ),
              ],
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _FTabBarHeaderDelegate(
              height: settingsProvider.themeStyle == ThemeStyle.florid
                  ? 68
                  : 56,
              child: Material(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                surfaceTintColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerLow,
                child: Container(
                  margin: settingsProvider.themeStyle == ThemeStyle.florid
                      ? const EdgeInsets.only(top: 8)
                      : null,
                  child: FTabBar(
                    controller: _tabController,
                    onTabChanged: (index) {
                      _tabController.animateTo(index);
                    },
                    items: [
                      FloridTabBarItem(
                        icon: Symbols.favorite_rounded,
                        label: AppLocalizations.of(context)!.favourites,
                      ),
                      FloridTabBarItem(
                        icon: Symbols.settings,
                        label: AppLocalizations.of(context)!.settings,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            FutureBuilder<List<FDroidApp>>(
              future: repositoryLoaded
                  ? appProvider.getUpdatableApps()
                  : Future.value(<FDroidApp>[]),
              builder: (context, snapshot) {
                final updatableApps = snapshot.data ?? <FDroidApp>[];
                final favoriteApps = repositoryLoaded
                    ? appProvider.getFavoriteApps()
                    : <FDroidApp>[];
                return _buildFavoritesTab(
                  context,
                  appProvider,
                  settingsProvider,
                  favoriteApps,
                  updatableApps,
                  repositoryLoaded,
                  appProvider.repositoryState,
                  appProvider.repositoryError,
                );
              },
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                0,
                16,
                0,
                settingsProvider.themeStyle == ThemeStyle.florid ? 32 : 0,
              ),
              child: SettingsScreen(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FTabBarHeaderDelegate extends SliverPersistentHeaderDelegate {
  _FTabBarHeaderDelegate({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _FTabBarHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}
