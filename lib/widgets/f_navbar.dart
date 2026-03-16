import 'dart:ui';

import 'package:florid/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

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
    final settings = context.watch<SettingsProvider>();
    final isFlorid = settings.themeStyle == ThemeStyle.florid;
    final isDarkKnight = settings.themeStyle == ThemeStyle.darkKnight;

    return SafeArea(
      top: false,
      child: Padding(
        padding: margin,
        child: Row(
          children: [
            // Single builder for both Florid and DarkKnight styles.
            () {
              Widget buildMaterialChild(Color color, {double alpha = 1.0}) {
                final effectiveColor = alpha == 1.0
                    ? color
                    : color.withValues(alpha: alpha);
                Widget innerMaterial() {
                  return Material(
                    color: effectiveColor,
                    elevation: 0.5,
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
                                child: Tooltip(
                                  message: item.label,
                                  preferBelow: false,
                                  child: InkWell(
                                    onTap: () => onChanged(index),
                                    borderRadius: BorderRadius.circular(99),
                                    child: SizedBox(
                                      height: double.infinity,
                                      child: Row(
                                        spacing: 16.0,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Flexible(
                                            child: IconTheme(
                                              data: IconThemeData(
                                                color: selected
                                                    ? selectedColor
                                                    : unselectedColor,
                                              ),
                                              child: selected
                                                  ? item.selectedIcon
                                                  : item.icon,
                                            ),
                                          ),
                                          if (selected)
                                            Flexible(
                                              child:
                                                  AnimatedDefaultTextStyle(
                                                        duration:
                                                            const Duration(
                                                              milliseconds: 180,
                                                            ),
                                                        curve: Curves.easeOut,
                                                        style: isFlorid
                                                            ? TextStyle(
                                                                color: selected
                                                                    ? selectedColor
                                                                    : unselectedColor,
                                                                fontSize: 14,
                                                                fontVariations: [
                                                                  FontVariation(
                                                                    'ROND',
                                                                    100,
                                                                  ),
                                                                ],
                                                              )
                                                            : const TextStyle(
                                                                inherit: true,
                                                              ),
                                                        child: Text(
                                                          item.label,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      )
                                                      .animate()
                                                      .fadeIn(duration: 180.ms)
                                                      .slideX(
                                                        begin: 0.5,
                                                        end: 0,
                                                        duration: 180.ms,
                                                        curve: Curves.easeOut,
                                                      ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  );
                }

                // For darkKnight we apply a blurred backdrop; otherwise return material directly
                if (isDarkKnight) {
                  return Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                          child: innerMaterial(),
                        ),
                      ),
                    ),
                  );
                }

                return Expanded(child: innerMaterial());
              }

              // Decide which style to render. Florid uses baseColor, DarkKnight uses a translucent base.
              if (isFlorid) return buildMaterialChild(baseColor);
              if (isDarkKnight) {
                return buildMaterialChild(baseColor, alpha: 0.5);
              }
              return const SizedBox.shrink();
            }(),
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
