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

  String _installMethodLabel(AppLocalizations l10n, InstallMethod method) {
    switch (method) {
      case InstallMethod.shizuku:
        return l10n.shizuku;
      case InstallMethod.system:
      default:
        return l10n.system_installer;
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
                  title: Text(
                    _installMethodLabel(
                      AppLocalizations.of(context)!,
                      method,
                    ),
                  ),
                  subtitle: method == InstallMethod.shizuku
                      ? Text(
                          AppLocalizations.of(
                            context,
                          )!.requires_shizuku_running,
                        )
                      : Text(
                          AppLocalizations.of(
                            context,
                          )!.uses_standard_system_installer,
                        ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.repository_cache_cleared),
      ),
    );
  }

  Future<void> _clearImageCache(BuildContext context) async {
    await DefaultCacheManager().emptyCache();
    imageCache.clear();
    imageCache.clearLiveImages();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.image_cache_cleared),
      ),
    );
  }

  Future<void> _clearApkDownloads(BuildContext context) async {
    final deleted = await context.read<DownloadProvider>().clearAllDownloads();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted > 0
              ? AppLocalizations.of(context)!.deleted_apk_files(deleted)
              : AppLocalizations.of(context)!.no_apk_downloads_to_delete,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final l10n = AppLocalizations.of(context)!;
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
                title: Text(l10n.troubleshooting),
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
                          MListHeader(title: l10n.downloads_and_storage),
                          MListView(
                            items: [
                              MListItemData(
                                title: l10n.installation_method,
                                subtitle: _installMethodLabel(
                                  l10n,
                                  settings.installMethod,
                                ),
                                onTap: () =>
                                    _showInstallMethodDialog(context, settings),
                                suffix: const Icon(Symbols.chevron_right),
                              ),
                              MListItemData(
                                title: l10n.auto_install_after_download,
                                onTap: () {
                                  settings.setAutoInstallApk(
                                    !settings.autoInstallApk,
                                  );
                                },
                                subtitle: l10n.auto_install_after_download_subtitle,
                                suffix: Switch(
                                  value: settings.autoInstallApk,
                                  onChanged: (value) {
                                    settings.setAutoInstallApk(value);
                                  },
                                ),
                              ),
                              MListItemData(
                                title: l10n.delete_apk_after_install,
                                onTap: () {
                                  settings.setAutoInstallApk(
                                    !settings.autoInstallApk,
                                  );
                                },
                                subtitle: l10n.delete_apk_after_install_subtitle,
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
                                title: l10n.clear_repository_cache,
                                onTap: () => _clearRepoCache(context),
                                subtitle: l10n.clear_repository_cache_subtitle,
                              ),
                              MListItemData(
                                leading: ListIcon(
                                  iconData: Symbols.delete_sweep,
                                ),
                                title: l10n.clear_apk_downloads,
                                onTap: () => _clearApkDownloads(context),
                                subtitle: l10n.clear_apk_downloads_subtitle,
                              ),
                              MListItemData(
                                leading: ListIcon(
                                  iconData: Symbols.image_not_supported,
                                ),
                                title: l10n.clear_image_cache,
                                onTap: () => _clearImageCache(context),
                                subtitle: l10n.clear_image_cache_subtitle,
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
