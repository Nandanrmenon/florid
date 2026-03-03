import 'package:app_installer/app_installer.dart';
import 'package:florid/l10n/app_localizations.dart';
import 'package:florid/providers/app_update_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdatePage extends StatefulWidget {
  const AppUpdatePage({super.key});

  @override
  State<AppUpdatePage> createState() => _AppUpdatePageState();
}

class _AppUpdatePageState extends State<AppUpdatePage> {
  bool _isInstalling = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appUpdateAvailable),
      ),
      body: Consumer<AppUpdateProvider>(
        builder: (context, updateProvider, _) {
          final update = updateProvider.availableUpdate;

          if (update == null) {
            return Center(
              child: Text(AppLocalizations.of(context)!.downloadFailed),
            );
          }

          return CustomScrollView(
            slivers: [
              // Header section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        spacing: 24,
                        children: [
                          Icon(
                            Symbols.system_update,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary,
                          ),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'v${update.version}',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              Text(
                                'Update available',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                    ),
                              ),
                              Text(
                                _formatDate(update.releaseDate),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Progress indicator if downloading
                      if (updateProvider.isDownloading)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: updateProvider.downloadProgress,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${(updateProvider.downloadProgress * 100).toStringAsFixed(1)}% downloaded',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline,
                                  ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),

                      // Error message if any
                      if (updateProvider.downloadError != null)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Symbols.error,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Error',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.error,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    updateProvider.downloadError!,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.error,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextButton(
                    onPressed: (updateProvider.isDownloading || _isInstalling)
                        ? null
                        : () async {
                            final update = updateProvider.availableUpdate;
                            if (update != null) {
                              await _launchReleaseUrl(
                                context,
                                update.releaseUrl,
                              );
                            }
                          },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(AppLocalizations.of(context)!.viewOnGithub),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: const SizedBox(height: 24)),
              // Release Notes section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    AppLocalizations.of(context)!.releaseNotes,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Html(
                      data: update.releaseNotes,
                      style: {
                        "body": Style(
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                          fontSize: FontSize(
                            Theme.of(context).textTheme.bodyMedium?.fontSize ??
                                14,
                          ),
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        "p": Style(margin: Margins.only(bottom: 8)),
                        "a": Style(
                          color: Theme.of(context).colorScheme.primary,
                          textDecoration: TextDecoration.underline,
                        ),
                      },
                      onLinkTap: (url, attributes, element) {
                        if (url != null) {
                          launchUrl(Uri.parse(url));
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: Consumer<AppUpdateProvider>(
          builder: (context, updateProvider, _) {
            return Row(
              spacing: 8.0,
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: updateProvider.isDownloading
                        ? null
                        : () {
                            Navigator.pop(context);
                            updateProvider.dismissUpdate();
                          },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(AppLocalizations.of(context)!.dismiss),
                    ),
                  ),
                ),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: (updateProvider.isDownloading || _isInstalling)
                        ? null
                        : () async {
                            await _handleUpdate(context, updateProvider);
                          },
                    icon: Icon(
                      _isInstalling
                          ? Symbols.downloading
                          : updateProvider.isDownloading
                          ? Symbols.downloading
                          : Symbols.system_update,
                    ),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        _isInstalling
                            ? AppLocalizations.of(context)!.installing
                            : updateProvider.isDownloading
                            ? AppLocalizations.of(context)!.downloading
                            : AppLocalizations.of(context)!.update,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleUpdate(
    BuildContext context,
    AppUpdateProvider updateProvider,
  ) async {
    setState(() => _isInstalling = true);

    try {
      final filePath = await updateProvider.downloadUpdate();

      if (!mounted) return;

      if (filePath != null) {
        // Install the downloaded APK
        await AppInstaller.installApk(filePath);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.downloadFailed),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isInstalling = false);
      }
    }
  }

  Future<void> _launchReleaseUrl(BuildContext context, String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open link: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
