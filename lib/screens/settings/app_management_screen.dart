import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:florid/l10n/app_localizations.dart';
import 'package:florid/providers/settings_provider.dart';
import 'package:florid/services/update_check_service.dart';
import 'package:florid/widgets/m_list.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

class AppManagementScreen extends StatefulWidget {
  const AppManagementScreen({super.key});

  static const MethodChannel _batteryChannel = MethodChannel(
    'florid/battery_optimizations',
  );

  @override
  State<AppManagementScreen> createState() => _AppManagementScreenState();
}

class _AppManagementScreenState extends State<AppManagementScreen> {
  bool? _isIgnoringBatteryOptimizations;

  @override
  void initState() {
    super.initState();
    _loadBatteryOptimizationStatus();
  }

  String _installMethodLabel(
    AppLocalizations localizations,
    InstallMethod method,
  ) {
    switch (method) {
      case InstallMethod.shizuku:
        return localizations.shizuku;
      case InstallMethod.system:
        return localizations.system_installer;
    }
  }

  Future<void> _showInstallMethodDialog(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    final localizations = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.installation_method),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: InstallMethod.values
              .map(
                (method) => RadioListTile<InstallMethod>(
                  value: method,
                  groupValue: settings.installMethod,
                  title: Text(_installMethodLabel(localizations, method)),
                  subtitle: method == InstallMethod.shizuku
                      ? Text(localizations.requires_shizuku_running)
                      : Text(localizations.uses_standard_system_installer),
                  onChanged: (value) async {
                    if (value == null) return;
                    await settings.setInstallMethod(value);
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  },
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localizations.close),
          ),
        ],
      ),
    );
  }

  Future<void> _loadBatteryOptimizationStatus() async {
    if (!Platform.isAndroid) return;
    try {
      final isIgnoring = await AppManagementScreen._batteryChannel
          .invokeMethod<bool>('isIgnoringBatteryOptimizations');
      if (!mounted) return;
      setState(() {
        _isIgnoringBatteryOptimizations = isIgnoring ?? false;
      });
    } on PlatformException {
      if (!mounted) return;
      setState(() {
        _isIgnoringBatteryOptimizations = null;
      });
    }
  }

  Future<void> _requestDisableBatteryOptimizations() async {
    if (!Platform.isAndroid) return;
    final info = await PackageInfo.fromPlatform();

    final intent = AndroidIntent(
      action: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
      data: 'package:${info.packageName}',
    );
    await intent.launch();
    await Future.delayed(const Duration(seconds: 1));
    await _loadBatteryOptimizationStatus();
  }

  String _updateNetworkPolicyLabel(
    AppLocalizations localizations,
    UpdateNetworkPolicy policy,
  ) {
    switch (policy) {
      case UpdateNetworkPolicy.wifiOnly:
        return localizations.wifi_only;
      case UpdateNetworkPolicy.wifiAndCharging:
        return localizations.wifi_and_charging;
      case UpdateNetworkPolicy.any:
        return localizations.mobile_data_or_wifi;
    }
  }

  String _updateIntervalLabel(AppLocalizations localizations, int hours) {
    switch (hours) {
      case 1:
        return localizations.every_1_hour;
      case 2:
        return localizations.every_2_hours;
      case 3:
        return localizations.every_3_hours;
      case 6:
        return localizations.every_6_hours;
      case 12:
        return localizations.every_12_hours;
      case 24:
        return localizations.daily;
      default:
        return localizations.every_hours(hours);
    }
  }

  Future<void> _showUpdateNetworkPolicyDialog(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    final localizations = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.update_network),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: UpdateNetworkPolicy.values
              .map(
                (policy) => RadioListTile<UpdateNetworkPolicy>(
                  value: policy,
                  groupValue: settings.updateNetworkPolicy,
                  title: Text(_updateNetworkPolicyLabel(localizations, policy)),
                  onChanged: (value) async {
                    if (value == null) return;
                    await settings.setUpdateNetworkPolicy(value);
                    await UpdateCheckService.scheduleFromPrefs();
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  },
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localizations.close),
          ),
        ],
      ),
    );
  }

  Future<void> _showUpdateIntervalDialog(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    final localizations = AppLocalizations.of(context)!;
    const intervals = [1, 2, 3, 6, 12, 24];
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.update_interval),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: intervals
              .map(
                (hours) => RadioListTile<int>(
                  value: hours,
                  groupValue: settings.updateIntervalHours,
                  title: Text(_updateIntervalLabel(localizations, hours)),
                  onChanged: (value) async {
                    if (value == null) return;
                    await settings.setUpdateIntervalHours(value);
                    await UpdateCheckService.scheduleFromPrefs();
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  },
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localizations.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final localizations = AppLocalizations.of(context)!;
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar.large(title: Text(localizations.app_management)),
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
                          MListHeader(title: localizations.installation_method),
                          MRadioListView<InstallMethod>(
                            items: InstallMethod.values
                                .map(
                                  (method) => MRadioListItemData<InstallMethod>(
                                    title: _installMethodLabel(
                                      localizations,
                                      method,
                                    ),
                                    subtitle: method == InstallMethod.shizuku
                                        ? localizations.requires_shizuku_running
                                        : localizations
                                              .uses_standard_system_installer,
                                    value: method,
                                    suffix: method == InstallMethod.shizuku
                                        ? Container(
                                            margin: const EdgeInsets.only(
                                              right: 8.0,
                                            ),
                                            child: Material(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.secondary,
                                              borderRadius:
                                                  BorderRadius.circular(99.0),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12.0,
                                                      vertical: 2.0,
                                                    ),
                                                child: Text(
                                                  localizations.alpha,
                                                  style: TextStyle(
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.onSecondary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                )
                                .toList(),
                            groupValue: settings.installMethod,
                            onChanged: (value) async {
                              await settings.setInstallMethod(value);
                            },
                          ),
                        ],
                      ),

                      Column(
                        spacing: 4,
                        children: [
                          MListHeader(
                            title: localizations.downloads_and_storage,
                          ),
                          MListView(
                            items: [
                              MListItemData(
                                title:
                                    localizations.auto_install_after_download,
                                onTap: () {
                                  settings.setAutoInstallApk(
                                    !settings.autoInstallApk,
                                  );
                                },
                                subtitle: localizations
                                    .auto_install_after_download_subtitle,
                                suffix: Switch(
                                  value: settings.autoInstallApk,
                                  onChanged: (value) {
                                    settings.setAutoInstallApk(value);
                                  },
                                ),
                              ),
                              MListItemData(
                                title: localizations.delete_apk_after_install,
                                onTap: () {
                                  settings.setAutoInstallApk(
                                    !settings.autoInstallApk,
                                  );
                                },
                                subtitle: localizations
                                    .delete_apk_after_install_subtitle,
                                suffix: Switch(
                                  value: settings.autoDeleteApk,
                                  onChanged: (value) {
                                    settings.setAutoDeleteApk(value);
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
                          MListHeader(title: localizations.background_updates),
                          MListView(
                            items: [
                              MListItemData(
                                leading: Icon(Symbols.notifications),
                                title:
                                    localizations.check_updates_in_background,
                                subtitle:
                                    localizations.notify_when_updates_available,
                                onTap: () async {
                                  await settings.setBackgroundUpdatesEnabled(
                                    !settings.backgroundUpdatesEnabled,
                                  );
                                  await UpdateCheckService.scheduleFromPrefs();
                                },
                                suffix: Switch(
                                  value: settings.backgroundUpdatesEnabled,
                                  onChanged: (value) async {
                                    await settings.setBackgroundUpdatesEnabled(
                                      value,
                                    );
                                    await UpdateCheckService.scheduleFromPrefs();
                                  },
                                ),
                              ),
                              MListItemData(
                                leading: Icon(Symbols.network_check),
                                title: localizations.update_network,
                                subtitle: _updateNetworkPolicyLabel(
                                  localizations,
                                  settings.updateNetworkPolicy,
                                ),
                                onTap: () => _showUpdateNetworkPolicyDialog(
                                  context,
                                  settings,
                                ),
                                suffix: Icon(Symbols.chevron_right),
                              ),
                              MListItemData(
                                leading: Icon(Symbols.schedule),
                                title: localizations.update_interval,
                                subtitle: _updateIntervalLabel(
                                  localizations,
                                  settings.updateIntervalHours,
                                ),
                                onTap: () => _showUpdateIntervalDialog(
                                  context,
                                  settings,
                                ),
                                suffix: Icon(Symbols.chevron_right),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        spacing: 4,
                        children: [
                          if (settings.backgroundUpdatesEnabled &&
                              _isIgnoringBatteryOptimizations == false)
                            MListHeader(title: localizations.reliability),
                          MListView(
                            items: [
                              if (settings.backgroundUpdatesEnabled &&
                                  _isIgnoringBatteryOptimizations == false)
                                MListItemData(
                                  leading: Icon(
                                    Symbols.battery_saver,
                                    fill: 1,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  title: localizations
                                      .disable_battery_optimization,
                                  subtitle: localizations
                                      .allow_background_checks_reliably,
                                  onTap: _requestDisableBatteryOptimizations,
                                ),
                              if (kDebugMode)
                                MListItemData(
                                  leading: Icon(Symbols.bolt),
                                  title: localizations.run_debug_check_10s,
                                  subtitle: localizations
                                      .run_debug_check_10s_subtitle,
                                  onTap: () async {
                                    await UpdateCheckService.showDebugNotificationNow(
                                      localizations.debug_check_scheduled,
                                    );
                                    await UpdateCheckService.runDebugInApp();
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          localizations
                                              .debug_update_check_runs_10s,
                                        ),
                                      ),
                                    );
                                  },
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
