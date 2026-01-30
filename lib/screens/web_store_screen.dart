import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pairing_provider.dart';
import '../providers/app_provider.dart';
import '../models/fdroid_app.dart';
import '../widgets/app_list_item.dart';

class WebStoreScreen extends StatefulWidget {
  const WebStoreScreen({super.key});

  @override
  State<WebStoreScreen> createState() => _WebStoreScreenState();
}

class _WebStoreScreenState extends State<WebStoreScreen> {
  final TextEditingController _pairingCodeController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _pairingCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Florid Web Store'),
        actions: [
          Consumer<PairingProvider>(
            builder: (context, pairingProvider, child) {
              if (pairingProvider.isPaired) {
                return IconButton(
                  icon: const Icon(Icons.link),
                  tooltip: 'Paired',
                  onPressed: () => _showPairingInfo(context),
                );
              }
              return IconButton(
                icon: const Icon(Icons.link_off),
                tooltip: 'Not paired',
                onPressed: () => _showPairingDialog(context),
              );
            },
          ),
        ],
      ),
      body: Consumer<PairingProvider>(
        builder: (context, pairingProvider, child) {
          if (!pairingProvider.isPaired) {
            return _buildPairingPrompt(context, pairingProvider);
          }
          return _buildAppStore(context);
        },
      ),
    );
  }

  Widget _buildPairingPrompt(
    BuildContext context,
    PairingProvider pairingProvider,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.phonelink_off,
                  size: 80,
                  color: Colors.grey,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Pair with Mobile Device',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'To install apps on your mobile device from the web, you need to pair this browser with your mobile app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Steps:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('1. Open Florid app on your mobile device'),
                    SizedBox(height: 8),
                    Text('2. Go to Settings → Pair with Web'),
                    SizedBox(height: 8),
                    Text('3. Note the 6-digit pairing code'),
                    SizedBox(height: 8),
                    Text('4. Enter the code below'),
                  ],
                ),
                const SizedBox(height: 32),
                if (pairingProvider.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            pairingProvider.errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                ElevatedButton.icon(
                  onPressed: () => _showPairingDialog(context),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Enter Pairing Code'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppStore(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search apps...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
        ),
        Expanded(
          child: Consumer<AppProvider>(
            builder: (context, appProvider, child) {
              if (appProvider.isLoading && appProvider.apps.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (appProvider.error != null && appProvider.apps.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(appProvider.error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => appProvider.loadApps(forceRefresh: true),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final filteredApps = _searchQuery.isEmpty
                  ? appProvider.apps
                  : appProvider.apps.where((app) {
                      return app.name.toLowerCase().contains(_searchQuery) ||
                          app.packageName.toLowerCase().contains(_searchQuery) ||
                          (app.summary ?? '').toLowerCase().contains(_searchQuery);
                    }).toList();

              if (filteredApps.isEmpty) {
                return const Center(
                  child: Text('No apps found'),
                );
              }

              return ListView.builder(
                itemCount: filteredApps.length,
                itemBuilder: (context, index) {
                  final app = filteredApps[index];
                  return _buildWebAppListItem(context, app);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWebAppListItem(BuildContext context, FDroidApp app) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: app.icon != null
            ? Image.network(
                app.icon!,
                width: 48,
                height: 48,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.android, size: 48);
                },
              )
            : const Icon(Icons.android, size: 48),
        title: Text(
          app.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              app.summary ?? 'No description available',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              app.packageName,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        trailing: ElevatedButton.icon(
          onPressed: () => _sendInstallRequest(context, app),
          icon: const Icon(Icons.install_mobile, size: 18),
          label: const Text('Install'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ),
    );
  }

  Future<void> _showPairingDialog(BuildContext context) async {
    _pairingCodeController.clear();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Pairing Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the 6-digit code from your mobile device:',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pairingCodeController,
              decoration: const InputDecoration(
                hintText: '123456',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Consumer<PairingProvider>(
            builder: (context, pairingProvider, child) {
              return ElevatedButton(
                onPressed: pairingProvider.isLoading
                    ? null
                    : () async {
                        final code = _pairingCodeController.text.trim();
                        // Validate: must be 6 digits
                        if (code.length == 6 && int.tryParse(code) != null) {
                          final success = await pairingProvider.pairWithCode(code);
                          if (success && context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Successfully paired!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid 6-digit code'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                child: pairingProvider.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Pair'),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showPairingInfo(BuildContext context) {
    final pairingProvider = context.read<PairingProvider>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pairing Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Status: Paired', style: TextStyle(color: Colors.green)),
            const SizedBox(height: 16),
            Text('Device ID: ${pairingProvider.deviceId ?? 'Unknown'}'),
            const SizedBox(height: 8),
            Text('Pairing Code: ${pairingProvider.currentPairingCode ?? 'N/A'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              pairingProvider.unpair();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Unpair'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendInstallRequest(BuildContext context, FDroidApp app) async {
    final pairingProvider = context.read<PairingProvider>();
    
    final success = await pairingProvider.sendInstallRequest(
      packageName: app.packageName,
      appName: app.name,
      versionName: app.latestVersion?.versionName,
    );

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Install request sent for ${app.name}'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send install request: ${pairingProvider.errorMessage}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
