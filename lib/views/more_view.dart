import 'package:flutter/material.dart';

class MoreView extends StatelessWidget {
  final VoidCallback onServers;
  final VoidCallback onDataSync;
  final VoidCallback onPreferences;
  final VoidCallback onDocumentation;

  const MoreView({
    super.key,
    required this.onServers,
    required this.onDataSync,
    required this.onPreferences,
    required this.onDocumentation,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('More', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Manage servers, portable data, preferences, and help.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.dns_outlined),
                title: const Text('Servers'),
                subtitle: const Text('Add, switch, and edit server profiles'),
                trailing: const Icon(Icons.chevron_right),
                onTap: onServers,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.sync_outlined),
                title: const Text('Data & Sync'),
                subtitle: const Text('Encrypted backup and transfer'),
                trailing: const Icon(Icons.chevron_right),
                onTap: onDataSync,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Preferences'),
                subtitle: const Text('Theme, font, and console behavior'),
                trailing: const Icon(Icons.chevron_right),
                onTap: onPreferences,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Docs'),
                subtitle: const Text('Setup guides and feature reference'),
                trailing: const Icon(Icons.open_in_new),
                onTap: onDocumentation,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
