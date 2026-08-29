import 'package:material_ui/material_ui.dart';
import 'package:iconify_flutter/iconify_flutter.dart';

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
    return Material(
      color: Theme.of(context).colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          widget.iconData,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class SocialListIcon extends StatefulWidget {
  final String icon;
  final bool? primary;

  const SocialListIcon({super.key, required this.icon, this.primary = false});

  @override
  State<SocialListIcon> createState() => _SocialListIconState();
}

class _SocialListIconState extends State<SocialListIcon> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Iconify(
          widget.icon,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
