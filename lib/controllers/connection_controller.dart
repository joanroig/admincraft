import 'dart:async';

import 'package:admincraft/models/connection_status.dart';
import 'package:admincraft/models/model.dart';
import 'package:admincraft/services/connection_failure.dart';
import 'package:admincraft/services/connection_service.dart';
import 'package:admincraft/services/retry_policy.dart';
import 'package:admincraft/utils/toast_utils.dart';
import 'package:flutter/material.dart';

class ConnectionController with ChangeNotifier, WidgetsBindingObserver {
  /// How many times a connection worth retrying is retried before the app
  /// stops and leaves it to the user.
  ///
  /// Retrying is only useful while the cause might pass on its own. The old
  /// code retried anything once and reported every failure as "connection
  /// lost", including a rejected key, which cannot fix itself.
  static const int maxRetries = 3;

  final ConnectionService connectionService;
  ConnectionStatus get status => connectionService.status;

  int _retries = 0;
  Timer? _retryTimer;
  Timer? _statusTimer;
  bool _statusRefreshInFlight = false;
  Model? _model;
  bool _keepConnected = false;
  bool _wasBackgrounded = false;

  /// The last thing that went wrong, kept so a view can show it instead of
  /// only flashing a toast that may be missed.
  ConnectionFailure? lastFailure;

  ConnectionController({ConnectionService? connectionService})
    : connectionService = connectionService ?? ConnectionService() {
    this.connectionService.onConnectionLost = _handleConnectionLost;
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> attemptConnection(Model model, {bool reconnect = false}) async {
    _model = model;
    _keepConnected = true;
    _retryTimer?.cancel();

    // A profile missing an address or a key cannot connect, so say so once
    // rather than letting the transport fail and schedule retries.
    if (!model.selectedServer.isComplete) {
      if (!reconnect) {
        ToastUtils.showToastError(
          'This server is not set up yet. Add its address and key first.',
        );
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
      ToastUtils.showInfo(
        reconnect ? 'Reconnected' : 'Connected',
        '${model.alias} is connected.',
      );
      _startStatusMonitoring();
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

    if (_wasBackgrounded) {
      ToastUtils.showToastError(
        '${failure.message} Admincraft will reconnect when you return.',
      );
      return;
    }

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
      _keepConnected = false;
      _statusTimer?.cancel();
      connectionService.disconnect(model);
      lastFailure = null;
      ToastUtils.showInfo('Disconnected', '${model.alias} was disconnected.');
      notifyListeners();
      return;
    }

    await attemptConnection(model);
  }

  void _handleConnectionLost(Model model, ConnectionFailure? failure) {
    _statusTimer?.cancel();
    notifyListeners();
    if (failure == null) return;
    _reportAndMaybeRetry(model, failure);
    notifyListeners();
  }

  Future<void> disconnect(Model model) async {
    _keepConnected = false;
    _retryTimer?.cancel();
    _statusTimer?.cancel();
    _retries = 0;
    connectionService.disconnect(model);
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _wasBackgrounded = true;
      _retryTimer?.cancel();
      _statusTimer?.cancel();
      return;
    }

    if (state != AppLifecycleState.resumed || !_wasBackgrounded) return;
    _wasBackgrounded = false;
    final model = _model;
    if (!_keepConnected || model == null || !model.selectedServer.isComplete) {
      return;
    }

    // Mobile operating systems may suspend sockets while an app is hidden.
    // Replace the possibly stale transport immediately on resume instead of
    // waiting for the next command to discover it died.
    connectionService.disconnect(model);
    notifyListeners();
    unawaited(attemptConnection(model, reconnect: true));
  }

  Future<void> restartServer(Model model) async {
    try {
      connectionService.executeCommand('admincraft restart-server');
      ToastUtils.showToastSuccess(
        'Server restart initiated, reconnecting in 5 seconds...',
      );
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
    final model = _model;
    if (model != null) connectionService.executeQuietCommand(model, command);
  }

  void _startStatusMonitoring() {
    _statusTimer?.cancel();
    unawaited(_refreshServerStatus());
    _statusTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(_refreshServerStatus()),
    );
  }

  Future<void> _refreshServerStatus() async {
    if (_statusRefreshInFlight || status != ConnectionStatus.connected) return;
    _statusRefreshInFlight = true;
    try {
      await sendQuietly('time query daytime');
      await Future.delayed(const Duration(milliseconds: 300));
      if (status == ConnectionStatus.connected) await sendQuietly('list');
    } finally {
      _statusRefreshInFlight = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _retryTimer?.cancel();
    _statusTimer?.cancel();
    super.dispose();
  }
}
