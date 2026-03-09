import 'package:florid/l10n/app_localizations.dart';
import 'package:florid/models/fdroid_app.dart';
import 'package:florid/providers/download_provider.dart';
import 'package:florid/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import 'app_details_screen.dart';

class DeveloperAppsScreen extends StatefulWidget {
  final String developerName;

  const DeveloperAppsScreen({super.key, required this.developerName});

  @override
  State<DeveloperAppsScreen> createState() => _DeveloperAppsScreenState();
}

class _DeveloperAppsScreenState extends State<DeveloperAppsScreen> {
  List<FDroidApp> _developerApps = [];
  LoadingState _state = LoadingState.loading;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _state = LoadingState.loading;
      _error = null;
    });

    try {
      final appProvider = context.read<AppProvider>();

      // Fetch apps by author name directly from database
      final apps = await appProvider.fetchAppsByAuthor(widget.developerName);

      setState(() {
        _developerApps = apps;
        _state = LoadingState.success;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _state = LoadingState.error;
      });
    }
  }

  Future<void> _onRefresh() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment:
              context.watch<SettingsProvider>().themeStyle == ThemeStyle.florid
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            Text(
              widget.developerName,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              '${_developerApps.length} ${_developerApps.length == 1 ? 'app' : 'apps'}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_state == LoadingState.loading && _developerApps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(year2023: false),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.loading_apps),
          ],
        ),
      );
    }

    if (_state == LoadingState.error && _developerApps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Symbols.error,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.failed_to_load_apps,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? AppLocalizations.of(context)!.unknown_error_occurred,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Symbols.refresh),
              label: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      );
    }

    if (_developerApps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Symbols.apps, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.no_apps_found,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              // crossAxisCount: constraints.maxWidth ~/ 400,
              crossAxisCount: 3,

              // childAspectRatio: 1.2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: .65,
            ),
            itemCount: _developerApps.length,
            itemBuilder: (context, index) {
              return Consumer2<DownloadProvider, AppProvider>(
                builder: (context, downloadProvider, appProvider, child) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AppDetailsScreen(app: _developerApps[index]),
                        ),
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 4.0,
                      children: [
                        Material(
                          clipBehavior: Clip.antiAlias,
                          borderRadius: BorderRadius.circular(16),
                          elevation: 0.3,
                          child: AppDetailsIcon(app: _developerApps[index]),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _developerApps[index].name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontVariations: [
                                    FontVariation('wght', 700),
                                    FontVariation('ROND', 100),
                                  ],
                                ),
                              ),
                              Text(
                                _developerApps[index]
                                        .latestVersion
                                        ?.sizeString ??
                                    '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  // fontVariations: [
                                  //   FontVariation('wght', 700),
                                  //   FontVariation('ROND', 100),
                                  // ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
