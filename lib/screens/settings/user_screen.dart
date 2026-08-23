import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:florid/constants.dart';
import 'package:florid/l10n/app_localizations.dart';
import 'package:florid/models/fdroid_app.dart';
import 'package:florid/providers/app_provider.dart';
import 'package:florid/providers/repositories_provider.dart';
import 'package:florid/providers/settings_provider.dart';
import 'package:florid/screens/app_details/app_details_screen.dart';
import 'package:florid/screens/settings/app_management_screen.dart';
import 'package:florid/screens/settings/appearance_screen.dart';
import 'package:florid/screens/settings/parental_control_screen.dart';
import 'package:florid/screens/settings/repositories_screen.dart';
import 'package:florid/screens/settings/troubleshooting_screen.dart';
import 'package:florid/services/fdroid_api_service.dart';
import 'package:florid/widgets/app_list_item.dart';
import 'package:florid/widgets/list_icon.dart';
import 'package:florid/widgets/m_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/svg.dart';
import 'package:iconify_flutter/icons/bxl.dart';
import 'package:iconify_flutter/icons/simple_icons.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  bool _isCollapsed = false;
  late final ScrollController _scrollController;
  final double expandedBarHeight = 200;
  final double collapsedBarHeight = kMinInteractiveDimension;

  Future<void> _editUserName(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) async {
    final controller = TextEditingController(text: settingsProvider.userName);

    final result = await showDialog<String>(
      context: context,

      builder: (dialogContext) => SimpleDialog(
        contentPadding: EdgeInsets.all(24),
        title: Text(AppLocalizations.of(context)!.your_name),

        children: [
          TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.enter_your_name,
            ),
            onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
          ),
          const SizedBox(height: 16),
          Column(
            spacing: 8.0,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(controller.text),
                  child: Text(AppLocalizations.of(context)!.save),
                ),
              ),
              SizedBox(
                height: 48,
                child: TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(AppLocalizations.of(context)!.close),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (result == null) return;
    await settingsProvider.setUserName(result.trim());
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final localizations = AppLocalizations.of(context)!;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        final newCollapsed =
            notification.metrics.pixels >
            (expandedBarHeight - collapsedBarHeight);
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
        extendBody: true,
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              pinned: true,
              centerTitle: true,
              expandedHeight: expandedBarHeight,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: GestureDetector(
                      onTap: () => _editUserName(context, settingsProvider),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        spacing: 4.0,
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 48,
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.onPrimary,
                                child: settingsProvider.userName.isNotEmpty
                                    ? Text(
                                        settingsProvider.userName
                                            .trim()
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 48,
                                          fontVariations: [
                                            FontVariation('wght', 700),
                                            FontVariation('ROND', 100),
                                            FontVariation('wdth', 100),
                                          ],
                                        ),
                                      )
                                    : const Icon(Symbols.person, size: 48),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Material(
                                  elevation: 2,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                  shape: const CircleBorder(),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: const Icon(Symbols.edit, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            settingsProvider.userName.isNotEmpty
                                ? settingsProvider.userName
                                : localizations.user,
                            style: Theme.of(context).textTheme.headlineMedium!
                                .copyWith(
                                  fontVariations: [
                                    FontVariation('wght', 700),
                                    FontVariation('ROND', 100),
                                    FontVariation('wdth', 100),
                                  ],
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              title: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isCollapsed ? 1 : 0,
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      child: settingsProvider.userName.isNotEmpty
                          ? Text(
                              settingsProvider.userName
                                  .trim()
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: TextStyle(
                                fontVariations: [
                                  FontVariation('wght', 700),
                                  FontVariation('ROND', 100),
                                  FontVariation('wdth', 100),
                                ],
                              ),
                            )
                          : const Icon(Symbols.person),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        settingsProvider.userName.isNotEmpty
                            ? settingsProvider.userName
                            : localizations.user,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: _UserSettingsContent()),
          ],
        ),
      ),
    );
  }
}

enum _FavoritesImportAction { merge, replace }

class _UserSettingsContent extends StatefulWidget {
  const _UserSettingsContent();

  @override
  State<_UserSettingsContent> createState() => _UserSettingsContentState();
}

class _UserSettingsContentState extends State<_UserSettingsContent> {
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

  String _localeLabel(AppLocalizations l10n, String locale) {
    if (locale == SettingsProvider.systemLocale) {
      return l10n.system_default_language;
    }
    return SettingsProvider.getLocaleDisplayName(locale);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final l10n = AppLocalizations.of(context)!;
        return Column(
          children: <Widget>[
            const SizedBox(height: 16),

            Column(
              spacing: 4,
              children: [
                MListHeader(
                  title: l10n.general_settings,
                  icon: Symbols.mobile,
                ),
                MListView(
                  items: [
                    MListItemData(
                      leading: ListIcon(iconData: SolarIconsBold.heart),
                      title: l10n.favourites,
                      subtitle: l10n.view_favourite_apps,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const _FavoriteAppsScreen(),
                          ),
                        );
                      },
                      suffix: const Icon(Symbols.chevron_right),
                    ),
                    MListItemData(
                      leading: ListIcon(iconData: SolarIconsBold.palette),
                      title: l10n.appearance,
                      subtitle: l10n.theme_mode_and_style,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AppearanceScreen(),
                          ),
                        );
                      },
                      suffix: const Icon(Symbols.chevron_right),
                    ),
                    MListItemData(
                      leading: ListIcon(iconData: SolarIconsBold.shield),
                      title: l10n.parental_control,
                      subtitle: l10n.parental_control_subtitle,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ParentalControlScreen(),
                          ),
                        );
                      },
                      suffix: const Icon(Symbols.chevron_right),
                    ),
                    MListItemData(
                      leading: ListIcon(iconData: SolarIconsBold.globus),
                      title: l10n.app_content_language,
                      onTap: () => _showLanguageDialog(context, settings),
                      subtitle: _localeLabel(l10n, settings.locale),
                      suffix: const Icon(Symbols.chevron_right),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              spacing: 4,
              children: [
                MListHeader(
                  title: l10n.repositories_and_management,
                  icon: Symbols.settings,
                ),
                MListView(
                  items: [
                    MListItemData(
                      leading: ListIcon(iconData: SolarIconsBold.cloud),
                      title: l10n.manage_repositories,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RepositoriesScreen(),
                          ),
                        );
                      },
                      subtitle: l10n.add_or_remove_fdroid_repositories,
                      suffix: const Icon(Symbols.chevron_right),
                    ),
                    MListItemData(
                      leading: ListIcon(
                        iconData: SolarIconsBold.settingsMinimalistic,
                      ),
                      title: l10n.app_management,
                      subtitle: l10n.manage_installs_and_updates,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AppManagementScreen(),
                          ),
                        );
                      },
                      suffix: const Icon(Symbols.chevron_right),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Padding(
                  padding: const EdgeInsets.only(left: 8.0, right: 8),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 12.0,
                        children: [
                          Text(
                            l10n.keep_android_open,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(l10n.keep_android_open_message),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              FilledButton.tonalIcon(
                                onPressed: () {
                                  canLaunchUrl(
                                    Uri.parse('https://keepandroidopen.org/'),
                                  ).then((canLaunch) {
                                    if (canLaunch) {
                                      launchUrl(
                                        Uri.parse(
                                          'https://keepandroidopen.org/',
                                        ),
                                      );
                                    }
                                  });
                                },
                                label: Text(
                                  AppLocalizations.of(context)!.learn_more,
                                ),
                                icon: const Icon(Symbols.open_in_new),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .animate(delay: const Duration(milliseconds: 100))
                .fadeIn(duration: 300.ms),
            const SizedBox(height: 16),
            Column(
              spacing: 4.0,
              children: [
                MListHeader(
                  title: l10n.miscellaneous,
                  icon: Symbols.more_horiz,
                ),
                MListView(
                  items: [
                    MListItemData(
                      leading: ListIcon(iconData: SolarIconsBold.sledgehammer),
                      title: l10n.troubleshooting,
                      subtitle: l10n.storage_cache_and_downloads,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TroubleshootingScreen(),
                          ),
                        );
                      },
                      suffix: const Icon(Symbols.chevron_right),
                    ),
                  ],
                ),
                MListView(
                  items: [
                    MListItemData(
                      leading: ListIcon(iconData: SolarIconsBold.infoSquare),
                      title: l10n.version,
                      subtitle: _appVersion.isEmpty
                          ? l10n.loading
                          : _appVersion,
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: kAppName,
                          applicationVersion: _appVersion,
                          children: [Text(l10n.a_modern_fdroid_client)],
                          applicationIcon: SvgPicture.asset(
                            kAppLogoSvg,
                            key: const ValueKey('app_logo'),
                            height: 56,
                            colorFilter: ColorFilter.mode(
                              Theme.of(context).colorScheme.primary,
                              BlendMode.srcIn,
                            ),
                          ),
                        );
                      },
                    ),
                    MListItemData(
                      leading: SocialListIcon(icon: Bxl.git),
                      title: l10n.source_code,
                      subtitle: l10n.view_florid_source_github,
                      suffix: Icon(SolarIconsOutline.squareBottomUp),
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
                      leading: SocialListIcon(icon: Bxl.telegram),
                      title: l10n.telegram,
                      subtitle: l10n.join_community_telegram,
                      suffix: Icon(SolarIconsOutline.squareBottomUp),
                      onTap: () async {
                        final url = Uri.parse('https://t.me/florid_app');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                    ),
                    MListItemData(
                      leading: SocialListIcon(icon: SimpleIcons.matrix),
                      title: l10n.matrix,
                      subtitle: l10n.join_community_matrix,
                      suffix: Icon(SolarIconsOutline.squareBottomUp),
                      onTap: () async {
                        final url = Uri.parse(
                          'https://matrix.to/#/#florid:matrix.org',
                        );
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                    ),
                    MListItemData(
                      leading: ListIcon(
                        iconData: SolarIconsBold.roundedMagnifierBug,
                      ),
                      title: l10n.report_an_issue,
                      subtitle: l10n.found_a_bug,
                      suffix: Icon(SolarIconsOutline.squareBottomUp),
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
                      leading: ListIcon(iconData: SolarIconsBold.heartShine),
                      title: l10n.donate,
                      subtitle: l10n.support_continued_development,
                      suffix: Icon(SolarIconsOutline.squareBottomUp),
                      onTap: () async {
                        final url = Uri.parse('https://ko-fi.com/nandanrmenon');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                    ),
                    MListItemData(
                      leading: ListIcon(iconData: SolarIconsBold.share),
                      title: l10n.share_florid,
                      subtitle: l10n.let_nerdy_friends_know,
                      onTap: () {
                        SharePlus.instance.share(
                          ShareParams(
                            title: l10n.check_out_florid,
                            text: l10n.share_florid_text,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Future<void> _showLanguageDialog(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    final parentContext = context;
    final navigator = Navigator.of(parentContext, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(parentContext);
    final apiService = parentContext.read<FDroidApiService>();
    final appProvider = parentContext.read<AppProvider>();
    final repositoriesProvider = parentContext.read<RepositoriesProvider>();

    final l10n = AppLocalizations.of(parentContext)!;
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.select_language),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: SettingsProvider.availableLocales.length,
            itemBuilder: (_, index) {
              final locale = SettingsProvider.availableLocales[index];
              final displayName = _localeLabel(l10n, locale);

              return RadioListTile<String>(
                title: Text(displayName),
                subtitle: Text(locale),
                value: locale,
                groupValue: settings.locale,
                onChanged: (value) async {
                  if (value != null) {
                    await settings.setLocale(value);
                    if (!mounted) return;

                    apiService.setLocale(settings.effectiveLocale);

                    await appProvider.refreshAll(
                      repositoriesProvider: repositoriesProvider,
                      forceRepositoryRefresh: true,
                    );

                    if (!mounted) return;
                    if (navigator.canPop()) {
                      navigator.pop();
                    }

                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.language_changed_to(_localeLabel(l10n, value)),
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
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }
}

class _FavoriteAppsScreen extends StatefulWidget {
  const _FavoriteAppsScreen();

  @override
  State<_FavoriteAppsScreen> createState() => _FavoriteAppsScreenState();
}

class _FavoriteAppsScreenState extends State<_FavoriteAppsScreen> {
  Future<void> _exportFavorites(BuildContext context) async {
    final appProvider = context.read<AppProvider>();
    final favorites = appProvider.favoritePackages.toList()..sort();

    if (favorites.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.no_favourites_to_export),
        ),
      );
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
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.unable_to_access_downloads,
          ),
        ),
      );
      return;
    }

    final exportFile = File(p.join(downloadsDir.path, fileName));
    await exportFile.writeAsString(payload);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(
            context,
          )!.saved_to_downloads('${downloadsDir.path}/$fileName'),
        ),
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
    final picked = await FilePicker.pickFiles(
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
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.no_favourites_found_to_import,
          ),
        ),
      );
      return;
    }

    final result = await showDialog<_FavoritesImportAction>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Symbols.star),
        title: Text(AppLocalizations.of(context)!.import_favourites),
        content: Text(
          AppLocalizations.of(
            context,
          )!.found_favourites_in_file(parsed.length, file.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.close),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_FavoritesImportAction.merge),
            child: Text(AppLocalizations.of(context)!.merge),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(_FavoritesImportAction.replace),
            child: Text(AppLocalizations.of(context)!.replace),
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
          AppLocalizations.of(context)!.imported_favourites_count(parsed.length),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      () async {
        final appProvider = context.read<AppProvider>();
        // Use cached/database repository first to avoid unnecessary network fetches.
        await appProvider.fetchRepository();

        // If favorites are unresolved locally, fall back to fetching enabled repos.
        final unresolvedFavorites =
            appProvider.favoritePackages.isNotEmpty &&
            appProvider.getFavoriteApps().isEmpty;

        if (unresolvedFavorites) {
          final repositoriesProvider = context.read<RepositoriesProvider>();
          if (repositoriesProvider.repositories.isEmpty &&
              !repositoriesProvider.isLoading) {
            await repositoriesProvider.loadRepositories();
          }

          final enabledUrls = repositoriesProvider.enabledRepositories
              .map((repo) => repo.url)
              .toList();
          if (enabledUrls.isNotEmpty) {
            await appProvider.fetchRepositoriesFromUrls(enabledUrls);
          }
        }
      }();
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        final repositoryLoaded = appProvider.repository != null;
        final repositoryState = appProvider.repositoryState;
        final repositoryError = appProvider.repositoryError;
        final favoriteApps = repositoryLoaded
            ? appProvider.getFavoriteApps()
            : <FDroidApp>[];

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
                title: Text(AppLocalizations.of(context)!.favourites),
                actions: [
                  if (favoriteApps.isNotEmpty)
                    PopupMenuButton(
                      icon: Icon(SolarIconsBold.menuDots),
                      itemBuilder: (context) {
                        return [
                          PopupMenuItem(
                            value: 'import',
                            child: Row(
                              spacing: 8.0,
                              children: [
                                const Icon(Symbols.file_upload),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.import_favourites,
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'export',
                            child: Row(
                              spacing: 8.0,
                              children: [
                                const Icon(Symbols.file_download),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.export_favourites,
                                ),
                              ],
                            ),
                          ),
                        ];
                      },
                      onSelected: (value) {
                        if (value == 'import') {
                          _importFavorites(context);
                        } else if (value == 'export') {
                          _exportFavorites(context);
                        }
                      },
                    ),
                ],
              ),
              if (repositoryState == LoadingState.loading && !repositoryLoaded)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (!repositoryLoaded &&
                  repositoryState == LoadingState.error)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 12,
                        children: [
                          const Icon(Symbols.cloud_off, size: 48),
                          Text(localizations.unable_to_load_repository),
                          if (repositoryError != null)
                            Text(
                              repositoryError.replaceAll('Exception: ', ''),
                              textAlign: TextAlign.center,
                            ),
                          FilledButton.icon(
                            onPressed: () => appProvider.fetchRepository(),
                            icon: const Icon(Symbols.refresh),
                            label: Text(localizations.retry),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (favoriteApps.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Symbols.favorite_rounded,
                          fill: 1,
                          size: 128,
                          color: Colors.redAccent,
                        ),
                        Text(
                          localizations.no_favourites_yet,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () {
                            _importFavorites(context);
                          },
                          icon: const Icon(Symbols.file_upload),
                          label: Text(localizations.import_favourites),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                  sliver: SliverList.builder(
                    itemCount: favoriteApps.length,
                    itemBuilder: (context, index) {
                      final app = favoriteApps[index];
                      return Container(
                        key: Key(app.packageName),
                        child: AppListItem(
                          app: app,
                          showInstallStatus: true,
                          showFavorite: true,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    AppDetailsScreen(app: app),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
