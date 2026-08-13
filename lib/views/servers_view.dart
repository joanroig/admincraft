import 'package:admincraft/controllers/connection_controller.dart';
import 'package:admincraft/models/connection_status.dart';
import 'package:admincraft/models/model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ServersView extends StatelessWidget {
  final Future<void> Function(String serverId) onSelect;
  final Future<void> Function() onAdd;
  final VoidCallback onEditSelected;

  const ServersView({
    super.key,
    required this.onSelect,
    required this.onAdd,
    required this.onEditSelected,
  });

  @override
  Widget build(BuildContext context) {
    final model = context.watch<Model>();
    final connection = context.watch<ConnectionController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Servers',
                            style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 4),
                        Text(
                          'Choose a server or create another profile.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add),
                    label: const Text('Add server'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              for (final server in model.servers) ...[
                Card(
                  color: server.id == model.selectedServerId
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    leading: CircleAvatar(
                      child: Icon(server.edition.name == 'java'
                          ? Icons.coffee_outlined
                          : Icons.view_in_ar_outlined),
                    ),
                    title: Text(
                        server.alias.isEmpty ? 'Unnamed server' : server.alias),
                    subtitle: Text(
                      '${server.edition.label} · ${server.ip.isEmpty ? 'Not configured' : '${server.ip}:${server.port}'}',
                    ),
                    trailing: Wrap(
                      spacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (server.id == model.selectedServerId)
                          _ConnectionChip(status: connection.status),
                        IconButton(
                          tooltip: server.id == model.selectedServerId
                              ? 'Edit server'
                              : 'Select and edit',
                          onPressed: () async {
                            if (server.id != model.selectedServerId) {
                              await onSelect(server.id);
                            }
                            onEditSelected();
                          },
                          icon: const Icon(Icons.edit_outlined),
                        ),
                      ],
                    ),
                    onTap: server.id == model.selectedServerId
                        ? null
                        : () => onSelect(server.id),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionChip extends StatelessWidget {
  final ConnectionStatus status;

  const _ConnectionChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      ConnectionStatus.connected => 'Connected',
      ConnectionStatus.connecting => 'Connecting',
      ConnectionStatus.disconnected => 'Selected',
    };
    final icon = switch (status) {
      ConnectionStatus.connected => Icons.check_circle_outline,
      ConnectionStatus.connecting => Icons.sync,
      ConnectionStatus.disconnected => Icons.radio_button_checked,
    };
    return Chip(avatar: Icon(icon, size: 16), label: Text(label));
  }
}
