import 'package:florid/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Theme-aware TabBar using Flutter's built-in TabBar.
/// Switches styling based on user's selected theme (Material or Florid).
class FTabBar extends StatelessWidget implements PreferredSizeWidget {
  const FTabBar({
    super.key,
    required this.items,
    required this.onTabChanged,
    required this.controller,
  });

  final List<FloridTabBarItem> items;
  final Function(int) onTabChanged;
  final TabController controller;

  // Give AppBar a consistent height hint; actual height adjusts inside.
  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    // Listen so the TabBar updates when the theme style changes.
    final settings = context.watch<SettingsProvider>();
    final isFlorid = settings.themeStyle == ThemeStyle.florid;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final indicator = isFlorid
        ? BoxDecoration(
            color: isDark
                ? Theme.of(context).colorScheme.surfaceContainer
                : Theme.of(context).colorScheme.surfaceBright,
            borderRadius: BorderRadius.circular(99),
          )
        : null;

    final labelColor = isFlorid
        ? Theme.of(context).colorScheme.onSurface
        : null;

    final unselectedColor = Theme.of(context).colorScheme.onSurfaceVariant;

    final padding = isFlorid
        ? const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0)
        : EdgeInsets.zero;

    return Padding(
      padding: padding,
      child: Material(
        borderRadius: isFlorid ? BorderRadius.circular(99) : null,
        color: isFlorid
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : Colors.transparent,
        child: TabBar(
          controller: controller,
          indicator: indicator,
          indicatorSize: isFlorid
              ? TabBarIndicatorSize.tab
              : TabBarIndicatorSize.label,
          dividerHeight: 0,
          labelColor: labelColor,
          unselectedLabelColor: unselectedColor,
          splashBorderRadius: isFlorid
              ? BorderRadius.circular(99)
              : BorderRadius.zero,
          onTap: onTabChanged,
          padding: isFlorid ? const EdgeInsets.all(4) : null,
          tabs: items.map((item) {
            return Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, fill: 1, size: 18),
                  const SizedBox(width: 8),
                  Text(item.label),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class FloridTabBarItem {
  const FloridTabBarItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
