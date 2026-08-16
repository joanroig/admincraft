import 'package:admincraft/controllers/connection_controller.dart';
import 'package:admincraft/models/connection_status.dart';
import 'package:admincraft/models/model.dart';
import 'package:admincraft/models/server_profile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admincraft/views/widgets/server_icon.dart';

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
              // The heading and the button share a row only when there is
              // room. Side by side on a phone, the button took enough width to
              // wrap the sentence beside it into a narrow column.
              LayoutBuilder(
                builder: (context, constraints) {
                  final heading = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Servers',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose a server or create another profile.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  );
                  final add = FilledButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add),
                    label: const Text('Add server'),
                  );

                  if (constraints.maxWidth < 520) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [heading, const SizedBox(height: 12), add],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: heading),
                      add,
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              for (final server in model.servers) ...[
                _ServerTile(
                  server: server,
                  selected: server.id == model.selectedServerId,
                  status: connection.status,
                  onSelect: () => onSelect(server.id),
                  onEdit: () async {
                    if (server.id != model.selectedServerId) {
                      await onSelect(server.id);
                    }
                    onEditSelected();
                  },
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

/// One saved server.
///
/// Kept deliberately compact on phones: connection state lives beside the
/// title instead of taking a full row below the address.
class _ServerTile extends StatelessWidget {
  final ServerProfile server;
  final bool selected;
  final ConnectionStatus status;
  final VoidCallback onSelect;
  final VoidCallback onEdit;

  const _ServerTile({
    required this.server,
    required this.selected,
    required this.status,
    required this.onSelect,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final address = server.ip.isEmpty
        ? 'Not configured'
        : '${server.ip}:${server.port}';

    return Card(
      margin: EdgeInsets.zero,
      color: selected ? theme.colorScheme.primaryContainer : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: selected ? null : onSelect,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: ServerIcon(server: server, size: 34),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            server.alias.isEmpty
                                ? 'Unnamed server'
                                : server.alias,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        if (selected) ...[
                          const SizedBox(width: 8),
                          _ConnectionLabel(status: status),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          server.edition.label,
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Tooltip(
                            message: address,
                            child: Text(
                              address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: selected ? 'Edit server' : 'Select and edit',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionLabel extends StatelessWidget {
  final ConnectionStatus status;

  const _ConnectionLabel({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      ConnectionStatus.connected => 'Connected',
      ConnectionStatus.connecting => 'Connecting',
      ConnectionStatus.disconnected => 'Selected',
    };
    final color = switch (status) {
      ConnectionStatus.connected => Colors.green,
      ConnectionStatus.connecting => Colors.orange,
      ConnectionStatus.disconnected => Theme.of(context).colorScheme.outline,
    };
    return Semantics(
      label: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
