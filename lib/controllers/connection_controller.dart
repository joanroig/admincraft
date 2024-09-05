import 'package:admincraft/models/connection_status.dart';
import 'package:admincraft/models/model.dart';
import 'package:admincraft/services/connection_service.dart';
import 'package:admincraft/utils/toast_utils.dart';
import 'package:flutter/material.dart';

class ConnectionController with ChangeNotifier {
  final ConnectionService connectionService = ConnectionService();
  ConnectionStatus get status => connectionService.status;
  int reconnectCount = 0;

  ConnectionController() {
    connectionService.onConnectionLost = (Model model, bool reconnect) => _handleConnectionLost(model, reconnect);
  }

  Future<void> attemptConnection(Model model, {bool reconnect = false}) async {
    if (model.ip.isEmpty || model.secretKey.isEmpty) {
      if (!reconnect) {
        ToastUtils.showToastError("Cannot connect, missing connection details.");
      }
    } else if (status == ConnectionStatus.connected) {
      ToastUtils.showToastError("Already connected!");
    } else {
      connectionService.connect(model, reconnect: reconnect);
    }
  }

  Future<void> toggleConnection(Model model) async {
    reconnectCount = 0;

    try {
      if (status == ConnectionStatus.connected) {
        connectionService.disconnect(model);
      } else {
        await attemptConnection(model);
      }
    } finally {
      notifyListeners();
    }
  }

  void _handleConnectionLost(Model model, bool reconnect) {
    if (reconnect) {
      if (reconnectCount == 0) {
        reconnectCount++;
        ToastUtils.showToastError("Connection lost, reconnecting in 5 seconds...");
        Future.delayed(const Duration(seconds: 5), () {
          attemptConnection(model, reconnect: reconnect);
        });
      } else {
        ToastUtils.showToastError("Connection lost, please connect again.");
      }
      notifyListeners();
    }
  }

  Future<void> disconnect(Model model) async {
    connectionService.disconnect(model);
    notifyListeners();
  }

  Future<void> restartServer(Model model) async {
    try {
      connectionService.executeCommand('admincraft restart-server');
      ToastUtils.showToastSuccess('Server restart initiated, reconnecting in 5 seconds...');
      disconnect(model);
      await Future.delayed(const Duration(seconds: 5));
      attemptConnection(model, reconnect: true);
      notifyListeners();
    } catch (e) {
      ToastUtils.showToastError(e.toString());
    }
  }

  Future<void> executeMinecraftCommand(Model model, String command) async {
    model.addUserCommand(command);
    model.appendOutputCommand(command);
    connectionService.executeCommand(command);
  }

  @override
  void dispose() {
    // webSocketService.disconnect(model);
    super.dispose();
  }
}
