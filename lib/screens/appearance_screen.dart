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
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar.large(title: Text('Appearance')),
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
                          MListHeader(title: 'Theme Mode'),
                          MRadioListView(
                            items: [
                              MRadioListItemData<ThemeMode>(
                                title: 'Follow system theme',
                                subtitle: '',
                                value: ThemeMode.system,
                                suffix: Icon(Symbols.settings_suggest),
                              ),
                              MRadioListItemData<ThemeMode>(
                                title: 'Light theme',
                                subtitle: '',
                                value: ThemeMode.light,
                                suffix: Icon(Symbols.light_mode_rounded),
                              ),
                              MRadioListItemData<ThemeMode>(
                                title: 'Dark theme',
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
                      Column(
                        spacing: 4,
                        children: [
                          MListHeader(title: 'Dynamic Color'),
                          MListView(
                            items: [
                              MListItemData(
                                leading: Icon(Symbols.palette),
                                title: 'Material You Dynamic',
                                subtitle:
                                    'Use system colors on supported Android devices',
                                onTap: () {
                                  settings.setDynamicColorEnabled(
                                    !settings.dynamicColorEnabled,
                                  );
                                },
                                suffix: Switch(
                                  value: settings.dynamicColorEnabled,
                                  onChanged: (value) {
                                    settings.setDynamicColorEnabled(value);
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
                          MListHeader(title: 'Theme Style'),
                          MRadioListView(
                            items: [
                              MRadioListItemData<ThemeStyle>(
                                title: 'Material style',
                                subtitle: '',
                                value: ThemeStyle.material,
                              ),
                              MRadioListItemData<ThemeStyle>(
                                title: 'Florid style',
                                subtitle: '',
                                suffix: Container(
                                  margin: const EdgeInsets.only(right: 8.0),
                                  child: Material(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                    borderRadius: BorderRadius.circular(99.0),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12.0,
                                        vertical: 2.0,
                                      ),
                                      child: Text(
                                        'Beta',
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                value: ThemeStyle.florid,
                              ),
                            ],
                            groupValue: settings.themeStyle,
                            onChanged: (style) {
                              settings.setThemeStyle(style);
                            },
                          ),
                          MListView(
                            items: [
                              MListItemData(
                                leading: Icon(Symbols.feedback),
                                title: 'Fedback on Florid theme',
                                subtitle:
                                    'Help improve the Florid theme by providing feedback',
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
  }
}
