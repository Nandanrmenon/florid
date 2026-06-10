import 'package:florid/l10n/app_localizations.dart';
import 'package:florid/providers/download_provider.dart';
import 'package:florid/providers/settings_provider.dart';
import 'package:florid/services/fdroid_api_service.dart';
import 'package:florid/widgets/list_icon.dart';
import 'package:florid/widgets/m_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:solar_icons/solar_icons.dart';

class TroubleshootingScreen extends StatelessWidget {
  const TroubleshootingScreen({super.key});

  String _installMethodLabel(InstallMethod method) {
    switch (method) {
      case InstallMethod.shizuku:
        return 'Shizuku';
      case InstallMethod.dhizuku:
        return 'Dhizuku';
      case InstallMethod.system:
        return 'System installer';
    }
  }

  String _installMethodSubtitle(BuildContext context, InstallMethod method) {
    final localizations = AppLocalizations.of(context)!;
    switch (method) {
      case InstallMethod.shizuku:
        return localizations.requires_shizuku_running;
      case InstallMethod.dhizuku:
        return localizations.requires_dhizuku_active;
      case InstallMethod.system:
        return localizations.uses_standard_system_installer;
    }
  }

  Future<void> _showInstallMethodDialog(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.installation_method),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: InstallMethod.values
              .map(
                (method) => RadioListTile<InstallMethod>(
                  value: method,
                  groupValue: settings.installMethod,
                  title: Text(_installMethodLabel(method)),
                  subtitle: Text(_installMethodSubtitle(context, method)),
                  onChanged: (value) async {
                    if (value == null) return;
                    await settings.setInstallMethod(value);
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  },
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }

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
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                leading: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(SolarIconsOutline.altArrowLeft),
                ),
                title: Text(AppLocalizations.of(context)!.troubleshooting),
              ),
              SliverToBoxAdapter(
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
                                title: 'Installation method',
                                subtitle: _installMethodLabel(
                                  settings.installMethod,
                                ),
                                onTap: () =>
                                    _showInstallMethodDialog(context, settings),
                                suffix: const Icon(Symbols.chevron_right),
                              ),
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
                                leading: ListIcon(
                                  iconData: Symbols.cleaning_services,
                                ),
                                title: 'Clear repository cache',
                                onTap: () => _clearRepoCache(context),
                                subtitle:
                                    'Refresh app list and metadata on next load',
                              ),
                              MListItemData(
                                leading: ListIcon(
                                  iconData: Symbols.delete_sweep,
                                ),
                                title: 'Clear APK downloads',
                                onTap: () => _clearApkDownloads(context),
                                subtitle:
                                    'Remove downloaded installer files from storage',
                              ),
                              MListItemData(
                                leading: ListIcon(
                                  iconData: Symbols.image_not_supported,
                                ),
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
            ],
          ),
        );
      },
    );
  }
}
