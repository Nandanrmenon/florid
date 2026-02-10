import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:florid/l10n/app_localizations.dart';
import 'package:florid/widgets/m_list.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/app_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/appearance_screen.dart';
import '../screens/repositories_screen.dart';
import '../screens/troubleshooting_screen.dart';
import '../screens/update_settings_screen.dart';
import '../services/fdroid_api_service.dart';
import '../services/update_check_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

enum _FavoritesImportAction { merge, replace }

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

  Future<void> _exportFavorites(BuildContext context) async {
    final appProvider = context.read<AppProvider>();
    final favorites = appProvider.favoritePackages.toList()..sort();

    if (favorites.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No favourites to export')));
      return;
    }

    final payload = jsonEncode({'favorites': favorites});
    final fileName =
        'florid-favourites-${DateTime.now().millisecondsSinceEpoch}.json';

    Directory? downloadsDir;
    if (Platform.isAndroid) {
      downloadsDir = Directory('/storage/emulated/0/Download');
    } else {
      downloadsDir = await getDownloadsDirectory();
    }

    if (downloadsDir == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to access Downloads folder')),
      );
      return;
    }

    final exportFile = File(p.join(downloadsDir.path, fileName));
    await exportFile.writeAsString(payload);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved to Downloads: ${downloadsDir.path}/$fileName'),
      ),
    );
  }

  Set<String> _parseFavoritesPayload(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return <String>{};

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is List) {
        return decoded.whereType<String>().toSet();
      }
      if (decoded is Map && decoded['favorites'] is List) {
        final list = decoded['favorites'] as List;
        return list.whereType<String>().toSet();
      }
    } catch (_) {
      // Fallback to parsing as a comma/whitespace-separated list.
    }

    return trimmed
        .split(RegExp(r'[\s,]+'))
        .where((item) => item.isNotEmpty)
        .toSet();
  }

  Future<void> _importFavorites(BuildContext context) async {
    final appProvider = context.read<AppProvider>();
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;

    final file = picked.files.first;
    final raw = file.bytes != null
        ? utf8.decode(file.bytes!)
        : file.path != null
        ? await File(file.path!).readAsString()
        : '';

    final parsed = _parseFavoritesPayload(raw);
    if (parsed.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No favourites found to import')),
      );
      return;
    }

    final result = await showDialog<_FavoritesImportAction>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Symbols.star),
        title: const Text('Import favourites'),
        content: Text(
          'Found ${parsed.length} favourite${parsed.length == 1 ? '' : 's'} in ${file.name}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_FavoritesImportAction.merge),
            child: const Text('Merge'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(_FavoritesImportAction.replace),
            child: const Text('Replace'),
          ),
        ],
      ),
    );

    if (result == null) return;

    await appProvider.setFavorites(
      parsed,
      merge: result == _FavoritesImportAction.merge,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Imported ${parsed.length} favourite${parsed.length == 1 ? '' : 's'}',
        ),
      ),
    );
  }

  String _updateNetworkPolicyLabel(UpdateNetworkPolicy policy) {
    switch (policy) {
      case UpdateNetworkPolicy.wifiOnly:
        return 'Wi-Fi only';
      case UpdateNetworkPolicy.wifiAndCharging:
        return 'Wi-Fi + charging';
      case UpdateNetworkPolicy.any:
      default:
        return 'Mobile data or Wi-Fi';
    }
  }

  Future<void> _showUpdateNetworkPolicyDialog(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update network'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: UpdateNetworkPolicy.values
              .map(
                (policy) => RadioListTile<UpdateNetworkPolicy>(
                  value: policy,
                  groupValue: settings.updateNetworkPolicy,
                  title: Text(_updateNetworkPolicyLabel(policy)),
                  onChanged: (value) async {
                    if (value == null) return;
                    await settings.setUpdateNetworkPolicy(value);
                    await UpdateCheckService.scheduleFromPrefs();
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
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _updateIntervalLabel(int hours) {
    switch (hours) {
      case 1:
        return 'Every 1 hour';
      case 2:
        return 'Every 2 hours';
      case 3:
        return 'Every 3 hours';
      case 6:
        return 'Every 6 hours';
      case 12:
        return 'Every 12 hours';
      case 24:
        return 'Daily';
      default:
        return 'Every $hours hours';
    }
  }

  Future<void> _showUpdateIntervalDialog(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    const intervals = [1, 2, 3, 6, 12, 24];
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update interval'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: intervals
              .map(
                (hours) => RadioListTile<int>(
                  value: hours,
                  groupValue: settings.updateIntervalHours,
                  title: Text(_updateIntervalLabel(hours)),
                  onChanged: (value) async {
                    if (value == null) return;
                    await settings.setUpdateIntervalHours(value);
                    await UpdateCheckService.scheduleFromPrefs();
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
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Scaffold(
          appBar: AppBar(title: Text(AppLocalizations.of(context)!.settings)),
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
                      MListHeader(
                        title: 'General Settings',
                        icon: Symbols.settings,
                      ),
                      MListView(
                        items: [
                          MListItemData(
                            leading: Icon(Symbols.palette),
                            title: 'Appearance',
                            subtitle: 'Theme mode and style',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AppearanceScreen(),
                                ),
                              );
                            },
                            suffix: Icon(Symbols.chevron_right),
                          ),
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
                          MListItemData(
                            leading: Icon(Symbols.update),
                            title: 'Update settings',
                            subtitle: 'Manage background updates',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const UpdateSettingsScreen(),
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
                    spacing: 4.0,
                    children: [
                      MListHeader(
                        title: 'Miscellaneous',
                        icon: Symbols.more_horiz,
                      ),
                      MListView(
                        items: [
                          MListItemData(
                            leading: Icon(Symbols.file_upload),
                            title: 'Export favourites',
                            subtitle: 'Save a JSON file to Downloads',
                            onTap: () => _exportFavorites(context),
                          ),
                          MListItemData(
                            leading: Icon(Symbols.file_download),
                            title: 'Import favourites',
                            subtitle: 'Import favourites from a JSON file',
                            onTap: () => _importFavorites(context),
                          ),
                        ],
                      ),
                      MListView(
                        items: [
                          MListItemData(
                            leading: Icon(Symbols.build),
                            title: 'Troubleshooting',
                            subtitle: 'Storage, cache, and downloads',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const TroubleshootingScreen(),
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
                      MListHeader(title: 'About', icon: Symbols.android),
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
                            subtitle: 'View the Florid source code on GitHub',
                            suffix: Icon(Symbols.open_in_new),
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
                            subtitle: 'Found a bug? Let us know!',
                            suffix: Icon(Symbols.open_in_new),
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
                            leading: Icon(Symbols.volunteer_activism),
                            title: 'Donate',
                            subtitle: 'Support continued development of Florid',
                            suffix: Icon(Symbols.open_in_new),
                            onTap: () async {
                              final url = Uri.parse(
                                'https://ko-fi.com/nandanrmenon',
                              );
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              }
                            },
                          ),
                          MListItemData(
                            leading: Icon(Symbols.share),
                            title: 'Share Florid',
                            subtitle:
                                'Let your nerdy friends know about Florid!',
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
