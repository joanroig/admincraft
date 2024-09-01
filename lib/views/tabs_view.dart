import 'dart:async';

import 'package:admincraft/controllers/connection_controller.dart';
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
    final model = Provider.of<Model>(context, listen: false);
    final connectionController = Provider.of<ConnectionController>(context, listen: false);
    // Attempt a connection on startup
    connectionController.attemptConnection(model, startup: true);
  }

  @override
  Widget build(BuildContext context) {
    final connectionController = Provider.of<ConnectionController>(context);
    final model = Provider.of<Model>(context);
    final isConnected = connectionController.sshClient != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admincraft'),
        actions: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Text(
                  connectionController.isConnecting
                      ? 'Connecting...'
                      : isConnected
                          ? model.alias
                          : 'Disconnected',
                  style: TextStyle(
                    color: connectionController.isConnecting
                        ? Colors.orange
                        : isConnected
                            ? Colors.green
                            : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: isConnected
                    ? const Icon(Icons.stop_circle_rounded, color: Colors.red)
                    : const Icon(Icons.play_circle_rounded, color: Colors.green),
                onPressed: connectionController.isConnecting ? null : () => connectionController.toggleConnection(model),
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
          return TabBarView(
            controller: _tabController,
            children: [
              TerminalTab(isEnabled: isConnected),
              ControlTab(isEnabled: isConnected),
              SettingsTab(onSettingsSaved: () {
                connectionController.disconnect();
                connectionController.attemptConnection(model);
              }),
            ],
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
