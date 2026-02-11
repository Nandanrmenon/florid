import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
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

  String _installMethodLabel(InstallMethod method) {
    switch (method) {
      case InstallMethod.shizuku:
        return 'Shizuku';
      case InstallMethod.system:
        return 'System installer';
    }
  }

  Future<void> _showInstallMethodDialog(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Installation method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: InstallMethod.values
              .map(
                (method) => RadioListTile<InstallMethod>(
                  value: method,
                  groupValue: settings.installMethod,
                  title: Text(_installMethodLabel(method)),
                  subtitle: method == InstallMethod.shizuku
                      ? const Text('Requires Shizuku to be running')
                      : const Text('Uses the standard system installer'),
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
            child: const Text('Close'),
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

  String _updateNetworkPolicyLabel(UpdateNetworkPolicy policy) {
    switch (policy) {
      case UpdateNetworkPolicy.wifiOnly:
        return 'Wi-Fi only';
      case UpdateNetworkPolicy.wifiAndCharging:
        return 'Wi-Fi + charging';
      case UpdateNetworkPolicy.any:
        return 'Mobile data or Wi-Fi';
    }
  }

  String _updateIntervalLabel(int hours) {
    switch (hours) {
      case 1:
        return 'Every 1 hour';
      case 2:
        return 'Every 2 hours';
      case 3:
        return 'Every 3 hours';
      case 6:
        return 'Every 6 hours';
      case 12:
        return 'Every 12 hours';
      case 24:
        return 'Daily';
      default:
        return 'Every $hours hours';
    }
  }

  Future<void> _showUpdateNetworkPolicyDialog(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update network'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: UpdateNetworkPolicy.values
              .map(
                (policy) => RadioListTile<UpdateNetworkPolicy>(
                  value: policy,
                  groupValue: settings.updateNetworkPolicy,
                  title: Text(_updateNetworkPolicyLabel(policy)),
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
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showUpdateIntervalDialog(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    const intervals = [1, 2, 3, 6, 12, 24];
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update interval'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: intervals
              .map(
                (hours) => RadioListTile<int>(
                  value: hours,
                  groupValue: settings.updateIntervalHours,
                  title: Text(_updateIntervalLabel(hours)),
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
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('App Management')),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16,
                children: [
                  Column(
                    spacing: 4,
                    children: [
                      MListHeader(title: 'Installation method'),
                      MRadioListView<InstallMethod>(
                        items: InstallMethod.values
                            .map(
                              (method) => MRadioListItemData<InstallMethod>(
                                title: _installMethodLabel(method),
                                subtitle: method == InstallMethod.shizuku
                                    ? 'Requires Shizuku to be running'
                                    : 'Uses the standard system installer',
                                value: method,
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
                      MListHeader(title: 'Downloads & Storage'),
                      MListView(
                        items: [
                          MListItemData(
                            title: 'Auto-install after download',
                            onTap: () {
                              settings.setAutoInstallApk(
                                !settings.autoInstallApk,
                              );
                            },
                            subtitle:
                                'Install APKs automatically once download finishes',
                            suffix: Switch(
                              value: settings.autoInstallApk,
                              onChanged: (value) {
                                settings.setAutoInstallApk(value);
                              },
                            ),
                          ),
                          MListItemData(
                            title: 'Delete APK after install',
                            onTap: () {
                              settings.setAutoInstallApk(
                                !settings.autoInstallApk,
                              );
                            },
                            subtitle:
                                'Remove installer files after successful installation',
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
                      MListHeader(title: 'Background updates'),
                      MListView(
                        items: [
                          MListItemData(
                            leading: Icon(Symbols.notifications),
                            title: 'Check for updates in background',
                            subtitle: 'Notify when updates are available',
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
                            title: 'Update network',
                            subtitle: _updateNetworkPolicyLabel(
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
                            title: 'Update interval',
                            subtitle: _updateIntervalLabel(
                              settings.updateIntervalHours,
                            ),
                            onTap: () =>
                                _showUpdateIntervalDialog(context, settings),
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
                        MListHeader(title: 'Reliability'),
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
                              title: 'Disable battery optimization',
                              subtitle:
                                  'Allow background checks to run reliably',
                              onTap: _requestDisableBatteryOptimizations,
                            ),
                          if (kDebugMode)
                            MListItemData(
                              leading: Icon(Symbols.bolt),
                              title: 'Run debug check in 10s',
                              subtitle:
                                  'Shows a test notification and runs after 10s',
                              onTap: () async {
                                await UpdateCheckService.showDebugNotificationNow(
                                  'Debug check scheduled',
                                );
                                await UpdateCheckService.runDebugInApp();
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Debug update check will run in 10 seconds',
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
        );
      },
    );
  }
}
