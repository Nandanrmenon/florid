import 'dart:convert';

import 'package:florid/l10n/app_localizations.dart';
import 'package:florid/widgets/list_icon.dart';
import 'package:florid/widgets/onboarding_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../providers/repositories_provider.dart';
import '../providers/settings_provider.dart';
import '../services/fdroid_api_service.dart';
import '../widgets/m_list.dart';
import 'florid_app.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final Map<String, bool> _selectedRepos = {};
  final bool _isFinishing = false;
  int _currentPage = 0;
  String _progressStatus = '';
  double _progressValue = 0.0;
  List<Map<String, dynamic>> _presets = [];
  bool _notificationsGranted = false;
  bool _installPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _progressStatus = 'Initializing...';
    // Ensure repositories are loaded so duplicate checks work
    Future.microtask(() {
      final repos = context.read<RepositoriesProvider>();
      repos.loadRepositories();
    });
    _loadPresets();
  }

  Future<void> _loadPresets() async {
    try {
      final jsonString = await DefaultAssetBundle.of(
        context,
      ).loadString('assets/repositories.json');
      final jsonData = jsonDecode(jsonString);
      final repos = (jsonData['repositories'] as List)
          .map(
            (e) => {
              'name': e['name'] as String,
              'url': e['url'] as String,
              'description': e['description'] as String? ?? '',
              'default': e['default'] as bool? ?? false,
            },
          )
          .toList();

      setState(() {
        _presets = repos;
        // Apply default selections from JSON
        for (var repo in repos) {
          _selectedRepos[repo['url'] as String] = repo['default'] == true;
        }
      });
    } catch (e) {
      debugPrint('Error loading presets: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _startSetup() {
    if (!_installPermissionGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('App installation permission is required to continue.'),
        ),
      );
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      return;
    }

    // Navigate to progress screen
    _pageController.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.decelerate,
    );
    // Start the actual setup
    _performSetup();
  }

  Future<void> _requestNotifications() async {
    final status = await Permission.notification.request();
    setState(() {
      _notificationsGranted = status.isGranted;
    });
  }

  Future<void> _requestInstallPermission() async {
    final status = await Permission.requestInstallPackages.request();
    setState(() {
      _installPermissionGranted = status.isGranted;
    });
  }

  Future<void> _performSetup() async {
    try {
      final settings = context.read<SettingsProvider>();
      final repos = context.read<RepositoriesProvider>();
      final appProvider = context.read<AppProvider>();

      // Step 1: Load repositories
      setState(() {
        _progressStatus = AppLocalizations.of(
          context,
        )!.loading_repository_configuration;
        _progressValue = 0.1;
      });
      await repos.loadRepositories();
      await Future.delayed(const Duration(milliseconds: 300));

      // Step 2: Add selected repositories
      if (_selectedRepos.values.any((selected) => selected)) {
        setState(() {
          _progressStatus = AppLocalizations.of(
            context,
          )!.adding_selected_repositories;
          _progressValue = 0.2;
        });

        for (var preset in _presets) {
          if (_selectedRepos[preset['url']] == true) {
            final hasRepo = repos.repositories.any(
              (repo) => repo.url == preset['url'],
            );
            if (!hasRepo) {
              await repos.addRepository(preset['name']!, preset['url']!);
            }
          }
        }
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Step 3: Fetch official F-Droid repository
      setState(() {
        _progressStatus = AppLocalizations.of(
          context,
        )!.fetching_fdroid_repository_index;
        _progressValue = 0.3;
      });
      await appProvider.fetchRepository();

      // Step 4: Wait for database import to complete
      setState(() {
        _progressStatus = AppLocalizations.of(
          context,
        )!.importing_apps_to_database;
        _progressValue = 0.4;
      });

      // Poll database until populated (with timeout)
      final startTime = DateTime.now();
      const maxWait = Duration(seconds: 30);
      final apiService = context.read<FDroidApiService>();
      while (DateTime.now().difference(startTime) < maxWait) {
        try {
          // Check if database has any apps (indicates import completed)
          final testApps = await apiService.fetchApps(limit: 1);
          if (testApps.isNotEmpty) {
            // Database is populated
            break;
          }
        } catch (e) {
          // Still importing or error, continue waiting
        }

        // Update progress based on elapsed time
        final elapsed = DateTime.now().difference(startTime);
        final progress = 0.4 + (elapsed.inSeconds / maxWait.inSeconds * 0.3);
        setState(() {
          _progressValue = progress.clamp(0.4, 0.7);
          _progressStatus = AppLocalizations.of(
            context,
          )!.importing_apps_to_database_seconds(elapsed.inSeconds);
        });

        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Step 5: Fetch custom repos if enabled (after main DB is ready)
      if (_selectedRepos.values.any((selected) => selected)) {
        setState(() {
          _progressStatus = AppLocalizations.of(
            context,
          )!.loading_custom_repositories;
          _progressValue = 0.75;
        });
        await repos.loadRepositories();
        final customUrls = repos.enabledRepositories.map((r) => r.url).toList();
        if (customUrls.isNotEmpty) {
          await appProvider.fetchRepositoriesFromUrls(customUrls);
        }
      }

      // Step 6: Fetch initial data
      setState(() {
        _progressStatus = AppLocalizations.of(context)!.loading_latest_apps;
        _progressValue = 0.85;
      });
      await appProvider.fetchLatestApps(repositoriesProvider: repos, limit: 50);

      setState(() {
        _progressStatus = AppLocalizations.of(context)!.loading_categories;
        _progressValue = 0.95;
      });
      await appProvider.fetchCategories();

      // Step 7: Complete
      setState(() {
        _progressStatus = AppLocalizations.of(context)!.setup_complete;
        _progressValue = 1.0;
      });
      await Future.delayed(const Duration(milliseconds: 500));

      await settings.setOnboardingComplete(true);

      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const FloridApp()));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _progressStatus =
            '${AppLocalizations.of(context)!.error}: ${e.toString()}';
      });
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.setup_failed}: $e'),
          action: SnackBarAction(
            label: AppLocalizations.of(context)!.retry,
            onPressed: _performSetup,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: _currentPage > 0
            ? IconButton(
                onPressed: _isFinishing || _currentPage == 0
                    ? null
                    : () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                        );
                      },
                icon: Icon(Symbols.arrow_back),
              ).animate().fadeIn(duration: 500.ms)
            : null,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _IntroStep(colorScheme: colorScheme),
                  _PermissionsStep(
                    notificationsGranted: _notificationsGranted,
                    installPermissionGranted: _installPermissionGranted,
                    onRequestNotifications: _requestNotifications,
                    onRequestInstallPermission: _requestInstallPermission,
                  ),
                  _ReposStep(
                    selectedRepos: _selectedRepos,
                    presets: _presets,
                    onToggleRepo: (url, selected) {
                      setState(() {
                        _selectedRepos[url] = selected;
                      });
                    },
                  ),
                  _ProgressStep(
                    colorScheme: colorScheme,
                    status: _progressStatus,
                    progress: _progressValue,
                  ),
                ],
              ),
            ),
            if (_currentPage < 3)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  height: 48,
                  child: OnboardingPrimaryButton(
                    currentPage: _currentPage,
                    isFinishing: _isFinishing,
                    canProceed: _currentPage == 1
                        ? _installPermissionGranted
                        : _currentPage == 2
                        ? _selectedRepos.values.any((selected) => selected)
                        : true,
                    onNext: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                    },
                    onStartSetup: _startSetup,
                  ),
                ).animate().fadeIn(duration: 500.ms),
              ),
          ],
        ),
      ),
    );
  }
}

class _IntroStep extends StatelessWidget {
  const _IntroStep({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            elevation: 2,
            child: Image.asset('assets/Florid.png', height: 64),
          ).animate().fadeIn(duration: 500.ms),
          const SizedBox(height: 16),
          Text(
            localizations.welcome_to,
            style: TextStyle(
              fontSize: 24,
              fontVariations: [
                FontVariation('wght', 400),
                FontVariation('ROND', 100),
              ],
              color: colorScheme.onSurfaceVariant,
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
          Text(
            'Florid',
            style: TextStyle(
              fontSize: 42,
              fontVariations: [
                FontVariation('wght', 700),
                FontVariation('ROND', 100),
                FontVariation('wdth', 125),
              ],
              color: colorScheme.primary,
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
          const SizedBox(height: 12),
          Text(
            localizations.onboarding_intro_subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 300.ms),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _Pill(
                text: localizations.curated_open_source_apps,
              ).animate().fadeIn(duration: 500.ms, delay: 500.ms),
              _Pill(
                text: localizations.safe_downloads,
              ).animate().fadeIn(duration: 500.ms, delay: 700.ms),
              _Pill(
                text: localizations.updates_and_notifications,
              ).animate().fadeIn(duration: 500.ms, delay: 900.ms),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReposStep extends StatelessWidget {
  const _ReposStep({
    required this.selectedRepos,
    required this.presets,
    required this.onToggleRepo,
  });

  final Map<String, bool> selectedRepos;
  final List<Map<String, dynamic>> presets;
  final Function(String url, bool selected) onToggleRepo;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 24.0,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 24.0, right: 16.0),
          child: Column(
            spacing: 16.0,
            children: [
              Row(
                spacing: 8,
                children: [
                  CircleAvatar(child: Icon(Symbols.dns)),
                  Text(
                    localizations.add_extra_repositories,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ).animate().fadeIn(duration: 500.ms),
              Text(
                localizations.repos_step_description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
            ],
          ),
        ),
        Column(
          spacing: 4.0,
          children: [
            if (presets.isNotEmpty)
              MListHeader(
                title: localizations.available_repositories,
              ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
            if (presets.isEmpty)
              Center(child: CircularProgressIndicator())
            else
              MCheckboxListViewBuilder(
                itemCount: presets.length,
                itemBuilder: (index) {
                  final preset = presets[index];
                  final url = preset['url'] as String;
                  return MCheckboxListItemData(
                    title: preset['name'],
                    subtitle: preset['description'],
                    value: selectedRepos[url] ?? false,
                  );
                },
                onChanged: (index, value) {
                  final url = presets[index]['url'] as String;
                  onToggleRepo(url, value);
                },
              ).animate().fadeIn(duration: 500.ms, delay: 600.ms),
          ],
        ),
        Text(
          localizations.manage_repositories_anytime,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ).animate().fadeIn(duration: 500.ms, delay: 600.ms),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _PermissionsStep extends StatelessWidget {
  const _PermissionsStep({
    required this.notificationsGranted,
    required this.installPermissionGranted,
    required this.onRequestNotifications,
    required this.onRequestInstallPermission,
  });

  final bool notificationsGranted;
  final bool installPermissionGranted;
  final VoidCallback onRequestNotifications;
  final VoidCallback onRequestInstallPermission;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          spacing: 16.0,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                spacing: 16.0,
                children: [
                  Row(
                    spacing: 8,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(child: Icon(Symbols.notifications_active)),
                      Text(
                        localizations.request_permissions,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ).animate().fadeIn(duration: 500.ms),
                  Text(
                    localizations.permissions_step_description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
                ],
              ),
            ),
            // Column(
            //   spacing: 12,
            //   children: [
            //     _PermissionCard(
            //       icon: Symbols.notifications,
            //       title: localizations.notifications,
            //       description: localizations.get_notified_updates,
            //       isGranted: notificationsGranted,
            //       onRequest: onRequestNotifications,
            //     ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
            //     _PermissionCard(
            //       icon: Symbols.install_mobile,
            //       title: localizations.app_installation,
            //       description: localizations.allow_florid_install_apps,
            //       isGranted: installPermissionGranted,
            //       onRequest: onRequestInstallPermission,
            //     ).animate().fadeIn(duration: 500.ms, delay: 600.ms),
            //   ],
            // ),
            MListView(
              items: [
                MListItemData(
                  title: localizations.app_installation,
                  subtitle: localizations.allow_florid_install_apps,
                  leading: ListIcon(
                    iconData: Symbols.install_mobile,
                    // color: colorScheme.primary,
                  ),
                  onTap: () {},
                  selected: installPermissionGranted,
                  suffix: FilledButton.tonal(
                    onPressed: onRequestInstallPermission,
                    child: Text(AppLocalizations.of(context)!.allow),
                  ),
                ),
              ],
            ),
            Column(
              children: [
                MListHeader(title: 'Optional'),
                MListView(
                  items: [
                    MListItemData(
                      title: localizations.notifications,
                      subtitle: localizations.get_notified_updates,
                      leading: ListIcon(
                        iconData: Symbols.notifications,
                        // color: colorScheme.primary,
                      ),
                      onTap: () {},
                      selected: notificationsGranted,
                      suffix: FilledButton.tonal(
                        onPressed: onRequestNotifications,
                        child: Text(AppLocalizations.of(context)!.allow),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Text(
              localizations.enable_permissions_anytime,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(duration: 500.ms, delay: 800.ms),
          ],
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isGranted,
    required this.onRequest,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool isGranted;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isGranted
            ? colorScheme.primaryContainer.withOpacity(0.5)
            : colorScheme.surfaceContainer,
        border: Border.all(
          color: isGranted ? colorScheme.primary : colorScheme.outlineVariant,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        spacing: 12,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isGranted
                  ? colorScheme.primary.withOpacity(0.2)
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isGranted
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (isGranted)
            Icon(Symbols.check_circle, color: colorScheme.primary, fill: 1)
          else
            SizedBox(
              height: 32,
              child: FilledButton.tonal(
                onPressed: onRequest,
                child: Text(AppLocalizations.of(context)!.allow),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({
    required this.colorScheme,
    required this.status,
    required this.progress,
  });

  final ColorScheme colorScheme;
  final String status;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Symbols.download,
              color: colorScheme.onPrimaryContainer,
              size: 48,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            localizations.setting_up_florid,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              year2023: false,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            status,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
