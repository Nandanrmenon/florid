import 'package:florid/l10n/app_localizations.dart';
import 'package:florid/models/search_filters.dart';
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
  SearchFilters _filters = const SearchFilters();

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
    appProvider.searchApps(
      query,
      repositoriesProvider: repositoriesProvider,
      filters: _filters,
    );
  }

  void _clearSearch() {
    _searchController.clear();
    final appProvider = context.read<AppProvider>();
    appProvider.clearSearch();
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _FilterBottomSheet(
        currentFilters: _filters,
        onApply: (newFilters) {
          setState(() {
            _filters = newFilters;
          });
          if (_searchController.text.trim().isNotEmpty) {
            _performSearch(_searchController.text.trim());
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
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
                hintText: localizations.search_fdroid_apps,
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
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: Consumer<AppProvider>(
                builder: (context, appProvider, _) {
                  final results = appProvider.searchResults;
                  final query = appProvider.searchQuery;

                  if (query.isNotEmpty && results.isNotEmpty) {
                    return Text(
                      localizations.search_results_for_query(
                        results.length,
                        query,
                      ),
                      style: Theme.of(context).textTheme.titleMedium,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              actions: [
                Badge(
                  isLabelVisible: _filters.hasActiveFilters,
                  label: Text(_filters.activeFilterCount.toString()),
                  child: IconButton.filledTonal(
                    onPressed: _openFilters,
                    icon: const Icon(Symbols.filter_list),
                    tooltip: localizations.filters,
                  ),
                ),
                SizedBox(width: 8),
              ],
            ),
            SliverToBoxAdapter(
              child: Consumer<AppProvider>(
                builder: (context, appProvider, child) {
                  final state = appProvider.searchState;
                  final results = appProvider.searchResults;
                  final error = appProvider.searchError;
                  final query = appProvider.searchQuery;
                  final settingsProvider = context.read<SettingsProvider>();

                  final bottomPadding =
                      settingsProvider.themeStyle == ThemeStyle.florid
                      ? 96.0
                      : 16.0;

                  // Show initial state
                  if (query.isEmpty) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Symbols.search,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          localizations.search_apps,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 32),
                        Card(
                          // margin: const EdgeInsets.symmetric(horizontal: 16),
                          child: _SearchSuggestions(
                            onSuggestionTap: (suggestion) {
                              setState(() {
                                _searchController.text = suggestion;
                              });
                              _performSearch(suggestion);
                            },
                          ),
                        ),
                      ],
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
                            localizations.search_failed,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error ?? localizations.unknown_error_occurred,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
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
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            localizations.no_apps_found,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            localizations.try_different_keywords,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Show results
                  return Card(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
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
                                builder: (context) =>
                                    AppDetailsScreen(app: app),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
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
    final localizations = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            localizations.popular_searches,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
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
      ],
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final SearchFilters currentFilters;
  final Function(SearchFilters) onApply;

  const _FilterBottomSheet({
    required this.currentFilters,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late Set<String> _selectedCategories;
  late Set<String> _selectedRepositories;
  late SortOption _selectedSort;

  @override
  void initState() {
    super.initState();
    _selectedCategories = Set.from(widget.currentFilters.categories);
    _selectedRepositories = Set.from(widget.currentFilters.repositories);
    _selectedSort = widget.currentFilters.sortBy;

    // Load categories if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appProvider = context.read<AppProvider>();
      if (appProvider.categories.isEmpty &&
          appProvider.categoriesState != LoadingState.loading) {
        appProvider.fetchCategories();
      }
    });
  }

  void _applyFilters() {
    final newFilters = SearchFilters(
      categories: _selectedCategories,
      repositories: _selectedRepositories,
      sortBy: _selectedSort,
    );
    widget.onApply(newFilters);
    Navigator.pop(context);
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategories.clear();
      _selectedRepositories.clear();
      _selectedSort = SortOption.relevance;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Consumer2<AppProvider, RepositoriesProvider>(
          builder: (context, appProvider, repoProvider, child) {
            final categories = appProvider.categories;
            final repositories = repoProvider.enabledRepositories;

            // Extract categories available in search results
            final searchResults = appProvider.searchResults;
            final availableCategories = <String>{};
            for (final app in searchResults) {
              if (app.categories != null) {
                availableCategories.addAll(app.categories!);
              }
            }

            // Filter categories to only show those in search results
            final filteredCategories = categories
                .where((cat) => availableCategories.contains(cat))
                .toList();

            return Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        localizations.filters,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton(
                        onPressed: _clearAllFilters,
                        child: Text(localizations.clear_all),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Filter options
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Sort by section
                      Text(
                        localizations.sort_by,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _SortChip(
                            label: localizations.relevance,
                            selected: _selectedSort == SortOption.relevance,
                            onSelected: () => setState(
                              () => _selectedSort = SortOption.relevance,
                            ),
                          ),
                          _SortChip(
                            label: localizations.name_az,
                            selected: _selectedSort == SortOption.nameAsc,
                            onSelected: () => setState(
                              () => _selectedSort = SortOption.nameAsc,
                            ),
                          ),
                          _SortChip(
                            label: localizations.name_za,
                            selected: _selectedSort == SortOption.nameDesc,
                            onSelected: () => setState(
                              () => _selectedSort = SortOption.nameDesc,
                            ),
                          ),
                          _SortChip(
                            label: localizations.recently_added,
                            selected: _selectedSort == SortOption.dateAddedDesc,
                            onSelected: () => setState(
                              () => _selectedSort = SortOption.dateAddedDesc,
                            ),
                          ),
                          _SortChip(
                            label: localizations.recently_updated,
                            selected:
                                _selectedSort == SortOption.dateUpdatedDesc,
                            onSelected: () => setState(
                              () => _selectedSort = SortOption.dateUpdatedDesc,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Categories section
                      Text(
                        localizations.categories,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (appProvider.categoriesState == LoadingState.loading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (filteredCategories.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            localizations.no_categories_available,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: filteredCategories.map((category) {
                            return FilterChip(
                              label: Text(category),
                              selected: _selectedCategories.contains(category),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedCategories.add(category);
                                  } else {
                                    _selectedCategories.remove(category);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),

                      const SizedBox(height: 24),

                      // Repositories section
                      if (repositories.length > 1) ...[
                        Text(
                          localizations.repositories,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: repositories.map((repo) {
                            return FilterChip(
                              label: Text(repo.name),
                              selected: _selectedRepositories.contains(
                                repo.url,
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedRepositories.add(repo.url);
                                  } else {
                                    _selectedRepositories.remove(repo.url);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                // Apply button
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _applyFilters,
                        icon: const Icon(Symbols.check),
                        label: Text(localizations.apply_filters),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _SortChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: true,
    );
  }
}
