import 'dart:convert';

import 'package:florid/constants.dart';
import 'package:florid/l10n/app_localizations.dart';
import 'package:florid/services/usage_analytics_service.dart';
import 'package:florid/widgets/list_icon.dart';
import 'package:florid/widgets/onboarding_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/svg.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../providers/repositories_provider.dart';
import '../providers/settings_provider.dart';
import '../services/fdroid_api_service.dart';
import '../widgets/m_list.dart';
import 'florid_app.dart';
import 'settings/repository_qr_scanner.dart';

enum SetupType { basic, advanced }

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final Map<String, bool> _selectedRepos = {};
  final bool _isFinishing = false;
  bool _setupInProgress = false;
  bool _setupCancelled = false;
  int _currentPage = 0;
  String _progressStatus = '';
  double _progressValue = 0.0;
  List<Map<String, dynamic>> _presets = [];
  bool _notificationsGranted = false;
  bool _installPermissionGranted = false;
  SetupType? _setupType;
  bool _telemetryOptOut = false;

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

  void _selectSetupType(SetupType type) {
    setState(() {
      _setupType = type;
    });

    if (type == SetupType.basic) {
      // For basic setup, select all default repositories
      for (var preset in _presets) {
        if (preset['default'] == true) {
          _selectedRepos[preset['url'] as String] = true;
        }
      }
      // Opt-in to telemetry for basic setup
      _telemetryOptOut = false;
      // Move to permissions
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.decelerate,
      );
    } else {
      // For advanced setup, move to permissions then repos then telemetry
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.decelerate,
      );
    }
  }

  Future<void> _loadPresets() async {
    try {
      final jsonString = await DefaultAssetBundle.of(
        context,
      ).loadString('assets/repositories.json');
      final jsonData = jsonDecode(jsonString);
      final repos = (jsonData['repositories'] as List)
          .map(
            (e) => <String, dynamic>{
              'name': e['name'] as String,
              'url': e['url'] as String,
              'description': e['description'] as String? ?? '',
              'fingerprint': e['fingerprint'] as String? ?? '',
              'default': e['default'] as bool? ?? false,
            },
          )
          .toList()
          .cast<Map<String, dynamic>>();

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

  ({String cleanUrl, String fingerprint}) _extractUrlAndFingerprint(
    String rawUrl,
  ) {
    var cleanUrl = rawUrl.trim();
    var fingerprint = '';

    final uri = Uri.tryParse(cleanUrl);
    if (uri != null && uri.queryParameters.containsKey('fingerprint')) {
      fingerprint = uri.queryParameters['fingerprint'] ?? '';
      cleanUrl = uri.replace(queryParameters: {}).toString();
      if (cleanUrl.endsWith('?')) {
        cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
      }
    }

    return (cleanUrl: cleanUrl, fingerprint: fingerprint);
  }

  void _addCustomRepoToSelection(String name, String url) {
    final parsed = _extractUrlAndFingerprint(url);
    final normalizedUrl = parsed.cleanUrl;
    final alreadyExists = _presets.any(
      (repo) =>
          (repo['url'] as String).toLowerCase() == normalizedUrl.toLowerCase(),
    );

    if (alreadyExists) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This repository URL already exists')),
      );
      return;
    }

    setState(() {
      _presets.add(<String, Object>{
        'name': name.trim().isEmpty ? Uri.parse(normalizedUrl).host : name,
        'url': normalizedUrl,
        'description': 'Custom repository',
        'fingerprint': parsed.fingerprint,
        'default': false,
      });
      _selectedRepos[normalizedUrl] = true;
    });
  }

  Future<void> _showAddCustomRepoDialog() async {
    final localizations = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final urlController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.add_repository),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: localizations.enter_repository_name,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                labelText: localizations.enter_repository_url,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localizations.cancel),
          ),
          FilledButton.tonal(
            onPressed: () {
              final url = urlController.text.trim();
              final name = nameController.text.trim();

              if (url.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(localizations.enter_repository_url)),
                );
                return;
              }

              final uri = Uri.tryParse(url);
              if (uri == null ||
                  !(url.startsWith('http://') || url.startsWith('https://'))) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid URL format')),
                );
                return;
              }

              Navigator.of(context).pop();
              _addCustomRepoToSelection(name, url);
            },
            child: Text(localizations.save),
          ),
        ],
      ),
    );
  }

  Future<void> _openRepoScanner() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RepositoryQRScanner(
          onScan: (url) {
            _addCustomRepoToSelection('', url);
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _getTotalPages() {
    switch (_setupType) {
      case SetupType.basic:
        return 4; // Intro, SetupType, Permissions, Progress
      case SetupType.advanced:
        return 6; // Intro, SetupType, Permissions, Repos, Privacy, Progress
      case null:
        return 2; // Intro, SetupType
    }
  }

  List<Widget> _buildPages() {
    final colorScheme = Theme.of(context).colorScheme;
    final pages = <Widget>[
      _IntroStep(colorScheme: colorScheme),
      _SetupTypeStep(onSelected: _selectSetupType),
    ];

    if (_setupType == SetupType.basic) {
      pages.addAll([
        _PermissionsStep(
          notificationsGranted: _notificationsGranted,
          installPermissionGranted: _installPermissionGranted,
          onRequestNotifications: _requestNotifications,
          onRequestInstallPermission: _requestInstallPermission,
        ),
        _ProgressStep(
          colorScheme: colorScheme,
          status: _progressStatus,
          progress: _progressValue,
        ),
      ]);
    } else if (_setupType == SetupType.advanced) {
      pages.addAll([
        _PermissionsStep(
          notificationsGranted: _notificationsGranted,
          installPermissionGranted: _installPermissionGranted,
          onRequestNotifications: _requestNotifications,
          onRequestInstallPermission: _requestInstallPermission,
        ),
        _ReposStep(
          selectedRepos: _selectedRepos,
          presets: _presets,
          onAddCustomRepo: _showAddCustomRepoDialog,
          onScanCustomRepo: _openRepoScanner,
          onToggleRepo: (url, selected) {
            setState(() {
              _selectedRepos[url] = selected;
            });
          },
        ),
        _TelemetryStep(
          telemetryOptOut: _telemetryOptOut,
          onTelemetryChoice: (optOut) {
            setState(() {
              _telemetryOptOut = optOut;
            });
          },
        ),
        _ProgressStep(
          colorScheme: colorScheme,
          status: _progressStatus,
          progress: _progressValue,
        ),
      ]);
    }

    return pages;
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
    _setupInProgress = true;
    _setupCancelled = false;
    context.read<AppProvider>().resetRepositoryOperationsCancellation();
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
      final analyticsService = UsageAnalyticsService();

      // Save telemetry preference
      await analyticsService.setOptOut(_telemetryOptOut);

      // Step 1: Load repositories
      if (_setupCancelled) {
        _finalizeCancelledSetup();
        return;
      }
      setState(() {
        _progressStatus = AppLocalizations.of(
          context,
        )!.loading_repository_configuration;
        _progressValue = 0.1;
      });
      await repos.loadRepositories();
      await Future.delayed(const Duration(milliseconds: 300));

      // Step 2: Add selected repositories
      if (_setupCancelled) {
        _finalizeCancelledSetup();
        return;
      }
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
              final fingerprint =
                  (preset['fingerprint'] as String?)?.trim() ?? '';
              await repos.addRepository(
                preset['name'] as String,
                preset['url'] as String,
                fingerprint: fingerprint.isEmpty ? null : fingerprint,
              );
            }
          }
        }
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Step 3: Fetch official F-Droid repository
      if (_setupCancelled) {
        _finalizeCancelledSetup();
        return;
      }
      setState(() {
        _progressStatus = AppLocalizations.of(
          context,
        )!.fetching_fdroid_repository_index;
        _progressValue = 0.3;
      });
      await appProvider.fetchRepository();

      // Step 4: Wait for database import to complete
      if (_setupCancelled) {
        _finalizeCancelledSetup();
        return;
      }
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
        if (_setupCancelled) {
          _finalizeCancelledSetup();
          return;
        }
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
      if (_setupCancelled) {
        _finalizeCancelledSetup();
        return;
      }
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
      if (_setupCancelled) {
        _finalizeCancelledSetup();
        return;
      }
      setState(() {
        _progressStatus = AppLocalizations.of(context)!.loading_latest_apps;
        _progressValue = 0.85;
      });
      await appProvider.fetchLatestApps(repositoriesProvider: repos, limit: 50);

      if (_setupCancelled) {
        _finalizeCancelledSetup();
        return;
      }
      setState(() {
        _progressStatus = AppLocalizations.of(context)!.loading_categories;
        _progressValue = 0.95;
      });
      await appProvider.fetchCategories();

      // Step 7: Complete
      if (_setupCancelled) {
        _finalizeCancelledSetup();
        return;
      }
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
            onPressed: () {
              _setupInProgress = true;
              _setupCancelled = false;
              _performSetup();
            },
          ),
        ),
      );
    } finally {
      _setupInProgress = false;
    }
  }

  void _finalizeCancelledSetup() {
    _setupInProgress = false;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages();
    final totalPages = _getTotalPages();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: _currentPage > 0
            ? IconButton(
                onPressed: _isFinishing || _currentPage == 0
                    ? null
                    : () {
                        if (_setupInProgress) {
                          // Show cancel dialog if setup is in progress
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Cancel setup?'),
                              content: const Text(
                                'Are you sure you want to cancel the setup? You can restart it later.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Continue'),
                                ),
                                FilledButton.tonal(
                                  onPressed: () {
                                    context
                                        .read<AppProvider>()
                                        .cancelRepositoryOperations();
                                    setState(() => _setupCancelled = true);
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Cancel setup'),
                                ),
                              ],
                            ),
                          );
                        } else {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          );
                        }
                      },
                icon: Icon(Symbols.arrow_back),
              ).animate().fadeIn(duration: 500.ms)
            : null,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.5),
              Theme.of(context).colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  children: pages,
                ),
              ),
              if (_currentPage < totalPages - 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    height: 48,
                    child: OnboardingPrimaryButton(
                      currentPage: _currentPage,
                      isFinishing: _isFinishing,
                      canProceed: _getCanProceed(),
                      shouldStartSetup: _shouldStartSetup(),
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
      ),
    );
  }

  bool _getCanProceed() {
    if (_setupType == null && _currentPage == 1) {
      return false; // Setup type must be selected
    }
    // Permissions page (page 2) requires install permission to proceed
    if (_currentPage == 2) {
      return _installPermissionGranted;
    }
    if (_setupType == SetupType.advanced) {
      // Repos step (page 3) - at least one repo must be selected
      if (_currentPage == 3) {
        return _selectedRepos.values.any((selected) => selected);
      }
    }
    return true;
  }

  bool _shouldStartSetup() {
    if (_setupType == SetupType.basic) {
      // For basic, start setup from Permissions page (page 2)
      return _currentPage == 2;
    } else if (_setupType == SetupType.advanced) {
      // For advanced, start setup from Privacy/Telemetry page (page 4)
      return _currentPage == 4;
    }
    return false;
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Material(
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            elevation: 2,
            color: colorScheme.primaryContainer,
            child: SvgPicture.asset(
              'assets/Florid.svg',
              height: 84,
              colorFilter: ColorFilter.mode(
                colorScheme.onPrimaryContainer,
                BlendMode.srcIn,
              ),
            ),
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
            kAppName,
            style: TextStyle(
              fontSize: 42,
              fontVariations: [
                FontVariation('wght', 700),
                FontVariation('ROND', 100),
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
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 500.ms, delay: 300.ms),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
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
    required this.onAddCustomRepo,
    required this.onScanCustomRepo,
    required this.onToggleRepo,
  });

  final Map<String, bool> selectedRepos;
  final List<Map<String, dynamic>> presets;
  final VoidCallback onAddCustomRepo;
  final VoidCallback onScanCustomRepo;
  final Function(String url, bool selected) onToggleRepo;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8.0,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              spacing: 16.0,
              children: [
                Column(
                  spacing: 8,
                  children: [
                    CircleAvatar(
                      radius: 48,
                      child: Icon(Symbols.dns, size: 48),
                    ).animate().fadeIn(duration: 500.ms),
                    Text(
                      localizations.add_extra_repositories,
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            fontFamily: 'Google Sans Flex',
                            fontVariations: [
                              FontVariation('wght', 600),
                              FontVariation('ROND', 100),
                            ],
                          ),
                    ).animate().fadeIn(duration: 500.ms),
                  ],
                ),
                Text(
                  localizations.repos_step_description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 500.ms, delay: 600.ms),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              spacing: 8,
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onAddCustomRepo,
                    icon: const Icon(Symbols.add),
                    label: Text(localizations.add_repository),
                  ),
                ),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onScanCustomRepo,
                    icon: const Icon(Symbols.qr_code_scanner),
                    label: Text(localizations.scan),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 700.ms),
          const SizedBox(height: 12),
        ],
      ),
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
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                spacing: 8.0,
                children: [
                  Column(
                    spacing: 8,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 48,
                        child: Icon(Symbols.notifications_active, size: 48),
                      ).animate().fadeIn(duration: 500.ms),
                      Text(
                        localizations.request_permissions,
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              fontFamily: 'Google Sans Flex',
                              fontVariations: [
                                FontVariation('wght', 600),
                                FontVariation('ROND', 100),
                              ],
                            ),
                      ).animate().fadeIn(duration: 500.ms),
                    ],
                  ),
                  Text(
                    localizations.permissions_step_description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
                ],
              ),
            ),
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
                  suffix: installPermissionGranted
                      ? null
                      : FilledButton.tonal(
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
                      suffix: notificationsGranted
                          ? null
                          : FilledButton.tonal(
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

class _SetupTypeStep extends StatelessWidget {
  const _SetupTypeStep({required this.onSelected});

  final Function(SetupType) onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          Column(
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 48,
                child: Icon(Symbols.settings, size: 48),
              ).animate().fadeIn(duration: 500.ms),
              Text(
                'Setup Type',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontFamily: 'Google Sans Flex',
                  fontVariations: [
                    FontVariation('wght', 600),
                    FontVariation('ROND', 100),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms),
              Text(
                'Choose how you want to set up Florid',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
            ],
          ),
          Column(
            spacing: 8.0,
            children: [
              _SetupOptionCard(
                title: 'Basic Setup',
                description: 'Quick start with recommended repositories',
                icon: Symbols.bolt_rounded,
                onTap: () => onSelected(SetupType.basic),
              ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
              _SetupOptionCard(
                title: 'Advanced Setup',
                description: 'Customize repositories and preferences',
                icon: Symbols.eyeglasses_2_rounded,
                onTap: () => onSelected(SetupType.advanced),
              ).animate().fadeIn(duration: 500.ms, delay: 300.ms),
            ],
          ),
        ],
      ),
    );
  }
}

class _SetupOptionCard extends StatelessWidget {
  const _SetupOptionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            spacing: 16,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: colorScheme.onPrimaryContainer,
                  size: 24,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontFamily: 'Google Sans Flex',
                        fontVariations: [
                          FontVariation('wght', 600),
                          FontVariation('ROND', 100),
                        ],
                      ),
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
              Icon(
                Symbols.arrow_forward_ios,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TelemetryStep extends StatefulWidget {
  const _TelemetryStep({
    required this.telemetryOptOut,
    required this.onTelemetryChoice,
  });

  final bool telemetryOptOut;
  final Function(bool) onTelemetryChoice;

  @override
  State<_TelemetryStep> createState() => _TelemetryStepState();
}

class _TelemetryStepState extends State<_TelemetryStep> {
  late bool _optOut;

  @override
  void initState() {
    super.initState();
    _optOut = widget.telemetryOptOut;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          spacing: 16.0,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                spacing: 16.0,
                children: [
                  Column(
                    spacing: 8,
                    children: [
                      CircleAvatar(
                        radius: 48,
                        child: Icon(
                          Symbols.data_loss_prevention_rounded,
                          size: 48,
                        ),
                      ).animate().fadeIn(duration: 500.ms),
                      Text(
                        'Privacy',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              fontFamily: 'Google Sans Flex',
                              fontVariations: [
                                FontVariation('wght', 600),
                                FontVariation('ROND', 100),
                              ],
                            ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 500.ms),
                  Text(
                    'Help us improve Florid',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
                ],
              ),
            ),
            MListView(
              items: [
                MListItemData(
                  title: AppLocalizations.of(context)!.opt_out_of_telemetry,
                  subtitle: AppLocalizations.of(
                    context,
                  )!.opt_out_of_telemetry_subtitle,
                  onTap: () {
                    setState(() => _optOut = false);
                    widget.onTelemetryChoice(false);
                  },
                  suffix: Checkbox(
                    value: _optOut,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _optOut = !value);
                        widget.onTelemetryChoice(!value);
                      }
                    },
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Your data is anonymous and never shared with third parties',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
            ),
          ],
        ),
      ),
    );
  }
}
