import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/download_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/repositories_screen.dart';
import '../services/fdroid_api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _appVersion = '${info.version}+${info.buildNumber}';
    });
  }

  Future<void> _clearRepoCache(BuildContext context) async {
    final api = context.read<FDroidApiService>();
    await api.clearRepositoryCache();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Repository cache cleared')));
  }

  Future<void> _clearImageCache(BuildContext context) async {
    await DefaultCacheManager().emptyCache();
    imageCache.clear();
    imageCache.clearLiveImages();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Image cache cleared')));
  }

  Future<void> _clearApkDownloads(BuildContext context) async {
    final deleted = await context.read<DownloadProvider>().clearAllDownloads();
    if (!mounted) return;
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
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _SectionHeader(label: 'Appearance'),
              RadioListTile<ThemeMode>(
                title: const Text('System default'),
                value: ThemeMode.system,
                groupValue: settings.themeMode,
                onChanged: (mode) {
                  if (mode != null) settings.setThemeMode(mode);
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Light'),
                value: ThemeMode.light,
                groupValue: settings.themeMode,
                onChanged: (mode) {
                  if (mode != null) settings.setThemeMode(mode);
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark'),
                value: ThemeMode.dark,
                groupValue: settings.themeMode,
                onChanged: (mode) {
                  if (mode != null) settings.setThemeMode(mode);
                },
              ),
              const Divider(height: 24),

              _SectionHeader(label: 'Language'),
              ListTile(
                leading: const Icon(Symbols.language),
                title: const Text('App content language'),
                subtitle: Text(
                  SettingsProvider.getLocaleDisplayName(settings.locale),
                ),
                trailing: const Icon(Symbols.chevron_right),
                onTap: () => _showLanguageDialog(context, settings),
              ),
              const Divider(height: 24),

              _SectionHeader(label: 'Repositories'),
              ListTile(
                leading: const Icon(Symbols.cloud),
                title: const Text('Manage repositories'),
                subtitle: const Text('Add or remove F-Droid repositories'),
                trailing: const Icon(Symbols.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RepositoriesScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 24),

              _SectionHeader(label: 'Downloads'),
              SwitchListTile(
                title: const Text('Auto-install after download'),
                subtitle: const Text(
                  'Install APKs automatically once download finishes',
                ),
                value: settings.autoInstallApk,
                onChanged: (value) => settings.setAutoInstallApk(value),
              ),
              SwitchListTile(
                title: const Text('Delete APK after install'),
                subtitle: const Text(
                  'Remove installer files after successful installation',
                ),
                value: settings.autoDeleteApk,
                onChanged: (value) => settings.setAutoDeleteApk(value),
              ),
              const Divider(height: 24),

              _SectionHeader(label: 'Storage & cache'),
              ListTile(
                leading: const Icon(Symbols.cleaning_services),
                title: const Text('Clear repository cache'),
                subtitle: const Text(
                  'Refresh app list and metadata on next load',
                ),
                onTap: () => _clearRepoCache(context),
              ),
              ListTile(
                leading: const Icon(Symbols.delete_sweep),
                title: const Text('Clear APK downloads'),
                subtitle: const Text(
                  'Remove downloaded installer files from storage',
                ),
                onTap: () => _clearApkDownloads(context),
              ),
              ListTile(
                leading: const Icon(Symbols.image_not_supported),
                title: const Text('Clear image cache'),
                subtitle: const Text('Remove cached icons and screenshots'),
                onTap: () => _clearImageCache(context),
              ),
              const Divider(height: 24),

              _SectionHeader(label: 'About'),
              ListTile(
                leading: const Icon(Symbols.info),
                title: const Text('Version'),
                subtitle: Text(_appVersion.isEmpty ? 'Loading…' : _appVersion),
              ),
              ListTile(
                leading: const Icon(Symbols.share),
                title: const Text('Share Florid'),
                onTap: () {
                  Share.share('Check out Florid, a modern F-Droid client!');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showLanguageDialog(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: SettingsProvider.availableLocales.length,
            itemBuilder: (context, index) {
              final locale = SettingsProvider.availableLocales[index];
              final displayName = SettingsProvider.getLocaleDisplayName(locale);

              return RadioListTile<String>(
                title: Text(displayName),
                subtitle: Text(locale),
                value: locale,
                groupValue: settings.locale,
                onChanged: (value) async {
                  if (value != null) {
                    await settings.setLocale(value);
                    if (!context.mounted) return;

                    // Update API service locale
                    final apiService = context.read<FDroidApiService>();
                    apiService.setLocale(value);

                    Navigator.pop(context);

                    // Show message that data will be refreshed
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Language changed. Repository will refresh on next load.',
                        ),
                      ),
                    );
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
