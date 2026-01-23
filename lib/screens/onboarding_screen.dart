import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../providers/repositories_provider.dart';
import '../providers/settings_provider.dart';
import '../services/fdroid_api_service.dart';
import 'florid_app.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  bool _addIzzy = true;
  final bool _isFinishing = false;
  int _currentPage = 0;
  String _progressStatus = 'Initializing...';
  double _progressValue = 0.0;

  @override
  void initState() {
    super.initState();
    // Ensure repositories are loaded so duplicate checks work
    Future.microtask(() {
      final repos = context.read<RepositoriesProvider>();
      repos.loadRepositories();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _startSetup() {
    // Navigate to progress screen
    _pageController.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.decelerate,
    );
    // Start the actual setup
    _performSetup();
  }

  Future<void> _performSetup() async {
    try {
      final settings = context.read<SettingsProvider>();
      final repos = context.read<RepositoriesProvider>();
      final appProvider = context.read<AppProvider>();

      // Step 1: Load repositories
      setState(() {
        _progressStatus = 'Loading repository configuration...';
        _progressValue = 0.1;
      });
      await repos.loadRepositories();
      await Future.delayed(const Duration(milliseconds: 300));

      // Step 2: Add IzzyOnDroid if selected
      if (_addIzzy) {
        setState(() {
          _progressStatus = 'Adding IzzyOnDroid repository...';
          _progressValue = 0.2;
        });
        const izzyUrl = 'https://apt.izzysoft.de/fdroid/repo';
        const izzyName = 'IzzyOnDroid';
        final hasIzzy = repos.repositories.any((repo) => repo.url == izzyUrl);
        if (!hasIzzy) {
          await repos.addRepository(izzyName, izzyUrl);
        }
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Step 3: Fetch official F-Droid repository
      setState(() {
        _progressStatus = 'Fetching F-Droid repository index...';
        _progressValue = 0.3;
      });
      await appProvider.fetchRepository();

      // Step 4: Wait for database import to complete
      setState(() {
        _progressStatus = 'Importing apps to database...';
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
          _progressStatus =
              'Importing apps to database... (${elapsed.inSeconds}s)';
        });

        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Step 5: Fetch custom repos if enabled (after main DB is ready)
      if (_addIzzy) {
        setState(() {
          _progressStatus = 'Loading custom repositories...';
          _progressValue = 0.75;
        });
        await repos.loadRepositories();
        final customUrls = repos.enabledRepositories.map((r) => r.url).toList();
        if (customUrls.isNotEmpty) {
          await appProvider.fetchRepositoriesFromUrls(customUrls);
        }

        // Wait for custom repo imports to complete
        await Future.delayed(const Duration(seconds: 3));
      }

      // Step 6: Fetch initial data
      setState(() {
        _progressStatus = 'Loading latest apps...';
        _progressValue = 0.85;
      });
      await appProvider.fetchLatestApps(repositoriesProvider: repos, limit: 50);

      setState(() {
        _progressStatus = 'Loading categories...';
        _progressValue = 0.95;
      });
      await appProvider.fetchCategories();

      // Step 7: Complete
      setState(() {
        _progressStatus = 'Setup complete!';
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
        _progressStatus = 'Error: ${e.toString()}';
      });
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Setup failed: $e'),
          action: SnackBarAction(label: 'Retry', onPressed: _performSetup),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _IntroStep(colorScheme: colorScheme),
                  _ReposStep(
                    addIzzy: _addIzzy,
                    onToggleIzzy: (value) => setState(() => _addIzzy = value),
                  ),
                  _ProgressStep(
                    colorScheme: colorScheme,
                    status: _progressStatus,
                    progress: _progressValue,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                spacing: 16,
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: FilledButton.tonal(
                          onPressed: _isFinishing || _currentPage == 0
                              ? null
                              : () {
                                  _pageController.previousPage(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeOut,
                                  );
                                },
                          child: const Text('Back'),
                        ),
                      ),
                    ),

                  if (_currentPage < 2)
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: () {
                            if (_currentPage == 0) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              );
                            } else if (_currentPage == 1) {
                              _startSetup();
                            }
                          },
                          child: Text(
                            _currentPage == 1 ? 'Start Setup' : 'Continue',
                          ),
                        ),
                      ),
                    ),
                ],
              ),
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
            'Welcome to Florid',
            style: Theme.of(context).textTheme.headlineMedium,
          ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
          const SizedBox(height: 12),
          Text(
            'A modern F-Droid client to browse, search, and download open-source Android apps with ease.',
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
                text: 'Curated open-source apps',
              ).animate().fadeIn(duration: 500.ms, delay: 500.ms),
              _Pill(
                text: 'Safe downloads',
              ).animate().fadeIn(duration: 500.ms, delay: 700.ms),
              _Pill(
                text: 'Updates & notifications',
              ).animate().fadeIn(duration: 500.ms, delay: 900.ms),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReposStep extends StatelessWidget {
  const _ReposStep({required this.addIzzy, required this.onToggleIzzy});

  final bool addIzzy;
  final ValueChanged<bool> onToggleIzzy;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [
          const SizedBox(height: 12),
          Row(
            spacing: 8,
            children: [
              Icon(Symbols.dns),
              Text(
                'Add extra repositories',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ).animate().fadeIn(duration: 500.ms),
          const SizedBox(height: 12),
          Text(
            'Florid ships with the official F-Droid repo. You can also include trusted community repos to get more apps.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: CheckboxListTile(
              value: addIzzy,
              onChanged: (value) => onToggleIzzy(value ?? false),
              title: const Text('IzzyOnDroid'),
              subtitle: const Text('https://apt.izzysoft.de/fdroid/repo'),
              secondary: const Icon(Symbols.extension),
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
          const Spacer(),
          Text(
            'You can add or remove repositories anytime in Settings.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 500.ms, delay: 600.ms),
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
            'Setting up Florid',
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
