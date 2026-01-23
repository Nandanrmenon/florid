import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../models/repository.dart';
import '../providers/app_provider.dart';
import '../providers/repositories_provider.dart';
import '../services/fdroid_api_service.dart';

class RepositoriesScreen extends StatefulWidget {
  const RepositoriesScreen({super.key});

  @override
  State<RepositoriesScreen> createState() => _RepositoriesScreenState();
}

class _RepositoriesScreenState extends State<RepositoriesScreen> {
  @override
  void initState() {
    super.initState();
    // Load repositories when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RepositoriesProvider>().loadRepositories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Repositories')),
      body: Consumer<RepositoriesProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Error message if any
              if (provider.error != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Material(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Icon(Symbols.error, color: Colors.red.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              provider.error ?? 'Unknown error',
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Symbols.close),
                            onPressed: provider.clearError,
                            color: Colors.red.shade700,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // Repositories list
              Expanded(
                child: provider.repositories.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Symbols.inbox,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No repositories added',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add a custom F-Droid repository to get started',
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: provider.repositories.length,
                        itemBuilder: (context, index) {
                          final repo = provider.repositories[index];
                          return _RepositoryListItem(repository: repo);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRepositoryDialog(context),
        tooltip: 'Add Repository',
        child: const Icon(Symbols.add),
      ),
    );
  }

  void _showAddRepositoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AddRepositoryDialog(
        onAdd: (name, url) async {
          // Close the add dialog, then run the add flow with a blocking progress dialog.
          Navigator.pop(context);
          await _runRepositoryActionWithDialog(context, () async {
            final repoProvider = context.read<RepositoriesProvider>();
            final apiService = context.read<FDroidApiService>();
            final appProvider = context.read<AppProvider>();

            await repoProvider.addRepository(name, url);
            await apiService.clearRepositoryCache();
            await appProvider.refreshAll(repositoriesProvider: repoProvider);
          });
        },
      ),
    );
  }
}

class _RepositoryListItem extends StatelessWidget {
  final Repository repository;

  const _RepositoryListItem({required this.repository});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<RepositoriesProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Card(
        child: Column(
          children: [
            ListTile(
              leading: Icon(
                repository.isEnabled ? Symbols.cloud_done : Symbols.cloud_off,
                color: repository.isEnabled ? Colors.green : Colors.grey,
              ),
              title: Text(repository.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    repository.url,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (repository.lastSyncedAt != null)
                    Text(
                      'Last synced: ${_formatDate(repository.lastSyncedAt!)}',
                      style: const TextStyle(fontSize: 11),
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: repository.isEnabled,
                    onChanged: (_) async {
                      await _toggleRepositoryWithDialog(
                        context,
                        provider,
                        repository.id,
                      );
                    },
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      switch (value) {
                        case 'toggle':
                          await _toggleRepositoryWithDialog(
                            context,
                            provider,
                            repository.id,
                          );
                          break;
                        case 'edit':
                          _showEditRepositoryDialog(context, repository);
                          break;
                        case 'delete':
                          _showDeleteConfirmation(
                            context,
                            repository,
                            provider,
                          );
                          break;
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text('Enable/Disable'),
                      ),
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditRepositoryDialog(BuildContext context, Repository repository) {
    showDialog(
      context: context,
      builder: (context) => _EditRepositoryDialog(
        repository: repository,
        onSave: (name, url) {
          context.read<RepositoriesProvider>().updateRepository(
            repository.id,
            name,
            url,
            repository.isEnabled,
          );
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    Repository repository,
    RepositoriesProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Repository'),
        content: Text('Are you sure you want to remove "${repository.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteRepository(repository.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 30) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

Future<void> _toggleRepositoryWithDialog(
  BuildContext context,
  RepositoriesProvider provider,
  int repositoryId,
) async {
  final apiService = context.read<FDroidApiService>();
  final appProvider = context.read<AppProvider>();
  final progress = ValueNotifier<double>(0.0);

  // Show a blocking dialog and execute the toggle inside it so the dialog stays up.
  await showDialog(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (dialogContext) {
      // // Kick off the async work after the dialog is built.
      Future.microtask(() async {
        try {
          progress.value = 0.1;
          await provider.toggleRepository(repositoryId);
          progress.value = 0.4;
          await apiService.clearRepositoryCache();
          progress.value = 0.7;
          await appProvider.refreshAll(repositoriesProvider: provider);
          progress.value = 1.0;
        } finally {
          if (Navigator.of(dialogContext, rootNavigator: true).canPop()) {
            Navigator.of(dialogContext, rootNavigator: true).pop();
          }
        }
      });

      return AlertDialog(
        title: const Text('Updating Repository'),
        icon: Icon(Symbols.sync, size: 32),
        content: ValueListenableBuilder<double>(
          valueListenable: progress,
          builder: (_, value, __) {
            final pct = (value * 100).clamp(0, 100).round();
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text('Now is a great time to touch grass!'),
                SizedBox(height: 16),
                LinearProgressIndicator(
                  value: value == 0.0 ? null : value,
                  year2023: false,
                ),
                const SizedBox(height: 8),
                Text('$pct%', textAlign: TextAlign.right),
              ],
            );
          },
        ),
      );
    },
  );
}

Future<void> _runRepositoryActionWithDialog(
  BuildContext context,
  Future<void> Function() action,
) async {
  final progress = ValueNotifier<double>(0.0);

  await showDialog(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (dialogContext) {
      Future.microtask(() async {
        try {
          progress.value = 0.2;
          await action();
          progress.value = 1.0;
        } finally {
          if (Navigator.of(dialogContext, rootNavigator: true).canPop()) {
            Navigator.of(dialogContext, rootNavigator: true).pop();
          }
        }
      });

      return AlertDialog(
        title: const Text('Updating Repository'),
        icon: Icon(Symbols.sync, size: 32),
        content: ValueListenableBuilder<double>(
          valueListenable: progress,
          builder: (_, value, __) {
            final pct = (value * 100).clamp(0, 100).round();
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text('Now is a great time to touch grass!'),
                SizedBox(height: 16),
                LinearProgressIndicator(
                  value: value == 0.0 ? null : value,
                  year2023: false,
                ),
                const SizedBox(height: 8),
                Text('$pct%', textAlign: TextAlign.right),
              ],
            );
          },
        ),
      );
    },
  );
}

class _AddRepositoryDialog extends StatefulWidget {
  final Function(String name, String url) onAdd;

  const _AddRepositoryDialog({required this.onAdd});

  @override
  State<_AddRepositoryDialog> createState() => _AddRepositoryDialogState();
}

class _AddRepositoryDialogState extends State<_AddRepositoryDialog> {
  late TextEditingController _nameController;
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _urlController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Repository'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Repository Name',
                hintText: 'e.g., IzzyOnDroid',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Repository URL',
                hintText: 'https://example.com',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'URL format: https://repo.example.com (we\'ll add /repo/index-v2.json automatically)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _addRepository, child: const Text('Add')),
      ],
    );
  }

  void _addRepository() {
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a repository name')),
      );
      return;
    }

    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a repository URL')),
      );
      return;
    }

    widget.onAdd(name, url);
  }
}

class _EditRepositoryDialog extends StatefulWidget {
  final Repository repository;
  final Function(String name, String url) onSave;

  const _EditRepositoryDialog({required this.repository, required this.onSave});

  @override
  State<_EditRepositoryDialog> createState() => _EditRepositoryDialogState();
}

class _EditRepositoryDialogState extends State<_EditRepositoryDialog> {
  late TextEditingController _nameController;
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.repository.name);
    _urlController = TextEditingController(text: widget.repository.url);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Repository'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Repository Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Repository URL',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _saveRepository, child: const Text('Save')),
      ],
    );
  }

  void _saveRepository() {
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a repository name')),
      );
      return;
    }

    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a repository URL')),
      );
      return;
    }

    widget.onSave(name, url);
  }
}
