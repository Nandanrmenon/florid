import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FNavBar extends StatelessWidget {
  const FNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onChanged,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 12),
    this.height = 64,
  });

  final List<FloridNavBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final EdgeInsets margin;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final baseColor = scheme.primary;
    final accentColor = scheme.surface;
    final selectedColor = scheme.onSurface;
    final unselectedColor = scheme.onPrimary;

    return SafeArea(
      top: false,
      child: Padding(
        padding: margin,
        child: Material(
          color: baseColor,
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
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      decoration: BoxDecoration(
                        color: selected ? accentColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: InkWell(
                        onTap: () => onChanged(index),
                        borderRadius: BorderRadius.circular(99),
                        child: SizedBox(
                          height: double.infinity,
                          child: Row(
                            spacing: 8.0,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconTheme(
                                data: IconThemeData(
                                  color: selected
                                      ? selectedColor
                                      : unselectedColor,
                                ),
                                child: selected ? item.selectedIcon : item.icon,
                              ).animate().fadeIn(duration: 180.ms),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOut,
                                style: TextStyle(
                                  color: selected
                                      ? selectedColor
                                      : unselectedColor,
                                  fontSize: 14,
                                  fontVariations: [FontVariation('ROND', 100)],
                                ),
                                child: Text(
                                  item.label,
                                ).animate().fadeIn(duration: 180.ms),
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
