import 'package:florid/l10n/app_localizations.dart';
import 'package:florid/providers/settings_provider.dart';
import 'package:florid/widgets/app_list_item.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hornbill/hornbill.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:solar_icons/solar_icons.dart';

import '../../providers/app_provider.dart';
import '../app_details/app_details_screen.dart';
import 'app_section_viewer.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with AutomaticKeepAliveClientMixin {
  final Set<String> _requestedCategoryLoads = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final appProvider = context.read<AppProvider>();
    _requestedCategoryLoads.clear();
    appProvider.fetchCategories();
  }

  Future<void> _onRefresh() async {
    _requestedCategoryLoads.clear();
    final appProvider = context.read<AppProvider>();
    await appProvider.fetchCategories();
  }

  void _ensureCategoryAppsLoaded(String category) {
    final appProvider = context.read<AppProvider>();
    if (appProvider.categoryApps.containsKey(category) ||
        _requestedCategoryLoads.contains(category)) {
      return;
    }

    _requestedCategoryLoads.add(category);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      appProvider.fetchAppsByCategory(category);
    });
  }

  void _openCategoryViewer(BuildContext context, String category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AppSectionViewer(
          title: category,
          subtitle: AppLocalizations.of(
            context,
          )!.section_app_count(category.length),
          stateSelector: (appProvider) => appProvider.categoryAppsState,
          appsSelector: (appProvider) =>
              appProvider.categoryApps[category] ?? [],
          errorSelector: (appProvider) => appProvider.categoryAppsError,
          onRefresh: (context) async {
            final appProvider = context.read<AppProvider>();
            appProvider.categoryApps.remove(category);
            await appProvider.fetchAppsByCategory(category);
          },
          loadingMessage: AppLocalizations.of(context)!.loading_apps,
          emptyMessage: AppLocalizations.of(
            context,
          )!.no_apps_in_category(category),
          emptyIcon: Symbols.apps,
          showInstallStatus: true,
        ),
      ),
    );
  }

  Widget _buildShowMoreCard(BuildContext context, String category) {
    return SizedBox(
      width: 150,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openCategoryViewer(context, category),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context)!.show_more,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                Icon(
                  SolarIconsOutline.arrowRight,
                  size: 26,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer2<AppProvider, SettingsProvider>(
      builder: (context, appProvider, settingsProvider, child) {
        final state = appProvider.categoriesState;
        final categories = appProvider.categories;
        final error = appProvider.categoriesError;
        final isFlorid = settingsProvider.themeStyle == ThemeStyle.florid;
        final isDarkKnight =
            settingsProvider.themeStyle == ThemeStyle.darkKnight;
        return _buildBody(state, categories, error, isFlorid, isDarkKnight);
      },
    );
  }

  Widget _buildBody(
    LoadingState state,
    List<String> categories,
    String? error,
    bool isFlorid,
    bool isDarkKnight,
  ) {
    if (state == LoadingState.loading && categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const M3EContainedLoadingIndicator(),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.loading_categories),
          ],
        ),
      );
    }

    if (state == LoadingState.error && categories.isEmpty) {
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
              'Failed to load categories',
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
              onPressed: _loadData,
              icon: const Icon(Symbols.refresh),
              label: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      );
    }

    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Symbols.category, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.no_categories_found),
          ],
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index.isOdd) {
                    return const SizedBox(height: 8);
                  }
                  final categoryIndex = index ~/ 2;
                  final category = categories[categoryIndex];
                  final categoryApps =
                      context.watch<AppProvider>().categoryApps[category] ?? [];
                  final appProvider = context.read<AppProvider>();
                  if (state == LoadingState.success) {
                    _ensureCategoryAppsLoaded(category);
                  }
                  final isCategoryLoading =
                      appProvider.categoryAppsState == LoadingState.loading &&
                      !appProvider.categoryApps.containsKey(category);
                  final isCategoryError =
                      appProvider.categoryAppsState == LoadingState.error &&
                      !appProvider.categoryApps.containsKey(category);
                  final displayedApps = categoryApps.length > 10
                      ? categoryApps.sublist(0, 10)
                      : categoryApps;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      HListHeader(
                        title: category,
                        onTap: () => _openCategoryViewer(context, category),
                        subtitle: categoryApps.isNotEmpty
                            ? AppLocalizations.of(
                                context,
                              )!.section_app_count(categoryApps.length)
                            : null,
                        trailing: IconButton(
                          onPressed: () =>
                              _openCategoryViewer(context, category),
                          icon: const Icon(SolarIconsOutline.arrowRight),
                        ),
                      ),
                      if (isCategoryLoading) ...[
                        const SizedBox(height: 160),
                        const Center(
                          child: M3EContainedLoadingIndicator(),
                        ),
                      ] else if (isCategoryError) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.failed_to_load_apps,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  appProvider.categoryApps.remove(category);
                                  appProvider.fetchAppsByCategory(category);
                                },
                                child: Text(
                                  AppLocalizations.of(context)!.retry,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ] else if (categoryApps.isEmpty) ...[
                        SizedBox(
                          height: 160,
                          child: Center(
                            child: Text(
                              AppLocalizations.of(
                                context,
                              )!.no_apps_in_category(category),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ] else ...[
                        SizedBox(
                          height: 200,
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: GridView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 8,
                                      crossAxisSpacing: 8,
                                      childAspectRatio: 0.3,
                                    ),
                                itemCount:
                                    displayedApps.length +
                                    (categoryApps.length > 10 ? 1 : 0),
                                itemBuilder: (context, itemIndex) {
                                  if (itemIndex < displayedApps.length) {
                                    final app = displayedApps[itemIndex];
                                    final heroTag =
                                        'category_${category}_$itemIndex';
                                    return AppListItem(
                                      key: ValueKey(app.packageName),
                                      app: app,
                                      heroTag: heroTag,
                                      showInstallStatus: false,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                AppDetailsScreen(
                                                  app: app,
                                                  heroTag: heroTag,
                                                ),
                                          ),
                                        );
                                      },
                                    ).animate().fadeIn(
                                      duration: 300.ms,
                                      delay: (50 * itemIndex).ms,
                                    );
                                  }
                                  return _buildShowMoreCard(context, category);
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                }, childCount: categories.length * 2 - 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
