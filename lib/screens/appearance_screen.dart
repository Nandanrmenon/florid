import 'package:dynamic_color/dynamic_color.dart';
import 'package:florid/l10n/app_localizations.dart';
import 'package:florid/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/m_list.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final localizations = AppLocalizations.of(context)!;
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
                          Column(
                            spacing: 4,
                            children: [
                              MListHeader(title: localizations.theme_style),
                              MRadioListView(
                                items: [
                                  MRadioListItemData<ThemeStyle>(
                                    title: localizations.material_style,
                                    subtitle: '',
                                    value: ThemeStyle.material,
                                  ),
                                  MRadioListItemData<ThemeStyle>(
                                    title: localizations.dark_knight,
                                    subtitle: '',
                                    value: ThemeStyle.darkKnight,
                                    suffix: Container(
                                      margin: const EdgeInsets.only(right: 8.0),
                                      child: Material(
                                        color: Theme.of(
                                          context,
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
                                                context,
                                              ).colorScheme.onSecondary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  MRadioListItemData<ThemeStyle>(
                                    title: localizations.florid_style,
                                    subtitle: '',
                                    value: ThemeStyle.florid,
                                  ),
                                ],
                                groupValue: settings.themeStyle,
                                onChanged: (style) {
                                  settings.setThemeStyle(style);
                                },
                              ),
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
