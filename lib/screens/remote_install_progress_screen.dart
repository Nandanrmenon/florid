import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/fdroid_app.dart';
import '../providers/app_provider.dart';
import '../providers/download_provider.dart';

class RemoteInstallProgressScreen extends StatefulWidget {
  final String packageName;
  final String versionName;

  const RemoteInstallProgressScreen({
    super.key,
    required this.packageName,
    required this.versionName,
  });

  @override
  State<RemoteInstallProgressScreen> createState() =>
      _RemoteInstallProgressScreenState();
}

class _RemoteInstallProgressScreenState
    extends State<RemoteInstallProgressScreen> {
  FDroidApp? _app;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAppAndStartDownload();
  }

  Future<void> _loadAppAndStartDownload() async {
    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final downloadProvider = Provider.of<DownloadProvider>(context, listen: false);

      // Fetch app details
      final app = await appProvider.getAppByPackageName(widget.packageName);

      if (app == null) {
        setState(() {
          _error = 'App not found: ${widget.packageName}';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _app = app;
        _isLoading = false;
      });

      // Check if already downloading or downloaded
      final downloadInfo = downloadProvider.getDownloadInfo(
        widget.packageName,
        widget.versionName,
      );

      if (downloadInfo?.status == DownloadStatus.downloading) {
        // Already downloading, just show progress
        return;
      }

      if (downloadInfo?.status == DownloadStatus.completed) {
        // Already downloaded, show install option
        return;
      }

      // Start download
      try {
        await downloadProvider.downloadApk(app);
      } catch (e) {
        setState(() => _error = 'Download failed: $e');
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading app: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Remote Install'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView(theme, colorScheme)
              : _buildProgressView(theme, colorScheme),
    );
  }

  Widget _buildErrorView(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressView(ThemeData theme, ColorScheme colorScheme) {
    return Consumer<DownloadProvider>(
      builder: (context, downloadProvider, child) {
        final downloadInfo = downloadProvider.getDownloadInfo(
          widget.packageName,
          widget.versionName,
        );

        final status = downloadInfo?.status ?? DownloadStatus.idle;
        final progress = downloadInfo?.progress ?? 0.0;
        final bytesDownloaded = downloadInfo?.formattedBytesDownloaded ?? '0 B';
        final totalBytes = downloadInfo?.formattedTotalBytes ?? '0 B';
        final speed = downloadInfo?.formattedSpeed ?? '0 B/s';

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // App Info
              if (_app != null) ...[
                CircleAvatar(
                  radius: 48,
                  backgroundImage: NetworkImage(_app!.iconUrl),
                  backgroundColor: colorScheme.surfaceContainerHighest,
                ),
                const SizedBox(height: 16),
                Text(
                  _app!.name,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.versionName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Status Icon
              _buildStatusIcon(status, colorScheme),

              const SizedBox(height: 24),

              // Status Text
              Text(
                _getStatusText(status),
                style: theme.textTheme.titleLarge,
              ),

              const SizedBox(height: 32),

              // Progress Indicator
              if (status == DownloadStatus.downloading) ...[
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                ),
                const SizedBox(height: 16),
                Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '$bytesDownloaded / $totalBytes',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  speed,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],

              const Spacer(),

              // Action Buttons
              if (status == DownloadStatus.completed) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      if (downloadInfo?.filePath != null) {
                        try {
                          await downloadProvider.installApk(downloadInfo!.filePath!);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Installing APK...'),
                              ),
                            );
                            Navigator.of(context).pop();
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Install failed: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                    icon: const Icon(Icons.install_mobile),
                    label: const Text('Install'),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              if (status == DownloadStatus.error) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _loadAppAndStartDownload,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              if (status == DownloadStatus.downloading) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      downloadProvider.cancelDownload(
                        widget.packageName,
                        widget.versionName,
                      );
                    },
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel'),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusIcon(DownloadStatus status, ColorScheme colorScheme) {
    IconData icon;
    Color color;

    switch (status) {
      case DownloadStatus.downloading:
        icon = Icons.download;
        color = colorScheme.primary;
        break;
      case DownloadStatus.completed:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case DownloadStatus.error:
        icon = Icons.error;
        color = colorScheme.error;
        break;
      case DownloadStatus.cancelled:
        icon = Icons.cancel;
        color = colorScheme.onSurface.withOpacity(0.5);
        break;
      default:
        icon = Icons.hourglass_empty;
        color = colorScheme.onSurface.withOpacity(0.5);
    }

    return Icon(icon, size: 64, color: color);
  }

  String _getStatusText(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.downloading:
        return 'Downloading...';
      case DownloadStatus.completed:
        return 'Download Complete';
      case DownloadStatus.error:
        return 'Download Failed';
      case DownloadStatus.cancelled:
        return 'Download Cancelled';
      default:
        return 'Preparing Download...';
    }
  }
}
