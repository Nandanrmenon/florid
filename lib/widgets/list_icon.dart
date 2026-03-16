import 'package:florid/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ListIcon extends StatefulWidget {
  final IconData iconData;
  final bool? primary;
  const ListIcon({super.key, required this.iconData, this.primary = false});

  @override
  State<ListIcon> createState() => _ListIconState();
}

class _ListIconState extends State<ListIcon> {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isFlorid = settings.themeStyle == ThemeStyle.florid;
    return Container(
      padding: isFlorid ? EdgeInsets.all(8) : EdgeInsets.zero,
      decoration: isFlorid
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 0.5,
              ),
              gradient: LinearGradient(
                colors: [
                  if (widget.primary == true)
                    Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.12)
                  else
                    Theme.of(context).colorScheme.surfaceContainerHigh,
                  if (widget.primary == true)
                    Theme.of(context).colorScheme.primary
                  else
                    Theme.of(context).colorScheme.surfaceContainer,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            )
          : null,
      child: Icon(
        widget.iconData,
        fill: 1,
        weight: 300,
        color: widget.primary == true
            ? Theme.of(context).colorScheme.onPrimary
            : null,
      ),
    );
  }
}
