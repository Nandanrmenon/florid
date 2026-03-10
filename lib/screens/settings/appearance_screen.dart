import 'package:dynamic_color/dynamic_color.dart';
import 'package:florid/l10n/app_localizations.dart';
import 'package:florid/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../themes/app_themes.dart';
import '../../widgets/m_list.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final localizations = AppLocalizations.of(context)!;
        final useDynamic = settings.dynamicColorEnabled;
        return DynamicColorBuilder(
          builder: (lightDynamic, darkDynamic) {
            final dynamicColorSupported =
                lightDynamic != null || darkDynamic != null;
            return Scaffold(
              body: CustomScrollView(
                slivers: [
                  SliverAppBar.large(title: Text(localizations.appearance)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 16,
                        children: [
                          Column(
                            spacing: 4,
                            children: [
                              MListHeader(title: localizations.theme_mode),
                              MRadioListView(
                                items: [
                                  MRadioListItemData<ThemeMode>(
                                    title: localizations.follow_system_theme,
                                    subtitle: '',
                                    value: ThemeMode.system,
                                    suffix: Icon(Symbols.settings_suggest),
                                  ),
                                  MRadioListItemData<ThemeMode>(
                                    title: localizations.light_theme,
                                    subtitle: '',
                                    value: ThemeMode.light,
                                    suffix: Icon(Symbols.light_mode_rounded),
                                  ),
                                  MRadioListItemData<ThemeMode>(
                                    title: localizations.dark_theme,
                                    subtitle: '',
                                    value: ThemeMode.dark,
                                    suffix: Icon(Symbols.dark_mode_rounded),
                                  ),
                                ],
                                groupValue: settings.themeMode,
                                onChanged: (mode) {
                                  settings.setThemeMode(mode);
                                },
                              ),
                            ],
                          ),
                          if (dynamicColorSupported)
                            Column(
                              spacing: 4,
                              children: [
                                MListHeader(title: localizations.dynamic_color),
                                MListView(
                                  items: [
                                    MListItemData(
                                      leading: Icon(Symbols.palette),
                                      title: localizations.material_you_dynamic,
                                      subtitle: localizations
                                          .use_system_colors_supported_android,
                                      onTap: () {
                                        settings.setDynamicColorEnabled(
                                          !settings.dynamicColorEnabled,
                                        );
                                      },
                                      suffix: Switch(
                                        value: settings.dynamicColorEnabled,
                                        onChanged: (value) {
                                          settings.setDynamicColorEnabled(
                                            value,
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          MListView(
                            items: [
                              MListItemData(
                                leading: Icon(Symbols.style),
                                title: localizations.theme_style,
                                subtitle: '',
                                suffix: Icon(Symbols.chevron_right),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ThemeStyleScreen(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            spacing: 4,
                            children: [
                              Column(
                                spacing: 4.0,
                                children: [
                                  MListHeader(title: localizations.other),
                                  MListView(
                                    items: [
                                      MListItemData(
                                        title: localizations.show_whats_new,
                                        onTap: () {
                                          settings.setShowWhatsNew(
                                            !settings.showWhatsNew,
                                          );
                                        },
                                        suffix: Switch(
                                          value: settings.showWhatsNew,
                                          onChanged: (value) {
                                            settings.setShowWhatsNew(value);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              MListView(
                                items: [
                                  MListItemData(
                                    leading: Icon(Symbols.feedback),
                                    title:
                                        localizations.feedback_on_florid_theme,
                                    subtitle: localizations
                                        .help_improve_florid_theme_feedback,
                                    onTap: () {
                                      // Keep the same URL used in Settings.
                                      launchUrl(
                                        Uri.parse(
                                          'https://github.com/Nandanrmenon/florid/discussions/5',
                                        ),
                                      );
                                    },
                                    suffix: Icon(Symbols.open_in_new),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class ThemeStyleScreen extends StatefulWidget {
  const ThemeStyleScreen({super.key});

  @override
  State<ThemeStyleScreen> createState() => _ThemeStyleScreenState();
}

class _ThemeStyleScreenState extends State<ThemeStyleScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final localizations = AppLocalizations.of(context)!;
        final useDynamic = settings.dynamicColorEnabled;
        return DynamicColorBuilder(
          builder: (lightDynamic, darkDynamic) {
            return Scaffold(
              body: CustomScrollView(
                slivers: [
                  SliverAppBar.medium(title: Text(localizations.theme_style)),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: SafeArea(
                      child: Scrollbar(
                        scrollbarOrientation: ScrollbarOrientation.bottom,
                        interactive: true,
                        trackVisibility: true,
                        thumbVisibility: true,
                        radius: Radius.circular(20),
                        thickness: 8,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ThemeStylePreviewCard(
                                isSelected:
                                    settings.themeStyle == ThemeStyle.florid,
                                themeData:
                                    Theme.of(context).brightness ==
                                        Brightness.light
                                    ? AppThemes.floridLightTheme(
                                        colorScheme: useDynamic
                                            ? lightDynamic
                                            : null,
                                      )
                                    : AppThemes.floridDarkTheme(
                                        colorScheme: useDynamic
                                            ? darkDynamic
                                            : null,
                                      ),
                                onTap: () =>
                                    settings.setThemeStyle(ThemeStyle.florid),
                                headerBuilder: (previewContext) => Text(
                                  localizations.florid_style,
                                  style: Theme.of(previewContext)
                                      .textTheme
                                      .headlineSmall!
                                      .copyWith(
                                        fontFamily: 'Google Sans Flex',
                                        fontVariations: [
                                          FontVariation('wght', 700),
                                          FontVariation('ROND', 100),
                                          FontVariation('wdth', 125),
                                        ],
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              ThemeStylePreviewCard(
                                isSelected:
                                    settings.themeStyle == ThemeStyle.material,
                                themeData:
                                    Theme.of(context).brightness ==
                                        Brightness.light
                                    ? AppThemes.materialLightTheme(
                                        colorScheme: useDynamic
                                            ? lightDynamic
                                            : null,
                                      )
                                    : AppThemes.materialDarkTheme(
                                        colorScheme: useDynamic
                                            ? darkDynamic
                                            : null,
                                      ),
                                onTap: () =>
                                    settings.setThemeStyle(ThemeStyle.material),
                                headerBuilder: (previewContext) => Text(
                                  localizations.material_style,
                                  style: Theme.of(
                                    previewContext,
                                  ).textTheme.headlineSmall,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              ThemeStylePreviewCard(
                                isSelected:
                                    settings.themeStyle ==
                                    ThemeStyle.darkKnight,
                                themeData:
                                    Theme.of(context).brightness ==
                                        Brightness.light
                                    ? AppThemes.lightKnightTheme(
                                        colorScheme: useDynamic
                                            ? lightDynamic
                                            : null,
                                      )
                                    : AppThemes.lightKnightTheme(
                                        colorScheme: useDynamic
                                            ? darkDynamic
                                            : null,
                                      ),
                                onTap: () => settings.setThemeStyle(
                                  ThemeStyle.darkKnight,
                                ),
                                headerBuilder: (previewContext) => Column(
                                  spacing: 4.0,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      localizations.dark_knight,
                                      style: Theme.of(
                                        previewContext,
                                      ).textTheme.headlineSmall,
                                    ),
                                    Container(
                                      margin: const EdgeInsets.only(right: 8.0),
                                      child: Material(
                                        color: Theme.of(
                                          previewContext,
                                        ).colorScheme.secondary,
                                        borderRadius: BorderRadius.circular(
                                          99.0,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12.0,
                                            vertical: 2.0,
                                          ),
                                          child: Text(
                                            localizations.beta,
                                            style: TextStyle(
                                              color: Theme.of(
                                                previewContext,
                                              ).colorScheme.onSecondary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class ThemeStylePreviewCard extends StatelessWidget {
  const ThemeStylePreviewCard({
    super.key,
    required this.isSelected,
    required this.themeData,
    required this.onTap,
    required this.headerBuilder,
  });

  final bool isSelected;
  final ThemeData themeData;
  final VoidCallback onTap;
  final Widget Function(BuildContext context) headerBuilder;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: themeData,
      child: Builder(
        builder: (previewContext) {
          final colorScheme = Theme.of(previewContext).colorScheme;
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
              side: BorderSide(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant.withValues(alpha: 0.6),
                // width: isSelected ? 2.0 : 1.0,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: SizedBox(
                width: 280,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    // horizontal: 16.0,
                    // vertical: 24.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppBar(
                        title: Text('AppBar'),
                        actions: [
                          Icon(Symbols.search),
                          SizedBox(width: 8),
                          Icon(Symbols.more_vert),
                        ],
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            children: [
                              Chip(label: Text('Chip')),
                              SizedBox(height: 8),
                              Row(
                                spacing: 4.0,
                                children: [
                                  IconButton.filled(
                                    onPressed: () {},
                                    icon: Icon(Symbols.share),
                                  ),
                                  IconButton.filledTonal(
                                    onPressed: () {},
                                    icon: Icon(Symbols.share),
                                  ),
                                  FloatingActionButton.small(
                                    onPressed: () {},
                                    child: const Icon(Symbols.add),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const LinearProgressIndicator(value: 0.4),
                              const SizedBox(height: 8),
                              FilledButton(
                                onPressed: () {},
                                child: const Text('Button'),
                              ),
                              FilledButton.tonal(
                                onPressed: () {},
                                child: const Text('Button'),
                              ),
                              Switch(value: true, onChanged: (_) {}),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: headerBuilder(previewContext),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
