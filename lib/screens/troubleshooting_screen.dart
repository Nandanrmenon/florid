import 'package:florid/providers/download_provider.dart';
import 'package:florid/providers/settings_provider.dart';
import 'package:florid/services/fdroid_api_service.dart';
import 'package:florid/widgets/m_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

class TroubleshootingScreen extends StatelessWidget {
  const TroubleshootingScreen({super.key});

  Future<void> _clearRepoCache(BuildContext context) async {
    final api = context.read<FDroidApiService>();
    await api.clearRepositoryCache();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Repository cache cleared')));
  }

  Future<void> _clearImageCache(BuildContext context) async {
    await DefaultCacheManager().emptyCache();
    imageCache.clear();
    imageCache.clearLiveImages();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Image cache cleared')));
  }

  Future<void> _clearApkDownloads(BuildContext context) async {
    final deleted = await context.read<DownloadProvider>().clearAllDownloads();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted > 0
              ? 'Deleted $deleted APK file${deleted == 1 ? '' : 's'}'
              : 'No APK downloads to delete',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Troubleshooting')),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16,
                children: [
                  Column(
                    spacing: 4,
                    children: [
                      MListHeader(title: 'Downloads & Storage'),
                      MListView(
                        items: [
                          MListItemData(
                            title: 'Auto-install after download',
                            onTap: () {
                              settings.setAutoInstallApk(
                                !settings.autoInstallApk,
                              );
                            },
                            subtitle:
                                'Install APKs automatically once download finishes',
                            suffix: Switch(
                              value: settings.autoInstallApk,
                              onChanged: (value) {
                                settings.setAutoInstallApk(value);
                              },
                            ),
                          ),
                          MListItemData(
                            title: 'Delete APK after install',
                            onTap: () {
                              settings.setAutoInstallApk(
                                !settings.autoInstallApk,
                              );
                            },
                            subtitle:
                                'Remove installer files after successful installation',
                            suffix: Switch(
                              value: settings.autoDeleteApk,
                              onChanged: (value) {
                                settings.setAutoDeleteApk(value);
                              },
                            ),
                          ),
                        ],
                      ),
                      MListView(
                        items: [
                          MListItemData(
                            leading: Icon(Symbols.cleaning_services),
                            title: 'Clear repository cache',
                            onTap: () => _clearRepoCache(context),
                            subtitle:
                                'Refresh app list and metadata on next load',
                          ),
                          MListItemData(
                            leading: Icon(Symbols.delete_sweep),
                            title: 'Clear APK downloads',
                            onTap: () => _clearApkDownloads(context),
                            subtitle:
                                'Remove downloaded installer files from storage',
                          ),
                          MListItemData(
                            leading: Icon(Symbols.image_not_supported),
                            title: 'Clear image cache',
                            onTap: () => _clearImageCache(context),
                            subtitle: 'Remove cached icons and screenshots',
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
