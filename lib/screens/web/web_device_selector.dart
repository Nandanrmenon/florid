import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../services/web_device_service.dart';
import 'web_pairing_screen.dart';

/// Widget for selecting a paired device
class WebDeviceSelector extends StatelessWidget {
  const WebDeviceSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WebDeviceService>(
      builder: (context, deviceService, _) {
        if (deviceService.devices.isEmpty) {
          return TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WebPairingScreen(),
                ),
              );
            },
            icon: const Icon(Symbols.add),
            label: const Text('Pair Device'),
          );
        }

        return PopupMenuButton(
          icon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Symbols.smartphone),
              const SizedBox(width: 8),
              Text(
                deviceService.selectedDevice?.deviceName ?? 'Select Device',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          onSelected: (value) {
            if (value == 'pair') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WebPairingScreen(),
                ),
              );
            } else {
              final device = deviceService.devices.firstWhere(
                (d) => d.deviceId == value,
              );
              deviceService.selectDevice(device);
            }
          },
          itemBuilder: (context) => [
            ...deviceService.devices.map((device) {
              final isSelected = deviceService.selectedDevice?.deviceId == device.deviceId;
              return PopupMenuItem(
                value: device.deviceId,
                child: Row(
                  children: [
                    Icon(
                      device.isActive ? Symbols.check_circle : Symbols.circle,
                      size: 20,
                      color: device.isActive ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.deviceName,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          Text(
                            device.isActive ? 'Active' : 'Offline',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(Symbols.check, size: 20),
                  ],
                ),
              );
            }),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'pair',
              child: Row(
                children: [
                  Icon(Symbols.add),
                  SizedBox(width: 12),
                  Text('Pair New Device'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
