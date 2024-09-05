import 'dart:async';

import 'package:admincraft/controllers/connection_controller.dart';
import 'package:admincraft/models/connection_status.dart';
import 'package:admincraft/models/model.dart';
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

  @override
  Widget build(BuildContext context) {
    final connectionController = Provider.of<ConnectionController>(context);
    final model = Provider.of<Model>(context);

    String statusText;
    Color statusColor;

    switch (connectionController.status) {
      case ConnectionStatus.connected:
        statusText = model.alias;
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
        title: const Text('Admincraft'),
        actions: [
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
                SettingsTab(onSettingsSaved: () {
                  connectionController.disconnect(model);
                  connectionController.attemptConnection(model);
                }),
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
