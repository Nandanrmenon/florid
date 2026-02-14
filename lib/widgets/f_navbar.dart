import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FNavBar extends StatelessWidget {
  const FNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onChanged,
    this.fab,
    this.fabGap = 4,
    this.fabPadding = const EdgeInsets.only(left: 8),
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 12),
    this.height = 64,
  });

  final List<FloridNavBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final Widget? fab;
  final double fabGap;
  final EdgeInsets fabPadding;
  final EdgeInsets margin;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final baseColor = scheme.surfaceContainerHigh;
    final accentColor = scheme.primary.withValues(alpha: 0.2);
    final selectedColor = scheme.primary;
    final unselectedColor = scheme.onSurfaceVariant;

    return SafeArea(
      top: false,
      child: Padding(
        padding: margin,
        child: Row(
          children: [
            Expanded(
              child: Material(
                color: baseColor,
                elevation: 1,
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: height,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: List.generate(items.length, (index) {
                        final item = items[index];
                        final selected = index == currentIndex;
                        return Expanded(
                          flex: selected ? 2 : 1,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOut,
                            decoration: BoxDecoration(
                              color: selected
                                  ? accentColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: InkWell(
                              onTap: () => onChanged(index),
                              borderRadius: BorderRadius.circular(99),
                              child: SizedBox(
                                height: double.infinity,
                                child: Row(
                                  spacing: 16.0,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconTheme(
                                      data: IconThemeData(
                                        color: selected
                                            ? selectedColor
                                            : unselectedColor,
                                      ),
                                      child: selected
                                          ? item.selectedIcon
                                          : item.icon,
                                    ),

                                    if (selected)
                                      AnimatedDefaultTextStyle(
                                            duration: const Duration(
                                              milliseconds: 180,
                                            ),
                                            curve: Curves.easeOut,
                                            style: TextStyle(
                                              color: selected
                                                  ? selectedColor
                                                  : unselectedColor,
                                              fontSize: 14,
                                              fontVariations: [
                                                FontVariation('ROND', 100),
                                              ],
                                            ),
                                            child: Text(item.label),
                                          )
                                          .animate()
                                          .fadeIn(duration: 180.ms)
                                          .slideX(
                                            begin: 0.5,
                                            end: 0,
                                            duration: 180.ms,
                                            curve: Curves.easeOut,
                                          ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
            if (fab != null) ...[
              SizedBox(width: fabGap),
              Padding(padding: fabPadding, child: fab!),
            ],
          ],
        ),
      ),
    );
  }
}

class FloridNavBarItem {
  const FloridNavBarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final Widget icon;
  final Widget selectedIcon;
  final String label;
}
