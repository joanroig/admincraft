import 'dart:async';

import 'package:admincraft/models/model.dart';
import 'package:admincraft/services/connection_service.dart';
import 'package:admincraft/utils/toast_utils.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';

class ConnectionController with ChangeNotifier {
  final ConnectionService _connectionService = ConnectionService();
  bool _isConnecting = false;

  bool get isConnecting => _isConnecting;
  SSHClient? get sshClient => _connectionService.sshClient;

  ConnectionController() {
    _connectionService.startConnectionCheck();
  }

  Future<void> attemptConnection(Model model, {bool startup = false}) async {
    if (model.hostname.isEmpty || model.username.isEmpty || model.pemKeyContent.isEmpty) {
      if (!startup) {
        ToastUtils.showToastError("Cannot connect, missing connection details.");
      }
    } else if (_connectionService.sshClient != null) {
      ToastUtils.showToastError("Already connected!");
    } else {
      await _connectionService.connectAndFetchLogs(model);
      _connectionService.streamLogs(model);
    }
  }

  Future<void> toggleConnection(Model model) async {
    _isConnecting = true;
    notifyListeners();

    try {
      if (_connectionService.sshClient != null) {
        await _connectionService.disconnect();
      } else {
        await _connectionService.connectAndFetchLogs(model);
        _connectionService.streamLogs(model);
      }
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    await _connectionService.disconnect();
    notifyListeners();
  }

  Future<void> restartServer(Model model) async {
    try {
      await _connectionService.executeCommand('sudo docker compose restart');
      ToastUtils.showToastSuccess('Server restarted successfully');
      attemptConnection(model);
      notifyListeners();
    } catch (e) {
      ToastUtils.showToastError(e.toString());
    }
  }

  Future<String> executeMinecraftCommand(Model model, String command) async {
    model.addUserCommand(command);
    model.appendOutputCommand(command);
    return _connectionService.executeCommandWithPrefix(command, model.commandPrefix);
  }

  @override
  void dispose() {
    _connectionService.stopConnections();
    super.dispose();
  }
}
