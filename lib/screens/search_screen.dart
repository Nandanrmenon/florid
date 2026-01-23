import 'package:florid/utils/menu_actions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../providers/repositories_provider.dart';
import '../widgets/app_list_item.dart';
import 'app_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.tabIndexListenable, this.tabIndex = 1});

  /// Notifies the screen when the search tab becomes active.
  final ValueListenable<int>? tabIndexListenable;

  /// The index of the search tab in the parent navigation.
  final int tabIndex;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  void _requestFocus() {
    // Defer to ensure the widget tree is ready, then show keyboard.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _searchFocus.requestFocus();
      SystemChannels.textInput.invokeMethod('TextInput.show');
    });
  }

  void _handleTabChange() {
    if (!mounted) return;
    final current = widget.tabIndexListenable?.value;
    if (current == widget.tabIndex) {
      _requestFocus();
    }
  }

  @override
  void initState() {
    super.initState();
    widget.tabIndexListenable?.addListener(_handleTabChange);
    // Focus once on first build even if opened directly.
    _requestFocus();
  }

  @override
  void dispose() {
    widget.tabIndexListenable?.removeListener(_handleTabChange);
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
        appBar: AppBar(
          scrolledUnderElevation: 0,
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
          toolbarHeight: 80,
          title: TextField(
            controller: _searchController,
            focusNode: _searchFocus,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search F-Droid apps...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(99),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(99),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              filled: true,
              prefixIcon: const Icon(Symbols.search),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: _performSearch,
            onChanged: (query) {
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
          actions: [
            Consumer<AppProvider>(
              builder: (context, appProvider, child) {
                if (appProvider.searchQuery.isNotEmpty) {
                  return IconButton(
                    icon: const Icon(Symbols.close),
                    onPressed: _clearSearch,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'settings':
                    MenuActions.showSettings(context);
                    break;
                  case 'about':
                    MenuActions.showAbout(context);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'settings',
                  child: ListTile(
                    leading: Icon(Symbols.settings),
                    title: Text('Settings'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'about',
                  child: ListTile(
                    leading: Icon(Symbols.info),
                    title: Text('About'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            SizedBox(width: 8),
          ],
        ),
        body: Consumer<AppProvider>(
          builder: (context, appProvider, child) {
            final state = appProvider.searchState;
            final results = appProvider.searchResults;
            final error = appProvider.searchError;
            final query = appProvider.searchQuery;

            // Show initial state
            if (query.isEmpty) {
              return Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Symbols.search,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Search F-Droid Apps',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Find free and open-source Android apps',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _SearchSuggestions(
                        onSuggestionTap: (suggestion) {
                          _searchController.text = suggestion;
                          _performSearch(suggestion);
                        },
                      ),
                    ],
                  ),
                ),
              );
            }

            // Show loading
            if (state == LoadingState.loading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(year2023: false),
                    SizedBox(height: 16),
                    Text('Searching...'),
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
                      label: const Text('Retry'),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final app = results[index];
                      return AppListItem(
                        app: app,
                        onTap: () async {
                          final screenshots = await context
                              .read<AppProvider>()
                              .getScreenshots(app.packageName);
                          if (!context.mounted) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AppDetailsScreen(
                                app: app,
                                screenshots: screenshots.isNotEmpty
                                    ? screenshots
                                    : null,
                              ),
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
