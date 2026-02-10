import 'package:flutter/material.dart';

class MListItemData {
  final String title;
  final String? subtitle;
  final Function onTap;
  final Widget? leading;
  final Widget? suffix;
  final bool selected;

  MListItemData({
    required this.title,
    this.subtitle,
    required this.onTap,
    this.leading,
    this.suffix,
    this.selected = false,
  });
}

class MListHeader extends StatefulWidget {
  final String title;
  final IconData? icon;
  const MListHeader({super.key, required this.title, this.icon});

  @override
  State<MListHeader> createState() => _MListHeaderState();
}

class _MListHeaderState extends State<MListHeader> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (widget.icon != null) Icon(widget.icon, size: 20),
          if (widget.icon != null) SizedBox(width: 8),
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class MListView extends StatelessWidget {
  final List items;
  final bool? enableScroll;
  final bool? shrinkWrap;
  const MListView({
    super.key,
    required this.items,
    this.enableScroll,
    this.shrinkWrap,
  });

  @override
  Widget build(BuildContext context) {
    // Use theme as part of key to force rebuild when theme changes
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ListView.separated(
      key: ValueKey(isDarkMode),
      shrinkWrap: shrinkWrap != null ? false : true,
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      physics: enableScroll != null
          ? AlwaysScrollableScrollPhysics()
          : NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        bool isLastItem(int index) {
          return index == items.length - 1;
        }

        return ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: index == 0 ? Radius.circular(16.0) : Radius.circular(4.0),
            topRight: index == 0 ? Radius.circular(16.0) : Radius.circular(4.0),
            bottomLeft: isLastItem(index)
                ? const Radius.circular(16.0)
                : const Radius.circular(4.0),
            bottomRight: isLastItem(index)
                ? const Radius.circular(16.0)
                : const Radius.circular(4.0),
          ),
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainer,
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding: EdgeInsets.only(left: 16.0, right: 16.0),
              title: Text(items[index].title),
              leading: items[index].leading,
              subtitle:
                  items[index].subtitle != null &&
                      items[index].subtitle!.isNotEmpty
                  ? Text(items[index].subtitle!)
                  : null,
              onTap: () => items[index].onTap(),
              trailing: items[index].suffix,
              selected: items[index].selected,
            ),
          ),
        );
      },
      separatorBuilder: (context, index) {
        return SizedBox(height: 4);
      },
    );
  }
}

class MListViewBuilder extends StatelessWidget {
  final int itemCount;
  final MListItemData Function(int index) itemBuilder;
  final bool? enableScroll;
  final bool? shrinkWrap;

  const MListViewBuilder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.enableScroll,
    this.shrinkWrap,
  });

  @override
  Widget build(BuildContext context) {
    // Use theme as part of key to force rebuild when theme changes
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ListView.separated(
      key: ValueKey(isDarkMode),
      shrinkWrap: shrinkWrap != null ? false : true,
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      physics: enableScroll != null
          ? AlwaysScrollableScrollPhysics()
          : NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        final item = itemBuilder(index);
        final isLastItem = index == itemCount - 1;

        return ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: index == 0 ? Radius.circular(16.0) : Radius.circular(4.0),
            topRight: index == 0 ? Radius.circular(16.0) : Radius.circular(4.0),
            bottomLeft: isLastItem
                ? const Radius.circular(16.0)
                : const Radius.circular(4.0),
            bottomRight: isLastItem
                ? const Radius.circular(16.0)
                : const Radius.circular(4.0),
          ),
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainer,
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding: EdgeInsets.only(left: 16.0, right: 16.0),
              title: Text(item.title),
              leading: item.leading,
              subtitle: item.subtitle != null && item.subtitle!.isNotEmpty
                  ? Text(item.subtitle!)
                  : null,
              onTap: () => item.onTap(),
              trailing: item.suffix,
              selected: item.selected,
            ),
          ),
        );
      },
      separatorBuilder: (context, index) {
        return SizedBox(height: 4);
      },
    );
  }
}

class MRadioListItemData<T> {
  final String title;
  final String subtitle;
  final T value;
  final Widget? leading;
  final Widget? suffix;

  MRadioListItemData({
    required this.title,
    required this.subtitle,
    required this.value,
    this.leading,
    this.suffix,
  });
}

class MRadioListView<T> extends StatelessWidget {
  final List<MRadioListItemData<T>> items;
  final T groupValue;
  final Function(T) onChanged;
  final bool? enableScroll;
  final bool? shrinkWrap;

  const MRadioListView({
    super.key,
    required this.items,
    required this.groupValue,
    required this.onChanged,
    this.enableScroll,
    this.shrinkWrap,
  });

  @override
  Widget build(BuildContext context) {
    // Use theme as part of key to force rebuild when theme changes
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ListView.separated(
      key: ValueKey(isDarkMode),
      shrinkWrap: shrinkWrap != null ? false : true,
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      physics: enableScroll != null
          ? AlwaysScrollableScrollPhysics()
          : NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        bool isLastItem(int index) {
          return index == items.length - 1;
        }

        return ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: index == 0 ? Radius.circular(16.0) : Radius.circular(4.0),
            topRight: index == 0 ? Radius.circular(16.0) : Radius.circular(4.0),
            bottomLeft: isLastItem(index)
                ? const Radius.circular(16.0)
                : const Radius.circular(4.0),
            bottomRight: isLastItem(index)
                ? const Radius.circular(16.0)
                : const Radius.circular(4.0),
          ),
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainer,
            clipBehavior: Clip.antiAlias,
            child: RadioListTile<T>(
              contentPadding: EdgeInsets.only(left: 16.0, right: 4.0),
              title: Text(items[index].title),
              subtitle: items[index].subtitle.isNotEmpty
                  ? Text(items[index].subtitle)
                  : null,
              value: items[index].value,
              groupValue: groupValue,
              onChanged: (value) {
                if (value != null) {
                  onChanged(value);
                }
              },
              secondary: items[index].suffix,
            ),
          ),
        );
      },
      separatorBuilder: (context, index) {
        return SizedBox(height: 4);
      },
    );
  }
}

class MCheckboxListItemData {
  final String title;
  final String subtitle;
  final bool value;
  final Widget? leading;
  final Widget? suffix;

  MCheckboxListItemData({
    required this.title,
    required this.subtitle,
    required this.value,
    this.leading,
    this.suffix,
  });
}

class MCheckboxListView extends StatelessWidget {
  final List<MCheckboxListItemData> items;
  final Function(int, bool) onChanged;
  final bool? enableScroll;
  final bool? shrinkWrap;

  const MCheckboxListView({
    super.key,
    required this.items,
    required this.onChanged,
    this.enableScroll,
    this.shrinkWrap,
  });

  @override
  Widget build(BuildContext context) {
    // Use theme as part of key to force rebuild when theme changes
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ListView.separated(
      key: ValueKey(isDarkMode),
      shrinkWrap: shrinkWrap != null ? false : true,
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      physics: enableScroll != null
          ? AlwaysScrollableScrollPhysics()
          : NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        bool isLastItem(int index) {
          return index == items.length - 1;
        }

        return ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: index == 0 ? Radius.circular(16.0) : Radius.circular(4.0),
            topRight: index == 0 ? Radius.circular(16.0) : Radius.circular(4.0),
            bottomLeft: isLastItem(index)
                ? const Radius.circular(16.0)
                : const Radius.circular(4.0),
            bottomRight: isLastItem(index)
                ? const Radius.circular(16.0)
                : const Radius.circular(4.0),
          ),
          child: Material(
            clipBehavior: Clip.antiAlias,
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: CheckboxListTile(
              contentPadding: EdgeInsets.only(left: 16.0, right: 4.0),
              title: Text(items[index].title),
              subtitle: items[index].subtitle.isNotEmpty
                  ? Text(items[index].subtitle)
                  : null,
              value: items[index].value,
              onChanged: (value) {
                if (value != null) {
                  onChanged(index, value);
                }
              },
              secondary: items[index].suffix,
            ),
          ),
        );
      },
      separatorBuilder: (context, index) {
        return SizedBox(height: 4);
      },
    );
  }
}

class MCheckboxListViewBuilder extends StatelessWidget {
  final int itemCount;
  final MCheckboxListItemData Function(int index) itemBuilder;
  final Function(int, bool) onChanged;
  final bool? enableScroll;
  final bool? shrinkWrap;

  const MCheckboxListViewBuilder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.onChanged,
    this.enableScroll,
    this.shrinkWrap,
  });

  @override
  Widget build(BuildContext context) {
    // Use theme as part of key to force rebuild when theme changes
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ListView.separated(
      key: ValueKey(isDarkMode),
      shrinkWrap: shrinkWrap != null ? false : true,
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      physics: enableScroll != null
          ? AlwaysScrollableScrollPhysics()
          : NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        final item = itemBuilder(index);
        final isLastItem = index == itemCount - 1;

        return ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: index == 0 ? Radius.circular(16.0) : Radius.circular(4.0),
            topRight: index == 0 ? Radius.circular(16.0) : Radius.circular(4.0),
            bottomLeft: isLastItem
                ? const Radius.circular(16.0)
                : const Radius.circular(4.0),
            bottomRight: isLastItem
                ? const Radius.circular(16.0)
                : const Radius.circular(4.0),
          ),
          child: Material(
            clipBehavior: Clip.antiAlias,
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: CheckboxListTile(
              contentPadding: EdgeInsets.only(left: 16.0, right: 4.0),
              title: Text(item.title),
              subtitle: item.subtitle.isNotEmpty ? Text(item.subtitle) : null,
              value: item.value,
              onChanged: (value) {
                if (value != null) {
                  onChanged(index, value);
                }
              },
              secondary: item.suffix,
            ),
          ),
        );
      },
      separatorBuilder: (context, index) {
        return SizedBox(height: 4);
      },
    );
  }
}
