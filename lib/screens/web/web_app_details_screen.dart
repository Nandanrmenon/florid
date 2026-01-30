import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../models/fdroid_app.dart';
import '../../services/web_device_service.dart';

/// Web app details screen with remote install button
class WebAppDetailsScreen extends StatelessWidget {
  final FDroidApp app;

  const WebAppDetailsScreen({super.key, required this.app});

  Future<void> _installOnDevice(BuildContext context) async {
    final deviceService = context.read<WebDeviceService>();
    
    if (deviceService.selectedDevice == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a device first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final success = await deviceService.sendInstallCommand(
      packageName: app.packageName,
      appName: app.name,
      iconUrl: app.icon,
      versionName: app.latestVersion?.versionName,
    );

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Install request sent to ${deviceService.selectedDevice!.deviceName}'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send install request'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(app.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (app.icon != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      app.icon!,
                      height: 120,
                      width: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 120,
                          width: 120,
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          child: const Icon(Symbols.android, size: 48),
                        );
                      },
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    app.summary,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  Consumer<WebDeviceService>(
                    builder: (context, deviceService, _) {
                      return FilledButton.icon(
                        onPressed: () => _installOnDevice(context),
                        icon: const Icon(Symbols.install_mobile),
                        label: Text(
                          deviceService.selectedDevice != null
                              ? 'Install on ${deviceService.selectedDevice!.deviceName}'
                              : 'Install on Device',
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(app.description),
                  const SizedBox(height: 24),
                  _InfoRow(
                    label: 'Package',
                    value: app.packageName,
                  ),
                  if (app.latestVersion != null)
                    _InfoRow(
                      label: 'Version',
                      value: app.latestVersion!.versionName,
                    ),
                  if (app.license != null)
                    _InfoRow(
                      label: 'License',
                      value: app.license!,
                    ),
                  if (app.categories.isNotEmpty)
                    _InfoRow(
                      label: 'Categories',
                      value: app.categories.join(', '),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
