import 'package:florid/l10n/app_localizations.dart';
import 'package:florid/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../providers/repositories_provider.dart';
import '../widgets/app_list_item.dart';
import 'app_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus search field when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Clear any previous search results
      final appProvider = context.read<AppProvider>();
      appProvider.clearSearch();

      _searchFocus.requestFocus();
      SystemChannels.textInput.invokeMethod('TextInput.show');
    });
  }

  @override
  void dispose() {
    // Clear search results when leaving the screen (before super.dispose)
    try {
      final appProvider = context.read<AppProvider>();
      appProvider.clearSearch();
    } catch (e) {
      // Context might not be available
    }
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    final appProvider = context.read<AppProvider>();
    final repositoriesProvider = context.read<RepositoriesProvider>();
    appProvider.searchApps(query, repositoriesProvider: repositoriesProvider);
  }

  void _clearSearch() {
    _searchController.clear();
    final appProvider = context.read<AppProvider>();
    appProvider.clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        final focus = FocusScope.of(context);
        if (!focus.hasPrimaryFocus && focus.focusedChild != null) {
          focus.unfocus();
        }
      },
      child: Scaffold(
        extendBody: true,
        bottomNavigationBar: Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: BottomAppBar(
            color: Colors.transparent,
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              decoration: InputDecoration(
                hintText: 'Search F-Droid apps...',
                prefixIcon: const Icon(Symbols.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Symbols.close),
                        onPressed: _clearSearch,
                      )
                    : null,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: _performSearch,
              onChanged: (query) {
                // Rebuild to show/hide clear button
                setState(() {});

                // Debounced search - search after user stops typing
                if (query.trim().isNotEmpty) {
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (_searchController.text.trim() == query.trim()) {
                      _performSearch(query.trim());
                    }
                  });
                } else {
                  _clearSearch();
                }
              },
            ),
          ),
        ),
        appBar: AppBar(
          // scrolledUnderElevation: 0,
          // elevation: 0,
          // backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        ),
        body: Consumer<AppProvider>(
          builder: (context, appProvider, child) {
            final state = appProvider.searchState;
            final results = appProvider.searchResults;
            final error = appProvider.searchError;
            final query = appProvider.searchQuery;
            final settingsProvider = context.read<SettingsProvider>();

            final bottomPadding =
                settingsProvider.themeStyle == ThemeStyle.florid ? 96.0 : 16.0;

            // Show initial state
            if (query.isEmpty) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 64),
                    Icon(
                      Symbols.search,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Search Apps',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 32),
                    _SearchSuggestions(
                      onSuggestionTap: (suggestion) {
                        setState(() {
                          _searchController.text = suggestion;
                        });
                        _performSearch(suggestion);
                      },
                    ),
                  ],
                ),
              );
            }

            // Show loading
            if (state == LoadingState.loading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(AppLocalizations.of(context)!.searching),
                  ],
                ),
              );
            }

            // Show error
            if (state == LoadingState.error) {
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
                      'Search failed',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error ?? 'Unknown error occurred',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _performSearch(query),
                      icon: const Icon(Symbols.refresh),
                      label: Text(AppLocalizations.of(context)!.retry),
                    ),
                  ],
                ),
              );
            }

            // Show no results
            if (results.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Symbols.search_off,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No apps found',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try different keywords or check spelling',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Show results
            return Column(
              children: [
                // Results header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                  ),
                  child: Text(
                    '${results.length} results for "$query"',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),

                // Results list
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(8, 8, 8, bottomPadding),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final app = results[index];
                      return AppListItem(
                        app: app,
                        showInstallStatus: false,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AppDetailsScreen(app: app),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SearchSuggestions extends StatelessWidget {
  final Function(String) onSuggestionTap;

  const _SearchSuggestions({required this.onSuggestionTap});

  static const List<String> _suggestions = [
    'browser',
    'messaging',
    'camera',
    'music',
    'games',
    'calculator',
    'file manager',
    'note taking',
    'gallery',
    'keyboard',
    'launcher',
    'email',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Popular searches:',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,

            alignment: WrapAlignment.center,
            children: _suggestions.map((suggestion) {
              return ActionChip(
                label: Text(suggestion),
                onPressed: () => onSuggestionTap(suggestion),
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                side: BorderSide.none,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
