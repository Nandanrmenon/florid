import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_platform/universal_platform.dart';

import '../models/fdroid_app.dart';
import '../providers/app_provider.dart';
import '../services/pairing_service.dart';
import '../screens/web_pairing_screen.dart';
import '../screens/app_details_screen.dart';

/// Web store home screen
class WebStoreScreen extends StatefulWidget {
  const WebStoreScreen({super.key});

  @override
  State<WebStoreScreen> createState() => _WebStoreScreenState();
}

class _WebStoreScreenState extends State<WebStoreScreen> {
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    // Load apps
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appProvider = context.read<AppProvider>();
      appProvider.fetchLatestApps();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/Florid.png',
              height: 32,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.android),
            ),
            const SizedBox(width: 12),
            const Text('Florid Web Store'),
          ],
        ),
        actions: [
          // Pairing status indicator
          Consumer<PairingService>(
            builder: (context, pairingService, child) {
              return IconButton(
                icon: Icon(
                  pairingService.isPaired 
                    ? Icons.phone_android 
                    : Icons.phonelink_off,
                  color: pairingService.isPaired 
                    ? Colors.green 
                    : Colors.grey,
                ),
                tooltip: pairingService.isPaired 
                  ? 'Paired with ${pairingService.pairedDeviceName}' 
                  : 'Pair with mobile device',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WebPairingScreen(),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search apps...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          
          // App list
          Expanded(
            child: Consumer2<AppProvider, PairingService>(
              builder: (context, appProvider, pairingService, child) {
                if (appProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final apps = appProvider.latestApps
                  .where((app) => 
                    _searchQuery.isEmpty ||
                    app.name.toLowerCase().contains(_searchQuery) ||
                    app.packageName.toLowerCase().contains(_searchQuery) ||
                    app.summary.toLowerCase().contains(_searchQuery)
                  )
                  .toList();

                if (apps.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.apps, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty 
                            ? 'No apps available' 
                            : 'No apps found',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 300,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: apps.length,
                  itemBuilder: (context, index) {
                    final app = apps[index];
                    return _AppCard(
                      app: app,
                      isPaired: pairingService.isPaired,
                      onInstall: () => _handleInstall(app, pairingService),
                      onDetails: () => _showAppDetails(app),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleInstall(FDroidApp app, PairingService pairingService) async {
    if (!pairingService.isPaired) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please pair with a mobile device first'),
          action: SnackBarAction(
            label: 'Pair',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WebPairingScreen(),
                ),
              );
            },
          ),
        ),
      );
      return;
    }

    try {
      await pairingService.sendInstallRequest(
        packageName: app.packageName,
        appName: app.name,
        repositoryUrl: app.repositoryUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Install request sent for ${app.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send install request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAppDetails(FDroidApp app) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppDetailsScreen(app: app),
      ),
    );
  }
}

class _AppCard extends StatelessWidget {
  final FDroidApp app;
  final bool isPaired;
  final VoidCallback onInstall;
  final VoidCallback onDetails;

  const _AppCard({
    required this.app,
    required this.isPaired,
    required this.onInstall,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onDetails,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App icon
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: app.iconUrl != null
                  ? Image.network(
                      app.iconUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => 
                        const Icon(Icons.android, size: 48),
                    )
                  : const Icon(Icons.android, size: 48),
              ),
            ),
            
            // App info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        app.summary,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onInstall,
                        icon: Icon(
                          isPaired ? Icons.send_to_mobile : Icons.phonelink_off,
                          size: 18,
                        ),
                        label: Text(isPaired ? 'Install' : 'Pair First'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
