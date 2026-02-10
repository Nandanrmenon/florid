import 'package:florid/widgets/m_list.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../constants.dart';

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
  String _permissionDescription(String permission) {
    return kPermissionDescriptions[permission] ?? 'Permission required by app.';
  }

  String _permissionGroup(String permission) {
    if (permission.contains('LOCATION')) return 'Location';
    if (permission.contains('STORAGE')) return 'Storage';
    if (permission.contains('NETWORK') || permission.contains('INTERNET')) {
      return 'Network';
    }
    if (permission.contains('BLUETOOTH')) return 'Bluetooth';
    if (permission.contains('CAMERA')) return 'Camera';
    if (permission.contains('AUDIO')) return 'Audio';
    if (permission.contains('CONTACTS')) return 'Contacts';
    if (permission.contains('NOTIFICATION')) return 'Notifications';
    if (permission.contains('BOOT')) return 'Startup';
    if (permission.contains('NFC')) return 'NFC';
    return 'Other';
  }

  IconData _groupIcon(String group) {
    switch (group) {
      case 'Network':
        return Symbols.wifi;
      case 'Storage':
        return Symbols.folder;
      case 'Location':
        return Symbols.location_on;
      case 'Bluetooth':
        return Symbols.bluetooth;
      case 'Camera':
        return Symbols.camera_alt;
      case 'Audio':
        return Symbols.mic;
      case 'Contacts':
        return Symbols.contacts;
      case 'Notifications':
        return Symbols.notifications;
      case 'Startup':
        return Symbols.power_settings_new;
      case 'NFC':
        return Symbols.nfc;
      default:
        return Symbols.security;
    }
  }

  @override
  Widget build(BuildContext context) {
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
              'Permissions',
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
                'Network',
                'Storage',
                'Location',
                'Bluetooth',
                'Camera',
                'Audio',
                'Contacts',
                'Notifications',
                'Startup',
                'NFC',
                'Other',
              ];

              return groupOrder.where(grouped.containsKey).expand((group) {
                final permissions = grouped[group]!;
                return [
                  Column(
                    spacing: 4.0,
                    children: [
                      MListHeader(title: group, icon: _groupIcon(group)),
                      MListViewBuilder(
                        itemCount: permissions.length,
                        itemBuilder: (index) {
                          final permission = permissions[index];
                          final description = _permissionDescription(
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
