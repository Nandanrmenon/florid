import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../models/fdroid_app.dart';
import '../providers/download_provider.dart';

class AppListItem extends StatelessWidget {
  final FDroidApp app;
  final VoidCallback? onTap;
  final bool showCategory;

  const AppListItem({
    super.key,
    required this.app,
    this.onTap,
    this.showCategory = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: theme.colorScheme.surface,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: _MultiIcon(app: app),
        ),
      ),
      title: Text(
        app.name,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(app.summary, maxLines: 2, overflow: TextOverflow.ellipsis),
      dense: true,
    );
  }
}

class _MultiIcon extends StatefulWidget {
  final FDroidApp app;
  const _MultiIcon({required this.app});

  @override
  State<_MultiIcon> createState() => _MultiIconState();
}

class _MultiIconState extends State<_MultiIcon> {
  late List<String> _candidates;
  int _index = 0;
  bool _showFallback = false;

  @override
  void initState() {
    super.initState();
    _candidates = widget.app.iconUrls;
  }

  void _next() {
    if (!mounted) return;

    // Always use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Move through all candidates before showing a fallback
      if (_index < _candidates.length - 1) {
        setState(() {
          _index++;
        });
      } else {
        setState(() {
          _showFallback = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_showFallback) {
      return Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Icon(Symbols.android, color: theme.colorScheme.onSurfaceVariant),
      );
    }

    if (_index >= _candidates.length) {
      return Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Icon(Symbols.apps, color: theme.colorScheme.onSurfaceVariant),
      );
    }

    final url = _candidates[_index];
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Move to next candidate or fallback
        _next();
        return Container(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            Symbols.image_not_supported,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: theme.colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              year2023: false,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        (loadingProgress.expectedTotalBytes ?? 1)
                  : null,
            ),
          ),
        );
      },
    );
  }
}

class _DownloadButton extends StatelessWidget {
  final FDroidApp app;

  const _DownloadButton({required this.app});

  @override
  Widget build(BuildContext context) {
    if (app.latestVersion == null) {
      return const SizedBox.shrink();
    }

    return Consumer<DownloadProvider>(
      builder: (context, downloadProvider, child) {
        final version = app.latestVersion!;
        final isDownloading = downloadProvider.isDownloading(
          app.packageName,
          version.versionName,
        );
        final isDownloaded = downloadProvider.isDownloaded(
          app.packageName,
          version.versionName,
        );
        final progress = downloadProvider.getProgress(
          app.packageName,
          version.versionName,
        );

        if (isDownloading) {
          return SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              year2023: false,
            ),
          );
        }

        return IconButton(
          onPressed: () async {
            if (isDownloaded) {
              // Install APK
              try {
                final downloadInfo = downloadProvider.getDownloadInfo(
                  app.packageName,
                  version.versionName,
                );
                if (downloadInfo?.filePath != null) {
                  // Request install permission first
                  final hasPermission = await downloadProvider
                      .requestInstallPermission();
                  if (!hasPermission) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Install permission is required to install APK files',
                          ),
                        ),
                      );
                    }
                    return;
                  }

                  await downloadProvider.installApk(downloadInfo!.filePath!);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${app.name} installation started!'),
                      ),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Installation failed: ${e.toString()}'),
                    ),
                  );
                }
              }
            } else {
              // Download APK
              try {
                await downloadProvider.downloadApk(app);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${app.name} downloaded successfully!'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Download failed: ${e.toString()}')),
                  );
                }
              }
            }
          },
          icon: Icon(isDownloaded ? Symbols.install_mobile : Symbols.download),
          tooltip: isDownloaded ? 'Install' : 'Download',
        );
      },
    );
  }
}
