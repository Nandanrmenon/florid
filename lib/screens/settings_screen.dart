import 'package:florid/widgets/m_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/download_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/device_pairing_screen.dart';
import '../screens/remote_install_screen.dart';
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
                      MListHeader(title: 'Theme Mode'),
                      MRadioListView(
                        items: [
                          MRadioListItemData<ThemeMode>(
                            title: 'Follow system theme',
                            subtitle: '',
                            value: ThemeMode.system,
                          ),
                          MRadioListItemData<ThemeMode>(
                            title: 'Light theme',
                            subtitle: '',
                            value: ThemeMode.light,
                          ),
                          MRadioListItemData<ThemeMode>(
                            title: 'Dark theme',
                            subtitle: '',
                            value: ThemeMode.dark,
                          ),
                        ],
                        groupValue: settings.themeMode,
                        onChanged: (mode) {
                          settings.setThemeMode(mode);
                        },
                      ),
                      MListHeader(title: 'Theme Style'),
                      MRadioListView(
                        items: [
                          MRadioListItemData<ThemeStyle>(
                            title: 'Material style',
                            subtitle: '',
                            value: ThemeStyle.material,
                          ),
                          MRadioListItemData<ThemeStyle>(
                            title: 'Florid style',
                            subtitle: '',
                            suffix: Container(
                              margin: const EdgeInsets.only(right: 8.0),
                              child: Material(
                                color: Theme.of(context).colorScheme.secondary,
                                borderRadius: BorderRadius.circular(99.0),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                    vertical: 2.0,
                                  ),
                                  child: Text(
                                    'Beta',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            value: ThemeStyle.florid,
                          ),
                        ],
                        groupValue: settings.themeStyle,
                        onChanged: (style) {
                          settings.setThemeStyle(style);
                        },
                      ),
                      MListView(
                        items: [
                          MListItemData(
                            leading: Icon(Symbols.feedback),
                            title: 'Fedback on Florid theme',
                            subtitle:
                                'Help improve the Florid theme by providing feedback',
                            onTap: () {
                              launchUrl(
                                Uri.parse(
                                  'https://github.com/Nandanrmenon/florid/discussions/5',
                                ),
                              );
                            },
                            suffix: Icon(Symbols.open_in_new),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    spacing: 4,
                    children: [
                      MListHeader(title: 'General Settings'),
                      MListView(
                        items: [
                          MListItemData(
                            leading: Icon(Symbols.language),
                            title: 'App content language',
                            onTap: () => _showLanguageDialog(context, settings),
                            subtitle: SettingsProvider.getLocaleDisplayName(
                              settings.locale,
                            ),
                            suffix: Icon(Symbols.chevron_right),
                          ),
                          MListItemData(
                            leading: Icon(Symbols.cloud),
                            title: 'Manage repositories',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const RepositoriesScreen(),
                                ),
                              );
                            },
                            subtitle: 'Add or remove F-Droid repositories',
                            suffix: Icon(Symbols.chevron_right),
                          ),
                        ],
                      ),
                    ],
                  ),

                  Column(
                    spacing: 4,
                    children: [
                      MListHeader(title: 'Web Store Sync'),
                      MListView(
                        items: [
                          MListItemData(
                            leading: Icon(Symbols.devices),
                            title: 'Pair with Web Store',
                            subtitle: settings.webSyncEnabled
                                ? 'Device paired'
                                : 'Not paired',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const DevicePairingScreen(),
                                ),
                              );
                            },
                            suffix: settings.webSyncEnabled
                                ? Icon(
                                    Symbols.check_circle,
                                    color: Colors.green,
                                  )
                                : Icon(Symbols.chevron_right),
                          ),
                          if (settings.webSyncEnabled)
                            MListItemData(
                              leading: Icon(Symbols.install_mobile),
                              title: 'Remote Installs',
                              subtitle:
                                  'View and manage remote install requests',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const RemoteInstallScreen(),
                                  ),
                                );
                              },
                              suffix: Icon(Symbols.chevron_right),
                            ),
                        ],
                      ),
                    ],
                  ),

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
                            onTap: () {
                              _clearRepoCache(context);
                            },
                            subtitle:
                                'Refresh app list and metadata on next load',
                          ),
                          MListItemData(
                            leading: Icon(Symbols.delete_sweep),
                            title: 'Clear APK downloads',
                            onTap: () {
                              _clearRepoCache(context);
                            },
                            subtitle:
                                'Remove downloaded installer files from storage',
                          ),
                          MListItemData(
                            leading: Icon(Symbols.image_not_supported),
                            title: 'Clear image cache',
                            onTap: () {
                              _clearRepoCache(context);
                            },
                            subtitle: 'Remove cached icons and screenshots',
                          ),
                        ],
                      ),
                    ],
                  ),

                  Column(
                    spacing: 4,
                    children: [
                      MListHeader(title: 'About'),
                      MListView(
                        items: [
                          MListItemData(
                            leading: Icon(Symbols.info),
                            title: 'Version',
                            subtitle: _appVersion.isEmpty
                                ? 'Loading…'
                                : _appVersion,
                            onTap: () {},
                          ),
                          MListItemData(
                            leading: Icon(Symbols.code_rounded),
                            title: 'Source code',
                            onTap: () async {
                              final url = Uri.parse(
                                'https://github.com/Nandanrmenon/florid',
                              );
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              }
                            },
                          ),
                          MListItemData(
                            leading: Icon(Symbols.bug_report_rounded),
                            title: 'Report an issue',
                            onTap: () async {
                              final url = Uri.parse(
                                'https://github.com/Nandanrmenon/florid/issues/new?template=bug_report.md',
                              );
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              }
                            },
                          ),
                          MListItemData(
                            leading: Icon(Symbols.share),
                            title: 'Share Florid',
                            onTap: () {
                              SharePlus.instance.share(
                                ShareParams(
                                  title: 'Check out Florid!',
                                  text:
                                      'A modern F-Droid client! https://github.com/Nandanrmenon/florid',
                                ),
                              );
                            },
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
