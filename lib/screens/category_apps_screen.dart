import 'package:florid/l10n/app_localizations.dart';
import 'package:florid/models/fdroid_app.dart';
import 'package:florid/providers/download_provider.dart';
import 'package:florid/providers/settings_provider.dart';
import 'package:florid/utils/responsive.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../widgets/app_list_item.dart';
import 'app_details_screen.dart';

class CategoryAppsScreen extends StatefulWidget {
  final String category;

  const CategoryAppsScreen({super.key, required this.category});

  @override
  State<CategoryAppsScreen> createState() => _CategoryAppsScreenState();
}

class _CategoryAppsScreenState extends State<CategoryAppsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final appProvider = context.read<AppProvider>();
    appProvider.fetchAppsByCategory(widget.category);
  }

  Future<void> _onRefresh() async {
    final appProvider = context.read<AppProvider>();
    // Clear cached data for this category and reload
    final categoryApps = appProvider.categoryApps;
    categoryApps.remove(widget.category);
    await appProvider.fetchAppsByCategory(widget.category);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<AppProvider>(
          builder: (context, appProvider, child) {
            final settings = context.watch<SettingsProvider>();
            return Column(
              crossAxisAlignment: settings.themeStyle == ThemeStyle.florid
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  widget.category,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${appProvider.categoryApps[widget.category]?.length ?? 0} apps',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          final state = appProvider.categoryAppsState;
          final apps = appProvider.categoryApps[widget.category] ?? [];
          final error = appProvider.categoryAppsError;

          if (state == LoadingState.loading && apps.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(year2023: false),
                  SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.loading_apps),
                ],
              ),
            );
          }

          if (state == LoadingState.error && apps.isEmpty) {
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
                    'Failed to load apps',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error ?? 'Unknown error occurred',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
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

          if (apps.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Symbols.apps, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.no_apps_in_category(widget.category),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (MediaQuery.sizeOf(context).width < Responsive.largeWidth) {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: apps.length,
                    itemBuilder: (context, index) {
                      final app = apps[index];
                      return AppListItem(
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
                      );
                    },
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                    childAspectRatio: 4.4,
                  ),
                  itemCount: apps.length,
                  itemBuilder: (context, index) {
                    final app = apps[index];
                    return Card(
                      child: AppListItem(
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
                    );
                  },
                );
              },
            ),
          );
        },
      ),
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
}
