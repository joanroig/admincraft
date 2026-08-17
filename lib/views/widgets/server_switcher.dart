import 'package:admincraft/models/model.dart';
import 'package:admincraft/models/server_profile.dart';
import 'package:flutter/material.dart';
import 'package:admincraft/views/widgets/server_icon.dart';

class ServerSwitcher extends StatelessWidget {
  static const String _addServerValue = '__add_server__';

  final Model model;
  final Future<void> Function(String serverId) onSelect;
  final Future<void> Function() onAdd;
  final bool compact;

  const ServerSwitcher({
    super.key,
    required this.model,
    required this.onSelect,
    required this.onAdd,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = model.selectedServer;

    return PopupMenuButton<String>(
      tooltip: 'Switch server',
      onSelected: (value) async {
        if (value == _addServerValue) {
          await onAdd();
        } else if (value != model.selectedServerId) {
          await onSelect(value);
        }
      },
      itemBuilder: (context) => [
        for (final server in model.servers)
          PopupMenuItem<String>(
            value: server.id,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ServerIcon(server: server),
              title: Text(
                server.alias.isEmpty ? 'Unnamed server' : server.alias,
              ),
              subtitle: Text(server.edition.label),
            ),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: _addServerValue,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.add_circle_outline),
            title: Text('Add server'),
            subtitle: Text('Create a new server profile'),
          ),
        ),
      ],
      child: Container(
        width: compact ? null : double.infinity,
        constraints: compact ? const BoxConstraints(maxWidth: 240) : null,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 6 : 10,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
          children: [
            ServerIcon(server: selected, size: compact ? 20 : 32),
            const SizedBox(width: 9),
            if (compact)
              Flexible(child: _serverLabel(theme, selected))
            else
              Expanded(child: _serverLabel(theme, selected)),
            const SizedBox(width: 4),
            const Icon(Icons.unfold_more, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _serverLabel(ThemeData theme, ServerProfile selected) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        selected.alias.isEmpty ? 'Unnamed server' : selected.alias,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleSmall,
      ),
      if (!compact)
        Text(
          selected.edition.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall,
        ),
    ],
  );
}
