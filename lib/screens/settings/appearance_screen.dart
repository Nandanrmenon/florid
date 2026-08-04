import 'package:dynamic_color/dynamic_color.dart';
import 'package:florid/l10n/app_localizations.dart';
import 'package:florid/providers/settings_provider.dart';
import 'package:florid/widgets/list_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hornbill/hornbill.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final localizations = AppLocalizations.of(context)!;
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return DynamicColorBuilder(
          builder: (lightDynamic, darkDynamic) {
            final dynamicColorSupported =
                lightDynamic != null || darkDynamic != null;
            return Scaffold(
              body: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    floating: true,
                    leading: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(SolarIconsOutline.altArrowLeft),
                    ),
                    title: Text(localizations.appearance),
                  ),
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
                              HListHeader(title: localizations.theme_mode),
                              HRadioListView(
                                items: [
                                  HRadioListItemData<ThemeMode>(
                                    title: localizations.follow_system_theme,
                                    subtitle: '',
                                    value: ThemeMode.system,
                                    suffix: Icon(SolarIconsBold.devices),
                                  ),
                                  HRadioListItemData<ThemeMode>(
                                    title: localizations.light_theme,
                                    subtitle: '',
                                    value: ThemeMode.light,
                                    suffix: Icon(SolarIconsBold.sun),
                                  ),
                                  HRadioListItemData<ThemeMode>(
                                    title: localizations.dark_theme,
                                    subtitle: '',
                                    value: ThemeMode.dark,
                                    suffix: Icon(SolarIconsBold.moonStars),
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
                            spacing: 4.0,
                            children: [
                              HListHeader(title: localizations.dynamic_color),
                              if (dynamicColorSupported)
                                HListView(
                                  items: [
                                    HListItemData(
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
                                )
                              else
                                HListView(
                                  items: [
                                    HListItemData(
                                      title:
                                          'Dynamic color is not supported on this device',
                                      subtitle:
                                          'Use the theme color palette below instead.',
                                      onTap: () {},
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          if (!settings.dynamicColorEnabled)
                            Column(
                                  spacing: 4,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    HListHeader(
                                      title: 'Theme color',
                                      subtitle:
                                          'Pick a custom accent color when dynamic color is disabled',
                                    ),
                                    Card(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0,
                                          vertical: 12.0,
                                        ),
                                        child: GridView.count(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          crossAxisCount: 4,
                                          padding: EdgeInsets.zero,
                                          crossAxisSpacing: 12.0,
                                          mainAxisSpacing: 12.0,
                                          childAspectRatio: 1,
                                          children: SettingsProvider.themeColors.map((
                                            color,
                                          ) {
                                            final selected =
                                                color == settings.themeColor;
                                            return GestureDetector(
                                              onTap: () {
                                                settings.setThemeColor(color);
                                              },
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 300,
                                                ),
                                                width: 44,
                                                height: 44,
                                                decoration: BoxDecoration(
                                                  color: color,
                                                  borderRadius: selected
                                                      ? BorderRadius.circular(8)
                                                      : BorderRadius.circular(
                                                          50,
                                                        ),
                                                  border: Border.all(
                                                    color: selected
                                                        ? Theme.of(context)
                                                              .colorScheme
                                                              .primaryFixedDim
                                                        : Colors.transparent,
                                                    width: 4,
                                                  ),
                                                ),
                                                child: selected
                                                    ? Icon(
                                                        SolarIconsBold
                                                            .checkSquare,
                                                        color: isDarkMode
                                                            ? Theme.of(context)
                                                                  .colorScheme
                                                                  .onPrimaryContainer
                                                            : Theme.of(context)
                                                                  .colorScheme
                                                                  .onPrimary,
                                                      )
                                                    : null,
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                                .animate()
                                .fade(
                                  duration: const Duration(milliseconds: 300),
                                )
                                .moveY(
                                  begin: -50,
                                  duration: const Duration(milliseconds: 300),
                                ),
                          Column(
                            spacing: 4.0,
                            children: [
                              HListHeader(title: localizations.other),
                              HListView(
                                items: [
                                  HListItemData(
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
                                  HListItemData(
                                    title: localizations.show_monthly_top_apps,
                                    onTap: () {
                                      settings.setShowMonthlyTopApps(
                                        !settings.showMonthlyTopApps,
                                      );
                                    },
                                    suffix: Switch(
                                      value: settings.showMonthlyTopApps,
                                      onChanged: (value) {
                                        settings.setShowMonthlyTopApps(value);
                                      },
                                    ),
                                  ),
                                  HListItemData(
                                    title: 'Show navigation labels',
                                    onTap: () {
                                      settings.setShowNavigationLabels(
                                        !settings.showNavigationLabels,
                                      );
                                    },
                                    suffix: Switch(
                                      value: settings.showNavigationLabels,
                                      onChanged: (value) {
                                        settings.setShowNavigationLabels(value);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          HListView(
                            items: [
                              HListItemData(
                                leading: ListIcon(iconData: Symbols.feedback),
                                title: localizations.feedback_on_florid_theme,
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
