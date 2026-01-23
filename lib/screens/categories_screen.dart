import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import 'category_apps_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with AutomaticKeepAliveClientMixin {
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
    appProvider.fetchCategories();
  }

  Future<void> _onRefresh() async {
    final appProvider = context.read<AppProvider>();
    await appProvider.fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final state = appProvider.categoriesState;
        final categories = appProvider.categories;
        final error = appProvider.categoriesError;
        return _buildBody(state, categories, error);
      },
    );
  }

  Widget _buildBody(
    LoadingState state,
    List<String> categories,
    String? error,
  ) {
    if (state == LoadingState.loading && categories.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(year2023: false),
            SizedBox(height: 16),
            Text('Loading categories...'),
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
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (categories.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Symbols.category, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No categories found'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return _CategoryCard(
            category: category,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CategoryAppsScreen(category: category),
                ),
              );
            },
          ).animate().fadeIn(duration: 300.ms, delay: (10 * index).ms);
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'ai chat':
        return Symbols.robot_2;
      case 'app store & updater':
        return Symbols.store;
      case 'bookmark':
        return Symbols.bookmark;
      case 'browser':
        return Symbols.globe;
      case 'calculator':
        return Symbols.calculate;
      case 'calendar & agenda':
        return Symbols.calendar_clock;
      case 'cloud storage & file sync':
        return Symbols.cloud;
      case 'dns & hosts':
        return Symbols.dns;
      case 'ebook reader':
        return Symbols.book;
      case 'draw':
        return Symbols.draw;
      case 'email':
        return Symbols.email;
      case 'file encryption & vault':
        return Symbols.encrypted;
      case 'file transfer':
        return Symbols.drive_folder_upload;
      case 'finance manager':
        return Symbols.finance;
      case 'forum':
        return Symbols.forum;
      case 'gallery':
        return Symbols.photo_library;
      case 'habit tracker':
        return Symbols.fitness_center;
      case 'icon pack':
        return Symbols.apps;
      case 'keyboard & ime':
        return Symbols.keyboard;
      case 'launcher':
        return Symbols.home;
      case 'local media player':
        return Symbols.play_circle;
      case 'location tracker & sharer':
        return Symbols.gps_fixed;
      case 'messaging':
        return Symbols.message;
      case 'music practice tool':
        return Symbols.music_note;
      case 'news':
        return Symbols.newspaper;
      case 'note':
        return Symbols.note;
      case 'online media player':
        return Symbols.connected_tv;
      case 'pass wallet':
        return Symbols.passkey;
      case 'password & 2fa':
        return Symbols.password_2;
      case 'games':
        return Symbols.sports_esports;
      case 'multimedia':
        return Symbols.perm_media;
      case 'internet':
        return Symbols.language;
      case 'system':
        return Symbols.settings;
      case 'phone & sms':
        return Symbols.phone;
      case 'development':
        return Symbols.code;
      case 'office':
        return Symbols.business;
      case 'graphics':
        return Symbols.palette;
      case 'security':
        return Symbols.security;
      case 'reading':
        return Symbols.menu_book;
      case 'science & education':
        return Symbols.school;
      case 'sports & health':
        return Symbols.fitness_center;
      case 'navigation':
        return Symbols.navigation;
      case 'money':
        return Symbols.attach_money;
      case 'writing':
        return Symbols.edit;
      case 'time':
        return Symbols.schedule;
      case 'theming':
        return Symbols.palette;
      case 'connectivity':
        return Symbols.wifi;
      default:
        return Symbols.category;
    }
  }

  Color _getCategoryColor(String category) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
    ];

    return colors[category.hashCode % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = _getCategoryColor(category);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: categoryColor.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            spacing: 8,
            children: [
              Icon(_getCategoryIcon(category), size: 32, color: categoryColor),
              Expanded(
                child: Text(
                  category,
                  style: theme.textTheme.titleSmall?.copyWith(
                    // fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
