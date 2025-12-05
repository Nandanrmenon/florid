import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class PermissionsScreen extends StatelessWidget {
  final List<String> permissions;
  final String appName;

  const PermissionsScreen({
    super.key,
    required this.permissions,
    required this.appName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$appName - Permissions'), centerTitle: false),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: permissions.length,
        itemBuilder: (context, index) {
          final permission = permissions[index];
          return ListTile(
            leading: Icon(
              Symbols.security,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(permission),
          );
        },
      ),
    );
  }
}
