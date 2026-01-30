import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/fdroid_app.dart';
import '../providers/app_provider.dart';
import '../providers/download_provider.dart';
import '../services/pairing_service.dart';

/// Screen to show install progress for apps requested from web
class InstallProgressScreen extends StatefulWidget {
  final String packageName;
  final String appName;

  const InstallProgressScreen({
    super.key,
    required this.packageName,
    required this.appName,
  });

  @override
  State<InstallProgressScreen> createState() => _InstallProgressScreenState();
}

class _InstallProgressScreenState extends State<InstallProgressScreen> {
  bool _isLoading = true;
  bool _isDownloading = false;
  bool _isInstalling = false;
  bool _isComplete = false;
  String? _error;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _startInstallProcess();
  }

  Future<void> _startInstallProcess() async {
    try {
      final appProvider = context.read<AppProvider>();
      final downloadProvider = context.read<DownloadProvider>();
      final pairingService = context.read<PairingService>();

      // Find the app
      setState(() => _isLoading = true);
      
      FDroidApp? app;
      
      // Try to find app in cached data first
      final apps = appProvider.allApps;
      app = apps.firstWhere(
        (a) => a.packageName == widget.packageName,
        orElse: () => FDroidApp(
          packageName: widget.packageName,
          name: widget.appName,
          summary: '',
          description: '',
          iconUrl: null,
          categories: [],
          antiFeatures: [],
          latestVersion: null,
          versions: [],
          screenshots: [],
          repositoryUrl: 'https://f-droid.org/repo',
        ),
      );

      setState(() => _isLoading = false);

      if (app.latestVersion == null) {
        throw Exception('No version available for ${widget.appName}');
      }

      // Start download
      setState(() => _isDownloading = true);

      // Monitor download progress
      final downloadInfo = downloadProvider.getDownloadInfo(
        widget.packageName,
        app.latestVersion!.versionName,
      );

      // Download the APK
      final filePath = await downloadProvider.downloadApk(app);

      // Send progress updates to web
      await pairingService.sendDownloadProgress(
        packageName: widget.packageName,
        progress: 1.0,
        status: 'complete',
      );

      setState(() {
        _isDownloading = false;
        _isInstalling = true;
      });

      // Send install progress to web
      await pairingService.sendInstallProgress(
        packageName: widget.packageName,
        status: 'installing',
      );

      // Install the APK
      if (filePath != null) {
        await downloadProvider.installApk(filePath);
      }

      // Send install complete to web
      await pairingService.sendInstallProgress(
        packageName: widget.packageName,
        status: 'complete',
      );

      setState(() {
        _isInstalling = false;
        _isComplete = true;
      });

      // Auto-close after a delay
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isDownloading = false;
        _isInstalling = false;
      });

      // Send error to web
      try {
        final pairingService = context.read<PairingService>();
        await pairingService.sendDownloadProgress(
          packageName: widget.packageName,
          progress: 0.0,
          status: 'error: $e',
        );
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Install Progress'),
      ),
      body: Consumer<DownloadProvider>(
        builder: (context, downloadProvider, child) {
          // Get real-time download progress if available
          final downloadInfo = downloadProvider.downloads.values.firstWhere(
            (info) => info.packageName == widget.packageName,
            orElse: () => DownloadInfo(
              packageName: widget.packageName,
              versionName: '',
              status: DownloadStatus.idle,
            ),
          );

          if (_isDownloading && downloadInfo.status == DownloadStatus.downloading) {
            _downloadProgress = downloadInfo.progress;
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App icon or placeholder
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.android,
                      size: 48,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.appName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.packageName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Status indicator
                  if (_isLoading)
                    const Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading app information...'),
                      ],
                    )
                  else if (_error != null)
                    Column(
                      children: [
                        const Icon(
                          Icons.error,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    )
                  else if (_isComplete)
                    Column(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 64,
                          color: Colors.green.shade600,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Installation Complete!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    )
                  else if (_isInstalling)
                    Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        const Text(
                          'Installing...',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please approve the installation prompt',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    )
                  else if (_isDownloading)
                    Column(
                      children: [
                        SizedBox(
                          width: 200,
                          child: LinearProgressIndicator(
                            value: _downloadProgress,
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Downloading: ${(_downloadProgress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (downloadInfo.status == DownloadStatus.downloading) ...[
                          const SizedBox(height: 8),
                          Text(
                            '${downloadInfo.formattedBytesDownloaded} / ${downloadInfo.formattedTotalBytes}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                          Text(
                            downloadInfo.formattedSpeed,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
