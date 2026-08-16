import 'dart:async';

import 'package:admincraft/models/connection_status.dart';
import 'package:admincraft/models/model.dart';
import 'package:admincraft/services/connection_failure.dart';
import 'package:admincraft/services/connection_service.dart';
import 'package:admincraft/services/retry_policy.dart';
import 'package:admincraft/utils/toast_utils.dart';
import 'package:flutter/material.dart';

class ConnectionController with ChangeNotifier {
  /// How many times a connection worth retrying is retried before the app
  /// stops and leaves it to the user.
  ///
  /// Retrying is only useful while the cause might pass on its own. The old
  /// code retried anything once and reported every failure as "connection
  /// lost", including a rejected key, which cannot fix itself.
  static const int maxRetries = 3;

  final ConnectionService connectionService = ConnectionService();
  ConnectionStatus get status => connectionService.status;

  int _retries = 0;
  Timer? _retryTimer;

  /// The last thing that went wrong, kept so a view can show it instead of
  /// only flashing a toast that may be missed.
  ConnectionFailure? lastFailure;

  ConnectionController() {
    connectionService.onConnectionLost = _handleConnectionLost;
  }

  Future<void> attemptConnection(Model model, {bool reconnect = false}) async {
    _retryTimer?.cancel();

    // A profile missing an address or a key cannot connect, so say so once
    // rather than letting the transport fail and schedule retries.
    if (!model.selectedServer.isComplete) {
      if (!reconnect) {
        ToastUtils.showToastError(
            'This server is not set up yet. Add its address and key first.');
      }
      return;
    }

    if (status == ConnectionStatus.connected) {
      ToastUtils.showToastError('Already connected.');
      return;
    }

    if (!reconnect) _retries = 0;
    lastFailure = null;
    notifyListeners();

    try {
      await connectionService.connect(model, reconnect: reconnect);
      _retries = 0;
      lastFailure = null;
      if (reconnect) ToastUtils.showToastSuccess('Reconnected.');
    } on ConnectionFailure catch (failure) {
      _reportAndMaybeRetry(model, failure);
    } catch (error) {
      _reportAndMaybeRetry(
        model,
        ConnectionFailure(ConnectionFailureKind.unknown, error.toString()),
      );
    } finally {
      notifyListeners();
    }
  }

  /// Reports the failure, and schedules another attempt when [decideRetry]
  /// says one is worth making.
  void _reportAndMaybeRetry(Model model, ConnectionFailure failure) {
    lastFailure = failure;

    final decision = decideRetry(
      failure: failure,
      attemptsMade: _retries,
      maxRetries: maxRetries,
    );
    ToastUtils.showToastError(decision.message);

    if (!decision.willRetry) {
      _retries = 0;
      return;
    }

    _retries++;
    _retryTimer = Timer(decision.delay!, () {
      attemptConnection(model, reconnect: true);
    });
  }

  Future<void> toggleConnection(Model model) async {
    _retryTimer?.cancel();
    _retries = 0;

    if (status == ConnectionStatus.connected) {
      connectionService.disconnect(model);
      lastFailure = null;
      notifyListeners();
      return;
    }

    await attemptConnection(model);
  }

  void _handleConnectionLost(Model model, ConnectionFailure? failure) {
    notifyListeners();
    if (failure == null) return;
    _reportAndMaybeRetry(model, failure);
    notifyListeners();
  }

  Future<void> disconnect(Model model) async {
    _retryTimer?.cancel();
    _retries = 0;
    connectionService.disconnect(model);
    notifyListeners();
  }

  Future<void> restartServer(Model model) async {
    try {
      connectionService.executeCommand('admincraft restart-server');
      ToastUtils.showToastSuccess(
          'Server restart initiated, reconnecting in 5 seconds...');
      await disconnect(model);
      await Future.delayed(const Duration(seconds: 5));
      await attemptConnection(model, reconnect: true);
    } catch (e) {
      ToastUtils.showToastError(e.toString());
    }
  }

  Future<void> executeMinecraftCommand(Model model, String command) async {
    model.addUserCommand(command);
    model.recordCommandUsage(command);
    model.appendOutputCommand(command);
    if (!connectionService.executeCommand(command)) {
      // In the terminal rather than a toast: that is where the user is
      // looking, and silence there reads as a command that ran and said
      // nothing.
      model.appendOutputCommand('Not connected: the command was not sent.');
    }
  }

  /// Sends a command without echoing it or saving it.
  ///
  /// Used for the queries that keep the control panel in sync, which would
  /// otherwise bury the terminal and the saved-command list under dozens of
  /// entries the user never typed.
  Future<void> sendQuietly(String command) async {
    connectionService.executeCommand(command);
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }
}
