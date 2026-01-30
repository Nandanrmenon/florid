import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../models/install_command.dart';
import '../providers/app_provider.dart';
import '../providers/download_provider.dart';
import '../screens/app_details_screen.dart';

/// Screen showing pending remote install requests
class RemoteInstallScreen extends StatelessWidget {
  const RemoteInstallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remote Installs'),
        actions: [
          Consumer<DownloadProvider>(
            builder: (context, downloads, _) {
              if (downloads.pendingRemoteInstalls.isEmpty) {
                return const SizedBox.shrink();
              }
              return TextButton.icon(
                onPressed: () {
                  _showClearAllDialog(context, downloads);
                },
                icon: const Icon(Symbols.delete),
                label: const Text('Clear All'),
              );
            },
          ),
        ],
      ),
      body: Consumer<DownloadProvider>(
        builder: (context, downloads, _) {
          final pending = downloads.pendingRemoteInstalls;

          if (pending.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Symbols.download_done,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pending remote installs',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Install requests from the web store will appear here',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: pending.length,
            itemBuilder: (context, index) {
              final command = pending[index];
              return _RemoteInstallCard(
                command: command,
                onInstall: () => _handleInstall(context, command),
                onDismiss: () => _handleDismiss(context, command),
                onViewDetails: () => _handleViewDetails(context, command),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleInstall(
    BuildContext context,
    InstallCommand command,
  ) async {
    final appProvider = context.read<AppProvider>();
    final downloadProvider = context.read<DownloadProvider>();

    // Try to find the app in the cache
    final app = appProvider.getCachedApp(command.packageName);

    if (app != null) {
      try {
        // Start download
        await downloadProvider.downloadApk(app);

        // Remove from remote install queue
        downloadProvider.removeRemoteInstall(command);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Installing ${command.appName}'),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to install: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // App not in cache, show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'App ${command.packageName} not found in repositories',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleDismiss(BuildContext context, InstallCommand command) {
    final downloadProvider = context.read<DownloadProvider>();
    downloadProvider.removeRemoteInstall(command);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Dismissed ${command.appName}'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            downloadProvider.queueRemoteInstall(command);
          },
        ),
      ),
    );
  }

  void _handleViewDetails(BuildContext context, InstallCommand command) {
    final appProvider = context.read<AppProvider>();
    final app = appProvider.getCachedApp(command.packageName);

    if (app != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AppDetailsScreen(app: app),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'App ${command.packageName} not found in repositories',
          ),
        ),
      );
    }
  }

  Future<void> _showClearAllDialog(
    BuildContext context,
    DownloadProvider downloads,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All'),
        content: const Text(
          'Are you sure you want to dismiss all pending remote install requests?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      downloads.clearRemoteInstalls();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All remote installs dismissed')),
        );
      }
    }
  }
}

class _RemoteInstallCard extends StatelessWidget {
  final InstallCommand command;
  final VoidCallback onInstall;
  final VoidCallback onDismiss;
  final VoidCallback onViewDetails;

  const _RemoteInstallCard({
    required this.command,
    required this.onInstall,
    required this.onDismiss,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final timestamp = DateTime.tryParse(command.timestamp);
    final timeAgo = timestamp != null ? _formatTimeAgo(timestamp) : 'Unknown';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              child: Icon(
                Symbols.install_mobile,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            title: Text(
              command.appName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(command.packageName),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Symbols.schedule,
                      size: 16,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Symbols.devices,
                      size: 16,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'from ${command.sourceDevice}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            isThreeLine: true,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onViewDetails,
                  child: const Text('Details'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onDismiss,
                  child: const Text('Dismiss'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: onInstall,
                  icon: const Icon(Symbols.download),
                  label: const Text('Install'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }
}
