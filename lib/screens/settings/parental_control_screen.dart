import 'dart:io';

import 'package:florid/l10n/app_localizations.dart';
import 'package:florid/providers/settings_provider.dart';
import 'package:florid/widgets/list_icon.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_m3shapes_extended/flutter_m3shapes_extended.dart';
import 'package:hornbill/hornbill.dart';
import 'package:local_auth/local_auth.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:solar_icons/solar_icons.dart';

class ParentalControlScreen extends StatefulWidget {
  const ParentalControlScreen({super.key});

  @override
  State<ParentalControlScreen> createState() => _ParentalControlScreenState();
}

class _ParentalControlScreenState extends State<ParentalControlScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> _authenticateForSettingsChange() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return true;
    }

    try {
      final supported = await _localAuth.isDeviceSupported();
      if (!supported) {
        return true;
      }

      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to change installation settings',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException {
      return false;
    }
  }

  Future<void> _setInstallAuthEnabledWithVerification(
    SettingsProvider settings,
    bool value,
  ) async {
    if (value == settings.installAuthEnabled) return;
    final authenticated = await _authenticateForSettingsChange();
    if (!authenticated || !mounted) return;
    await settings.setInstallAuthEnabled(value);
  }

  Future<void> _setInstallAuthPolicyWithVerification(
    SettingsProvider settings,
    InstallAuthPolicy value,
  ) async {
    if (value == settings.installAuthPolicy) return;
    final authenticated = await _authenticateForSettingsChange();
    if (!authenticated || !mounted) return;
    await settings.setInstallAuthPolicy(value);
  }

  Future<void> _setHideAntiFeatureAppsWithConfirmation(
    SettingsProvider settings,
    bool value,
  ) async {
    if (value == settings.hideAntiFeatureApps) return;
    if (!value) {
      final authenticated = await _authenticateForSettingsChange();
      if (!authenticated || !mounted) return;
    }
    await settings.setHideAntiFeatureApps(value);
  }

  void _showInstallAuthPolicyInfoDialog(
    BuildContext context,
    String title,
    String description,
  ) {
    final localizations = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: SafeArea(
          child: Column(
            spacing: 16,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(localizations.close),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final localizations = AppLocalizations.of(context)!;

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
            title: const Text('Parental Control'),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16,
                children: [
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 36.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        spacing: 16,
                        children: [
                          M3EContainer.c9SidedCookie(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            padding: const EdgeInsets.all(24.0),
                            child: Icon(
                              SolarIconsOutline.faceScanSquare,
                              size: 64,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          Text(
                            'Keep your family safe with parental controls. Manage app visibility and installation settings to ensure a secure experience for everyone.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    spacing: 4,
                    children: [
                      const HListHeader(title: 'Parental Control'),
                      HListView(
                        items: [
                          HListItemData(
                            leading: ListIcon(
                              iconData: settings.hideAntiFeatureApps
                                  ? SolarIconsBold.eyeClosed
                                  : SolarIconsBold.eye,
                            ),
                            title: Text('Hide anti-feature apps'),
                            subtitle:
                                'Prevent apps with anti-features from appearing in app lists',
                            onTap: () async {
                              await _setHideAntiFeatureAppsWithConfirmation(
                                settings,
                                !settings.hideAntiFeatureApps,
                              );
                            },
                            suffix: HSwitch(
                              value: settings.hideAntiFeatureApps,
                              onChanged: (value) async {
                                await _setHideAntiFeatureAppsWithConfirmation(
                                  settings,
                                  value,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (Platform.isAndroid)
                    Column(
                      spacing: 4,
                      children: [
                        HListHeader(title: localizations.installation_method),
                        HListView(
                          items: [
                            HListItemData(
                              leading: const ListIcon(
                                iconData: SolarIconsBold.lock,
                              ),
                              title: Text('Biometric Authentication'),
                              subtitle:
                                  'Require authentication before installations',
                              onTap: () async {
                                await _setInstallAuthEnabledWithVerification(
                                  settings,
                                  !settings.installAuthEnabled,
                                );
                              },
                              suffix: HSwitch(
                                value: settings.installAuthEnabled,
                                onChanged: (value) async {
                                  await _setInstallAuthEnabledWithVerification(
                                    settings,
                                    value,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        if (settings.installAuthEnabled)
                          HRadioListView<InstallAuthPolicy>(
                            items: [
                              HRadioListItemData<InstallAuthPolicy>(
                                leading: const Icon(Symbols.apps),
                                title: Text(localizations.auth_all_apps),
                                subtitle: '',
                                value: InstallAuthPolicy.all,
                                suffix: IconButton(
                                  onPressed: () {
                                    _showInstallAuthPolicyInfoDialog(
                                      context,
                                      localizations.auth_all_apps,
                                      localizations.auth_all_apps_desc,
                                    );
                                  },
                                  icon: const Icon(Symbols.info),
                                ),
                              ),
                              HRadioListItemData<InstallAuthPolicy>(
                                leading: const Icon(Symbols.warning),
                                title: Text(
                                  localizations.auth_all_apps_w_anti_feat,
                                ),
                                subtitle: '',
                                value: InstallAuthPolicy.antiFeatures,
                                suffix: IconButton(
                                  onPressed: () {
                                    _showInstallAuthPolicyInfoDialog(
                                      context,
                                      localizations.auth_all_apps_w_anti_feat,
                                      localizations
                                          .auth_all_apps_w_anti_feat_desc,
                                    );
                                  },
                                  icon: const Icon(Symbols.info),
                                ),
                              ),
                            ],
                            groupValue: settings.installAuthPolicy,
                            onChanged: (value) async {
                              await _setInstallAuthPolicyWithVerification(
                                settings,
                                value,
                              );
                            },
                          ),
                      ],
                    ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
