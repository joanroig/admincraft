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
/// Not a ListTile: its trailing widget takes whatever width it wants, and a
/// status chip beside an edit button left the address a five-line column on a
/// phone. Here the text spans the card and the chip sits under it, so the
/// address stays on one line and is truncated rather than stacked.
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
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(child: ServerIcon(server: server, size: 28)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      server.alias.isEmpty ? 'Unnamed server' : server.alias,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      server.edition.label,
                      style: theme.textTheme.bodySmall,
                    ),
                    // Truncated from the left: the port and the end of a
                    // hostname distinguish two profiles, the leading label
                    // rarely does.
                    Tooltip(
                      message: address,
                      child: Text(
                        address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.rtl,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    if (selected) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _ConnectionChip(status: status),
                      ),
                    ],
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
