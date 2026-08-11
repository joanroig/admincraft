import 'dart:async';

import 'package:admincraft/controllers/connection_controller.dart';
import 'package:admincraft/models/connection_status.dart';
import 'package:admincraft/models/model.dart';
import 'package:admincraft/utils/url_utils.dart';
import 'package:admincraft/views/control_tab_view.dart';
import 'package:admincraft/views/data_sync_view.dart';
import 'package:admincraft/views/more_view.dart';
import 'package:admincraft/views/overview_view.dart';
import 'package:admincraft/views/preferences_view.dart';
import 'package:admincraft/views/server_editor_view.dart';
import 'package:admincraft/views/servers_view.dart';
import 'package:admincraft/views/terminal_tab_view.dart';
import 'package:admincraft/views/widgets/server_switcher.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum _WorkspaceDestination {
  overview,
  console,
  controls,
  servers,
  serverEditor,
  dataSync,
  preferences,
  more,
}

extension on _WorkspaceDestination {
  String get label => switch (this) {
        _WorkspaceDestination.overview => 'Overview',
        _WorkspaceDestination.console => 'Console',
        _WorkspaceDestination.controls => 'Controls',
        _WorkspaceDestination.servers => 'Servers',
        _WorkspaceDestination.serverEditor => 'Edit server',
        _WorkspaceDestination.dataSync => 'Data & Sync',
        _WorkspaceDestination.preferences => 'Preferences',
        _WorkspaceDestination.more => 'More',
      };

  IconData get icon => switch (this) {
        _WorkspaceDestination.overview => Icons.dashboard_outlined,
        _WorkspaceDestination.console => Icons.terminal,
        _WorkspaceDestination.controls => Icons.tune,
        _WorkspaceDestination.servers => Icons.dns_outlined,
        _WorkspaceDestination.serverEditor => Icons.edit_outlined,
        _WorkspaceDestination.dataSync => Icons.sync_outlined,
        _WorkspaceDestination.preferences => Icons.settings_outlined,
        _WorkspaceDestination.more => Icons.more_horiz,
      };
}

class Tabs extends StatefulWidget {
  const Tabs({super.key});

  @override
  State<Tabs> createState() => _TabsState();
}

class _TabsState extends State<Tabs> {
  static const double _desktopBreakpoint = 820;
  late Future<void> _initializationFuture;
  _WorkspaceDestination _destination = _WorkspaceDestination.overview;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initialize();
  }

  Future<void> _initialize() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final model = context.read<Model>();
      if (model.selectedServer.isComplete) {
        context
            .read<ConnectionController>()
            .attemptConnection(model, reconnect: false);
      }
    });
  }

  void _go(_WorkspaceDestination destination) {
    setState(() => _destination = destination);
  }

  Future<void> _selectServer(String id) async {
    final model = context.read<Model>();
    final connection = context.read<ConnectionController>();
    await connection.disconnect(model);
    await model.selectServer(id);
    if (!mounted) return;
    _go(_WorkspaceDestination.overview);
    if (model.selectedServer.isComplete) {
      await connection.attemptConnection(model);
    }
  }

  Future<void> _addServer() async {
    final model = context.read<Model>();
    final connection = context.read<ConnectionController>();
    await connection.disconnect(model);
    await model.addServer();
    if (!mounted) return;
    _go(_WorkspaceDestination.serverEditor);
  }

  Future<void> _serverSaved() async {
    final model = context.read<Model>();
    final connection = context.read<ConnectionController>();
    await connection.disconnect(model);
    if (model.selectedServer.isComplete) {
      await connection.attemptConnection(model);
    }
  }

  Future<void> _serverDeleted() async {
    final model = context.read<Model>();
    final connection = context.read<ConnectionController>();
    await connection.disconnect(model);
    if (!mounted) return;
    _go(_WorkspaceDestination.servers);
    if (model.selectedServer.isComplete) {
      await connection.attemptConnection(model);
    }
  }

  Future<void> _serversImported() async {
    final model = context.read<Model>();
    final connection = context.read<ConnectionController>();
    await connection.disconnect(model);
    if (model.selectedServer.isComplete) {
      await connection.attemptConnection(model);
    }
  }

  List<Widget> _pages(Model model, ConnectionController connection) => [
        OverviewView(
          onOpenConsole: () => _go(_WorkspaceDestination.console),
          onOpenControls: () => _go(_WorkspaceDestination.controls),
          onEditServer: () => _go(_WorkspaceDestination.serverEditor),
        ),
        TerminalTab(
          isEnabled: connection.status == ConnectionStatus.connected,
        ),
        ControlTab(
          isEnabled: connection.status == ConnectionStatus.connected,
        ),
        ServersView(
          onSelect: _selectServer,
          onAdd: _addServer,
          onEditSelected: () => _go(_WorkspaceDestination.serverEditor),
        ),
        ServerEditorView(
          key: ValueKey(model.selectedServerId),
          onSaved: _serverSaved,
          onDeleted: _serverDeleted,
        ),
        DataSyncView(onServersChanged: _serversImported),
        const PreferencesView(),
        MoreView(
          onServers: () => _go(_WorkspaceDestination.servers),
          onDataSync: () => _go(_WorkspaceDestination.dataSync),
          onPreferences: () => _go(_WorkspaceDestination.preferences),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final model = context.watch<Model>();
    final connection = context.watch<ConnectionController>();

    return FutureBuilder<void>(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= _desktopBreakpoint;
            return desktop
                ? _buildDesktop(context, model, connection)
                : _buildMobile(context, model, connection);
          },
        );
      },
    );
  }

  Widget _buildDesktop(
    BuildContext context,
    Model model,
    ConnectionController connection,
  ) {
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 224,
            child: _WorkspaceSidebar(
              model: model,
              destination: _destination,
              onDestination: _go,
              onSelectServer: _selectServer,
              onAddServer: _addServer,
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                _WorkspaceHeader(
                  destination: _destination,
                  model: model,
                  connection: connection,
                  onEditServer: () => _go(_WorkspaceDestination.serverEditor),
                ),
                const Divider(height: 1),
                Expanded(
                  child: IndexedStack(
                    index: _destination.index,
                    children: _pages(model, connection),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobile(
    BuildContext context,
    Model model,
    ConnectionController connection,
  ) {
    final secondary = {
      _WorkspaceDestination.servers,
      _WorkspaceDestination.serverEditor,
      _WorkspaceDestination.dataSync,
      _WorkspaceDestination.preferences,
    }.contains(_destination);

    return Scaffold(
      appBar: AppBar(
        leading: secondary
            ? IconButton(
                tooltip: 'Back to More',
                onPressed: () => _go(_WorkspaceDestination.more),
                icon: const Icon(Icons.arrow_back),
              )
            : null,
        titleSpacing: secondary ? 0 : 12,
        title: secondary
            ? Text(_destination.label)
            : ServerSwitcher(
                model: model,
                compact: true,
                onSelect: _selectServer,
                onAdd: _addServer,
              ),
        actions: [
          _ConnectionAction(model: model, connection: connection),
          IconButton(
            tooltip: 'Documentation',
            onPressed: () => UrlUtils.openDocumentation(),
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: IndexedStack(
        index: _destination.index,
        children: _pages(model, connection),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _mobileIndex,
        onDestinationSelected: (index) => _go(switch (index) {
          0 => _WorkspaceDestination.overview,
          1 => _WorkspaceDestination.console,
          2 => _WorkspaceDestination.controls,
          _ => _WorkspaceDestination.more,
        }),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.terminal_outlined),
            selectedIcon: Icon(Icons.terminal),
            label: 'Console',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Controls',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }

  int get _mobileIndex => switch (_destination) {
        _WorkspaceDestination.overview => 0,
        _WorkspaceDestination.console => 1,
        _WorkspaceDestination.controls => 2,
        _ => 3,
      };
}

class _WorkspaceSidebar extends StatelessWidget {
  final Model model;
  final _WorkspaceDestination destination;
  final ValueChanged<_WorkspaceDestination> onDestination;
  final Future<void> Function(String) onSelectServer;
  final Future<void> Function() onAddServer;

  const _WorkspaceSidebar({
    required this.model,
    required this.destination,
    required this.onDestination,
    required this.onSelectServer,
    required this.onAddServer,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerLow,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 6, 14),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      width: 30,
                      height: 30,
                      filterQuality: FilterQuality.none,
                      isAntiAlias: false,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Admincraft',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
              ServerSwitcher(
                model: model,
                onSelect: onSelectServer,
                onAdd: onAddServer,
              ),
              const SizedBox(height: 16),
              const _SectionLabel(label: 'Server'),
              _NavigationTile(
                destination: _WorkspaceDestination.overview,
                selected: destination == _WorkspaceDestination.overview,
                onTap: onDestination,
              ),
              _NavigationTile(
                destination: _WorkspaceDestination.console,
                selected: destination == _WorkspaceDestination.console,
                onTap: onDestination,
              ),
              _NavigationTile(
                destination: _WorkspaceDestination.controls,
                selected: destination == _WorkspaceDestination.controls,
                onTap: onDestination,
              ),
              _NavigationTile(
                destination: _WorkspaceDestination.servers,
                selected: destination == _WorkspaceDestination.servers ||
                    destination == _WorkspaceDestination.serverEditor,
                onTap: onDestination,
              ),
              const Spacer(),
              const _SectionLabel(label: 'Application'),
              _NavigationTile(
                destination: _WorkspaceDestination.dataSync,
                selected: destination == _WorkspaceDestination.dataSync,
                onTap: onDestination,
              ),
              _NavigationTile(
                destination: _WorkspaceDestination.preferences,
                selected: destination == _WorkspaceDestination.preferences,
                onTap: onDestination,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkspaceHeader extends StatelessWidget {
  final _WorkspaceDestination destination;
  final Model model;
  final ConnectionController connection;
  final VoidCallback onEditServer;

  const _WorkspaceHeader({
    required this.destination,
    required this.model,
    required this.connection,
    required this.onEditServer,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    destination.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    model.ip.isEmpty
                        ? model.selectedServer.edition.label
                        : '${model.selectedServer.edition.label} · ${model.ip}:${model.port}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            _StatusLabel(status: connection.status),
            const SizedBox(width: 8),
            if (destination != _WorkspaceDestination.serverEditor)
              OutlinedButton.icon(
                onPressed: onEditServer,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit server'),
              ),
            const SizedBox(width: 8),
            _ConnectionAction(model: model, connection: connection),
            IconButton(
              tooltip: 'Documentation',
              onPressed: () => UrlUtils.openDocumentation(),
              icon: const Icon(Icons.help_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationTile extends StatelessWidget {
  final _WorkspaceDestination destination;
  final bool selected;
  final ValueChanged<_WorkspaceDestination> onTap;

  const _NavigationTile({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          dense: true,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          selected: selected,
          selectedTileColor: Theme.of(context).colorScheme.secondaryContainer,
          leading: Icon(destination.icon, size: 21),
          title: Text(destination.label),
          onTap: () => onTap(destination),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 5),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  final ConnectionStatus status;

  const _StatusLabel({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ConnectionStatus.connected => ('Connected', Colors.green),
      ConnectionStatus.connecting => ('Connecting', Colors.orange),
      ConnectionStatus.disconnected => ('Disconnected', Colors.red),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelLarge),
      ],
    );
  }
}

class _ConnectionAction extends StatelessWidget {
  final Model model;
  final ConnectionController connection;

  const _ConnectionAction({required this.model, required this.connection});

  @override
  Widget build(BuildContext context) {
    final connected = connection.status == ConnectionStatus.connected;
    final connecting = connection.status == ConnectionStatus.connecting;
    return IconButton.filledTonal(
      tooltip: connected ? 'Disconnect' : 'Connect',
      onPressed: connecting ? null : () => connection.toggleConnection(model),
      icon: connecting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(connected ? Icons.stop_rounded : Icons.play_arrow_rounded),
    );
  }
}
