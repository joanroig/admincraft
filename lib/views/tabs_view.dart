import 'dart:async';

import 'package:admincraft/controllers/connection_controller.dart';
import 'package:admincraft/models/connection_status.dart';
import 'package:admincraft/models/model.dart';
import 'package:admincraft/utils/url_utils.dart';
import 'package:admincraft/views/control_tab_view.dart';
import 'package:admincraft/views/settings_tab_view.dart';
import 'package:admincraft/views/terminal_tab_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Tabs extends StatefulWidget {
  const Tabs({super.key});

  @override
  State<Tabs> createState() => _TabsState();
}

class _TabsState extends State<Tabs> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializationFuture = _initialize();
  }

  Future<void> _initialize() async {
    // Defer connection attempt until after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final model = Provider.of<Model>(context, listen: false);
      final connectionController = Provider.of<ConnectionController>(context, listen: false);
      connectionController.attemptConnection(model, reconnect: false);
    });
  }

  /// Reconnects against whatever server is now selected. Switching profile
  /// changes the host and credentials, so an open socket has to be dropped.
  Future<void> _reconnect(Model model, ConnectionController connection) async {
    connection.disconnect(model);
    await connection.attemptConnection(model);
  }

  /// Server picker in the title, listing saved servers plus an entry to add
  /// one. Kept in the app bar so it is reachable from every tab.
  Widget _buildServerSelector(BuildContext context, Model model, ConnectionController connection) {
    return PopupMenuButton<String>(
      tooltip: 'Select server',
      onSelected: (value) async {
        if (value == _addServerValue) {
          await model.addServer();
          if (!context.mounted) return;
          connection.disconnect(model);
          _tabController.animateTo(2); // Settings, to fill the new server in
          return;
        }
        await model.selectServer(value);
        if (!context.mounted) return;
        await _reconnect(model, connection);
      },
      itemBuilder: (context) => [
        for (final server in model.servers)
          PopupMenuItem(
            value: server.id,
            child: Row(
              children: [
                Icon(
                  server.id == model.selectedServerId ? Icons.check : Icons.dns_outlined,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Flexible(child: Text(server.alias.isEmpty ? 'Unnamed' : server.alias)),
              ],
            ),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: _addServerValue,
          child: Row(
            children: [
              Icon(Icons.add, size: 18),
              SizedBox(width: 8),
              Text('Add new server'),
            ],
          ),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pixel art at its native 16px: nearest neighbour keeps the edges
          // hard instead of blurring them when scaled up.
          Image.asset(
            'assets/logo.png',
            width: 26,
            height: 26,
            filterQuality: FilterQuality.none,
            isAntiAlias: false,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              model.alias.isEmpty ? 'Admincraft' : model.alias,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }

  static const String _addServerValue = '__add_server__';

  @override
  Widget build(BuildContext context) {
    final connectionController = Provider.of<ConnectionController>(context);
    final model = Provider.of<Model>(context);

    String statusText;
    Color statusColor;

    switch (connectionController.status) {
      case ConnectionStatus.connected:
        // The title already names the server, so the status only reports state.
        statusText = 'Connected';
        statusColor = Colors.green;
        break;
      case ConnectionStatus.connecting:
        statusText = 'Connecting...';
        statusColor = Colors.orange;
        break;
      case ConnectionStatus.disconnected:
      default:
        statusText = 'Disconnected';
        statusColor = Colors.red;
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: _buildServerSelector(context, model, connectionController),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Open documentation',
            onPressed: () => UrlUtils.openDocumentation(),
          ),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: connectionController.status == ConnectionStatus.connected
                    ? const Icon(Icons.stop_circle_rounded, color: Colors.red)
                    : const Icon(Icons.play_circle_rounded, color: Colors.green),
                // Disable button when connecting
                onPressed: connectionController.status == ConnectionStatus.connecting ? null : () => connectionController.toggleConnection(model),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Terminal'),
            Tab(text: 'Control Panel'),
            Tab(text: 'Settings'),
          ],
        ),
      ),
      body: FutureBuilder<void>(
        future: _initializationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Disable TabBarView when connecting
          return AbsorbPointer(
            absorbing: connectionController.status == ConnectionStatus.connecting, // Disable interaction while connecting
            child: TabBarView(
              controller: _tabController,
              children: [
                TerminalTab(isEnabled: connectionController.status == ConnectionStatus.connected),
                ControlTab(isEnabled: connectionController.status == ConnectionStatus.connected),
                // Keyed by server: the form holds its values in State, so
                // switching profile has to rebuild it or it would keep showing
                // the previous server's details.
                SettingsTab(
                  key: ValueKey(model.selectedServerId),
                  onSettingsSaved: () {
                    connectionController.disconnect(model);
                    connectionController.attemptConnection(model);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
