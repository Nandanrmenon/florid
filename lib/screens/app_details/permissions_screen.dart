import 'package:florid/l10n/app_localizations.dart';
import 'package:florid/widgets/m_list.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class PermissionsScreen extends StatefulWidget {
  final List<String> permissions;
  final String appName;

  const PermissionsScreen({
    super.key,
    required this.permissions,
    required this.appName,
  });

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  String _permissionDescription(AppLocalizations l10n, String permission) {
    switch (permission) {
      case 'android.permission.INTERNET':
        return l10n.permission_desc_internet;
      case 'android.permission.ACCESS_NETWORK_STATE':
        return l10n.permission_desc_access_network_state;
      case 'android.permission.ACCESS_WIFI_STATE':
        return l10n.permission_desc_access_wifi_state;
      case 'android.permission.CHANGE_WIFI_STATE':
        return l10n.permission_desc_change_wifi_state;
      case 'android.permission.READ_EXTERNAL_STORAGE':
        return l10n.permission_desc_read_external_storage;
      case 'android.permission.WRITE_EXTERNAL_STORAGE':
        return l10n.permission_desc_write_external_storage;
      case 'android.permission.MANAGE_EXTERNAL_STORAGE':
        return l10n.permission_desc_manage_external_storage;
      case 'android.permission.REQUEST_INSTALL_PACKAGES':
        return l10n.permission_desc_request_install_packages;
      case 'android.permission.POST_NOTIFICATIONS':
        return l10n.permission_desc_post_notifications;
      case 'android.permission.VIBRATE':
        return l10n.permission_desc_vibrate;
      case 'android.permission.WAKE_LOCK':
        return l10n.permission_desc_wake_lock;
      case 'android.permission.RECEIVE_BOOT_COMPLETED':
        return l10n.permission_desc_receive_boot_completed;
      case 'android.permission.FOREGROUND_SERVICE':
        return l10n.permission_desc_foreground_service;
      case 'android.permission.CAMERA':
        return l10n.permission_desc_camera;
      case 'android.permission.RECORD_AUDIO':
        return l10n.permission_desc_record_audio;
      case 'android.permission.READ_CONTACTS':
        return l10n.permission_desc_read_contacts;
      case 'android.permission.WRITE_CONTACTS':
        return l10n.permission_desc_write_contacts;
      case 'android.permission.ACCESS_FINE_LOCATION':
        return l10n.permission_desc_access_fine_location;
      case 'android.permission.ACCESS_COARSE_LOCATION':
        return l10n.permission_desc_access_coarse_location;
      case 'android.permission.BLUETOOTH':
        return l10n.permission_desc_bluetooth;
      case 'android.permission.BLUETOOTH_CONNECT':
        return l10n.permission_desc_bluetooth_connect;
      case 'android.permission.BLUETOOTH_SCAN':
        return l10n.permission_desc_bluetooth_scan;
      case 'android.permission.NFC':
        return l10n.permission_desc_nfc;
      default:
        return l10n.permission_required_by_app;
    }
  }

  String _permissionGroup(String permission) {
    if (permission.contains('LOCATION')) return 'location';
    if (permission.contains('STORAGE')) return 'storage';
    if (permission.contains('NETWORK') || permission.contains('INTERNET')) {
      return 'network';
    }
    if (permission.contains('BLUETOOTH')) return 'bluetooth';
    if (permission.contains('CAMERA')) return 'camera';
    if (permission.contains('AUDIO')) return 'audio';
    if (permission.contains('CONTACTS')) return 'contacts';
    if (permission.contains('NOTIFICATION')) return 'notifications';
    if (permission.contains('BOOT')) return 'startup';
    if (permission.contains('NFC')) return 'nfc';
    return 'other';
  }

  String _groupLabel(AppLocalizations l10n, String group) {
    switch (group) {
      case 'network':
        return l10n.permission_group_network;
      case 'storage':
        return l10n.permission_group_storage;
      case 'location':
        return l10n.permission_group_location;
      case 'bluetooth':
        return l10n.permission_group_bluetooth;
      case 'camera':
        return l10n.permission_group_camera;
      case 'audio':
        return l10n.permission_group_audio;
      case 'contacts':
        return l10n.permission_group_contacts;
      case 'notifications':
        return l10n.notifications;
      case 'startup':
        return l10n.permission_group_startup;
      case 'nfc':
        return l10n.permission_group_nfc;
      default:
        return l10n.other;
    }
  }

  IconData _groupIcon(String group) {
    switch (group) {
      case 'network':
        return Symbols.wifi;
      case 'storage':
        return Symbols.folder;
      case 'location':
        return Symbols.location_on;
      case 'bluetooth':
        return Symbols.bluetooth;
      case 'camera':
        return Symbols.camera_alt;
      case 'audio':
        return Symbols.mic;
      case 'contacts':
        return Symbols.contacts;
      case 'notifications':
        return Symbols.notifications;
      case 'startup':
        return Symbols.power_settings_new;
      case 'nfc':
        return Symbols.nfc;
      default:
        return Symbols.security;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.appName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 20,
                fontVariations: [
                  FontVariation('wght', 700),
                  FontVariation('ROND', 100),
                ],
              ),
            ),
            Text(
              l10n.permissions,
              style: TextStyle(
                fontSize: 12,
                fontVariations: [FontVariation('ROND', 100)],
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          spacing: 16,
          children: [
            ...() {
              final grouped = <String, List<String>>{};
              for (final permission in widget.permissions) {
                final group = _permissionGroup(permission);
                grouped.putIfAbsent(group, () => []).add(permission);
              }

              for (final entry in grouped.entries) {
                entry.value.sort();
              }

              const groupOrder = [
                'network',
                'storage',
                'location',
                'bluetooth',
                'camera',
                'audio',
                'contacts',
                'notifications',
                'startup',
                'nfc',
                'other',
              ];

              return groupOrder.where(grouped.containsKey).expand((group) {
                final permissions = grouped[group]!;
                return [
                  Column(
                    spacing: 4.0,
                    children: [
                      MListHeader(
                        title: _groupLabel(l10n, group),
                        icon: _groupIcon(group),
                      ),
                      MListViewBuilder(
                        itemCount: permissions.length,
                        itemBuilder: (index) {
                          final permission = permissions[index];
                          final description = _permissionDescription(
                            l10n,
                            permission,
                          );

                          return MListItemData(
                            title: permission,
                            subtitle: description,
                            onTap: () {},
                          );
                        },
                      ),
                    ],
                  ),
                ];
              });
            }(),
          ],
        ),
      ),
    );
  }
}
