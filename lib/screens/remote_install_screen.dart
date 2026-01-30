import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/fdroid_app.dart';
import '../providers/download_provider.dart';
import '../providers/app_provider.dart';

class RemoteInstallScreen extends StatefulWidget {
  final String packageName;
  final String appName;
  final String? versionName;

  const RemoteInstallScreen({
    super.key,
    required this.packageName,
    required this.appName,
    this.versionName,
  });

  @override
  State<RemoteInstallScreen> createState() => _RemoteInstallScreenState();
}

class _RemoteInstallScreenState extends State<RemoteInstallScreen> {
  bool _isLoading = true;
  bool _isDownloading = false;
  String? _errorMessage;
  FDroidApp? _app;

  @override
  void initState() {
    super.initState();
    _loadAppAndStartDownload();
  }

  Future<void> _loadAppAndStartDownload() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load app details
      final appProvider = context.read<AppProvider>();
      await appProvider.ensureAppsLoaded();
      
      final app = appProvider.apps.firstWhere(
        (a) => a.packageName == widget.packageName,
        orElse: () => throw Exception('App not found'),
      );

      setState(() {
        _app = app;
        _isLoading = false;
      });

      // Start download
      await _startDownload();
    } catch (e, stackTrace) {
      debugPrint('[RemoteInstallScreen] Failed to load app: $e');
      debugPrint('[RemoteInstallScreen] Stack trace: $stackTrace');
      setState(() {
        _errorMessage = 'Failed to load app: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _startDownload() async {
    if (_app == null) return;

    setState(() {
      _isDownloading = true;
      _errorMessage = null;
    });

    try {
      final downloadProvider = context.read<DownloadProvider>();
      await downloadProvider.downloadApk(_app!);
      
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Download failed: $e';
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remote Install'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading app details...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    }

    if (_app == null) {
      return const Center(
        child: Text('App not found'),
      );
    }

    return Consumer<DownloadProvider>(
      builder: (context, downloadProvider, child) {
        final downloadInfo = downloadProvider.getDownloadInfo(
          widget.packageName,
          widget.versionName ?? _app!.latestVersion?.versionName ?? '',
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.download,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              Text(
                widget.appName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.packageName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              if (downloadInfo != null) ...[
                _buildDownloadStatus(downloadInfo),
              ] else ...[
                const Center(
                  child: CircularProgressIndicator(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDownloadStatus(DownloadInfo downloadInfo) {
    switch (downloadInfo.status) {
      case DownloadStatus.downloading:
        return Column(
          children: [
            const Text(
              'Downloading...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: downloadInfo.progress,
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              '${(downloadInfo.progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  downloadInfo.formattedBytesDownloaded,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  downloadInfo.formattedSpeed,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  downloadInfo.formattedTotalBytes,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ],
        );

      case DownloadStatus.completed:
        return Column(
          children: [
            const Icon(
              Icons.check_circle,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            const Text(
              'Download Complete!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  await context
                      .read<DownloadProvider>()
                      .installApk(downloadInfo.filePath!);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Installation failed: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.install_mobile),
              label: const Text('Install Now'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );

      case DownloadStatus.error:
        return Column(
          children: [
            const Icon(
              Icons.error,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Download Failed',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              downloadInfo.error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _startDownload(),
              child: const Text('Retry'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );

      case DownloadStatus.cancelled:
        return Column(
          children: [
            const Icon(
              Icons.cancel,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            const Text(
              'Download Cancelled',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _startDownload(),
              child: const Text('Retry'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
