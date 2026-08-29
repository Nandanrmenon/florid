import 'package:florid/providers/settings_provider.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

/// Theme-aware TabBar using Flutter's built-in TabBar.
/// Switches styling based on user's selected theme (Material or Florid).
class FTabBar extends StatelessWidget implements PreferredSizeWidget {
  const FTabBar({
    super.key,
    required this.items,
    required this.onTabChanged,
    required this.controller,
    this.isScrollable = false,
    this.showBadge = false,
    this.badgeText = '',
  });

  final List<FloridTabBarItem> items;
  final Function(int) onTabChanged;
  final TabController controller;
  final bool isScrollable;
  final bool showBadge;
  final String badgeText;

  // Give AppBar a consistent height hint; actual height adjusts inside.
  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    // Listen so the TabBar updates when the theme style changes.
    final settings = context.watch<SettingsProvider>();
    final isFlorid = settings.themeStyle == ThemeStyle.florid;
    final isDarkKnight = settings.themeStyle == ThemeStyle.darkKnight;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final (
      indicator,
      indicatorSize,
      labelColor,
      unselectedColor,
      padding,
    ) = switch (settings.themeStyle) {
      ThemeStyle.florid => (
        BoxDecoration(
          color: isDark
              ? Theme.of(context).colorScheme.surfaceContainerHigh
              : Theme.of(context).colorScheme.surfaceBright,
          borderRadius: BorderRadius.circular(99),
        ),
        TabBarIndicatorSize.tab,
        Theme.of(context).colorScheme.primary,
        Theme.of(context).colorScheme.onSurfaceVariant,
        const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
      ),
      ThemeStyle.darkKnight => (
        null,
        TabBarIndicatorSize.label,
        null,
        Theme.of(context).colorScheme.onSurfaceVariant,
        null,
      ),
      _ => (
        null,
        TabBarIndicatorSize.label,
        null,
        Theme.of(context).colorScheme.onSurfaceVariant,
        EdgeInsets.zero,
      ),
    };

    return Container(
      width: double.infinity,
      padding: padding,
      child: Material(
        borderRadius: isFlorid ? BorderRadius.circular(99) : null,
        color: isFlorid
            ? Theme.of(context).colorScheme.surfaceContainerLow
            : Colors.transparent,
        clipBehavior: isFlorid ? Clip.antiAlias : Clip.none,
        child: TabBar(
          controller: controller,
          indicator: indicator,
          indicatorSize: indicatorSize,
          indicatorAnimation: TabIndicatorAnimation.elastic,
          dividerHeight: isDarkKnight ? 1 : 0,
          labelColor: labelColor,
          unselectedLabelColor: unselectedColor,
          splashBorderRadius: isFlorid
              ? BorderRadius.circular(99)
              : BorderRadius.zero,
          onTap: onTabChanged,
          isScrollable: isScrollable,
          tabAlignment: isScrollable ? TabAlignment.start : null,
          padding: isFlorid ? const EdgeInsets.all(4) : null,
          tabs: items.map((item) {
            return Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (item.icon != null) Icon(item.icon, fill: 1, size: 18),
                  if (item.icon != null) SizedBox(width: 8),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (showBadge && item.badgeCount > 0)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      child: CircleAvatar(
                        radius: 11,
                        child: Text(
                          item.badgeCount.toString(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
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
  const FloridTabBarItem({this.icon, required this.label, this.badgeCount = 0});

  final IconData? icon;
  final String label;
  final int badgeCount;
}
