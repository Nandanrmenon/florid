import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../services/update_check_service.dart';
import '../widgets/m_list.dart';

class UpdateSettingsScreen extends StatefulWidget {
  const UpdateSettingsScreen({super.key});

  @override
  State<UpdateSettingsScreen> createState() => _UpdateSettingsScreenState();
}

class _UpdateSettingsScreenState extends State<UpdateSettingsScreen> {
  static const MethodChannel _batteryChannel = MethodChannel(
    'florid/battery_optimizations',
  );

  bool? _isIgnoringBatteryOptimizations;

  @override
  void initState() {
    super.initState();
    _loadBatteryOptimizationStatus();
  }

  Future<void> _loadBatteryOptimizationStatus() async {
    if (!Platform.isAndroid) return;
    try {
      final isIgnoring = await _batteryChannel.invokeMethod<bool>(
        'isIgnoringBatteryOptimizations',
      );
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
          appBar: AppBar(title: const Text('Update settings')),
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
