import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';

/// Florid style custom TabBar widget
/// Theme-aware TabBar that chooses Florid or Material style based on settings
class FTabBar extends StatelessWidget {
  const FTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTabChanged,
    this.floridPadding = const EdgeInsets.symmetric(horizontal: 16.0),
  });

  final List<FloridTabBarItem> items;
  final int currentIndex;
  final Function(int) onTabChanged;
  final EdgeInsets floridPadding;

  @override
  Widget build(BuildContext context) {
    final themeStyle = context.watch<SettingsProvider>().themeStyle;

    if (themeStyle == ThemeStyle.florid) {
      return Padding(
        padding: floridPadding,
        child: FloridTabBar(
          items: items,
          currentIndex: currentIndex,
          onTabChanged: onTabChanged,
        ),
      );
    }

    return MaterialTabBar(
      items: items,
      currentIndex: currentIndex,
      onTabChanged: onTabChanged,
    );
  }
}

/// Florid style custom TabBar widget
class FloridTabBar extends StatelessWidget {
  const FloridTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTabChanged,
  });

  final List<FloridTabBarItem> items;
  final int currentIndex;
  final Function(int) onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(24),
      shadowColor: Colors.black.withOpacity(0.3),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Row(
          children: List.generate(
            items.length,
            (index) => Expanded(
              child: _FloridTabBarItem(
                item: items[index],
                isSelected: currentIndex == index,
                onTap: () => onTabChanged(index),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloridTabBarItem extends StatelessWidget {
  const _FloridTabBarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final FloridTabBarItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              fill: 1,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              item.label,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Material style custom TabBar widget
class MaterialTabBar extends StatelessWidget {
  const MaterialTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTabChanged,
  });

  final List<FloridTabBarItem> items;
  final int currentIndex;
  final Function(int) onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: List.generate(
          items.length,
          (index) => Expanded(
            child: _MaterialTabBarItem(
              item: items[index],
              isSelected: currentIndex == index,
              onTap: () => onTabChanged(index),
            ),
          ),
        ),
      ),
    );
  }
}

class _MaterialTabBarItem extends StatelessWidget {
  const _MaterialTabBarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final FloridTabBarItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            item.icon,
            fill: isSelected ? 1 : 0,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          if (isSelected)
            Container(
              height: 3,
              width: 30,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            )
          else
            const SizedBox(height: 3),
        ],
      ),
    );
  }
}

/// Model for TabBar items
class FloridTabBarItem {
  const FloridTabBarItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
