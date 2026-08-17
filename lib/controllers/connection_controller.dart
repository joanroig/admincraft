import 'dart:async';

import 'package:admincraft/models/connection_security.dart';
import 'package:admincraft/models/connection_status.dart';
import 'package:admincraft/models/model.dart';
import 'package:admincraft/services/connection_failure.dart';
import 'package:admincraft/services/connection_platform_capabilities.dart';
import 'package:admincraft/services/connection_service.dart';
import 'package:admincraft/services/console_output_formatter.dart';
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
  final ConnectionPlatformCapabilities capabilities;
  ConnectionStatus get status => connectionService.status;

  int _retries = 0;
  Timer? _retryTimer;
  Timer? _initialStatusTimer;
  Timer? _statusTimer;
  bool _statusRefreshInFlight = false;
  Future<void>? _connectionAttempt;
  bool _resumeCheckInFlight = false;
  Model? _model;
  bool _keepConnected = false;
  bool _wasBackgrounded = false;

  /// The last thing that went wrong, kept so a view can show it instead of
  /// only flashing a toast that may be missed.
  ConnectionFailure? lastFailure;

  ConnectionController({
    ConnectionService? connectionService,
    this.capabilities = currentConnectionPlatformCapabilities,
  }) : connectionService = connectionService ?? ConnectionService() {
    this.connectionService.onConnectionLost = _handleConnectionLost;
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> attemptConnection(
    Model model, {
    bool reconnect = false,
    bool announce = true,
  }) {
    final active = _connectionAttempt;
    if (active != null) return active;

    final attempt = _attemptConnection(
      model,
      reconnect: reconnect,
      announce: announce,
    );
    _connectionAttempt = attempt;
    return attempt.whenComplete(() {
      if (identical(_connectionAttempt, attempt)) _connectionAttempt = null;
    });
  }

  Future<void> _attemptConnection(
    Model model, {
    required bool reconnect,
    required bool announce,
  }) async {
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

    final platformFailure = compatibilityFailure(model);
    if (platformFailure != null) {
      _keepConnected = false;
      lastFailure = platformFailure;
      notifyListeners();
      return;
    }

    if (status == ConnectionStatus.connected) {
      if (announce && !reconnect) {
        ToastUtils.showToastError('Already connected.');
      }
      return;
    }

    if (!reconnect) _retries = 0;
    lastFailure = null;
    notifyListeners();

    try {
      await connectionService.connect(model, reconnect: reconnect);
      _retries = 0;
      lastFailure = null;
      if (announce) {
        ToastUtils.showInfo(
          reconnect ? 'Reconnected' : 'Connected',
          '${model.alias} is connected.',
        );
      }
      _startStatusMonitoring();
    } on ConnectionFailure catch (failure) {
      _reportAndMaybeRetry(model, failure, quiet: !announce);
    } catch (error) {
      _reportAndMaybeRetry(
        model,
        ConnectionFailure(ConnectionFailureKind.unknown, error.toString()),
        quiet: !announce,
      );
    } finally {
      notifyListeners();
    }
  }

  ConnectionFailure? compatibilityFailure(Model model) =>
      capabilities.failureFor(model.connectionSecurity, model.minecraftEdition);

  /// Reports the failure, and schedules another attempt when [decideRetry]
  /// says one is worth making.
  void _reportAndMaybeRetry(
    Model model,
    ConnectionFailure failure, {
    bool quiet = false,
  }) {
    lastFailure = failure;

    if (_wasBackgrounded) {
      return;
    }

    final decision = decideRetry(
      failure: failure,
      attemptsMade: _retries,
      maxRetries: maxRetries,
    );
    // Automatic startup/resume recovery stays quiet while it is making
    // progress. A final failure is still surfaced because user action is then
    // required; all attempts remain available through controller state.
    if (!quiet || !decision.willRetry) {
      ToastUtils.showToastError(decision.message);
    }

    if (!decision.willRetry) {
      _retries = 0;
      return;
    }

    _retries++;
    _retryTimer = Timer(decision.delay!, () {
      attemptConnection(model, reconnect: true, announce: !quiet);
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
    if (_wasBackgrounded) {
      lastFailure = failure;
      notifyListeners();
      return;
    }
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

    unawaited(_resumeConnection(model));
  }

  Future<void> _resumeConnection(Model model) async {
    if (_resumeCheckInFlight) return;
    _resumeCheckInFlight = true;
    try {
      // Browsers commonly throttle a hidden tab without actually losing its
      // socket. Probe it first; reconnect only when the bridge does not answer.
      if (status == ConnectionStatus.connected &&
          await connectionService.checkAlive()) {
        lastFailure = null;
        _startStatusMonitoring();
        notifyListeners();
        return;
      }

      connectionService.disconnect(model);
      notifyListeners();
      await attemptConnection(model, reconnect: true, announce: false);
    } finally {
      _resumeCheckInFlight = false;
    }
  }

  Future<void> restartServer(Model model) async {
    await _manageServer(
      model,
      'restart',
      'Server restart initiated.',
      resumeMonitoringAfter: const Duration(seconds: 5),
    );
  }

  Future<void> startServer(Model model) async {
    await _manageServer(
      model,
      'start',
      'Server start initiated.',
      resumeMonitoringAfter: const Duration(seconds: 4),
    );
  }

  Future<void> stopServer(Model model) async {
    await _manageServer(model, 'stop', 'Server stop initiated.');
  }

  Future<void> _manageServer(
    Model model,
    String action,
    String successMessage, {
    Duration? resumeMonitoringAfter,
  }) async {
    _statusTimer?.cancel();
    final command = 'admincraft $action-server';
    if (!model.supportsBridgeCapability(action)) {
      ToastUtils.showToastError(
        'This bridge credential cannot $action the server.',
      );
      await model.recordCommandAudit(
        command,
        source: 'control',
        outcome: 'permission denied',
      );
      return;
    }
    if (!connectionService.executeCommand(command)) {
      ToastUtils.showToastError('The bridge is not connected.');
      await model.recordCommandAudit(
        command,
        source: 'control',
        outcome: 'not sent',
      );
      return;
    }
    await model.recordCommandAudit(command, source: 'control', outcome: 'sent');
    ToastUtils.showToastSuccess(successMessage);
    if (resumeMonitoringAfter != null) {
      await Future.delayed(resumeMonitoringAfter);
      if (_keepConnected && status == ConnectionStatus.connected) {
        _startStatusMonitoring();
      }
    }
  }

  Future<void> executeMinecraftCommand(
    Model model,
    String command, {
    String source = 'terminal',
  }) async {
    // User commands carry a private marker while stored in the transcript.
    // Never allow that presentation metadata to cross the command boundary,
    // even if a saved transcript row or pasted value reaches this method.
    command = ConsoleOutputFormatter.stripUserCommandMarker(command);
    final bridgeDiagnostic = command.toLowerCase().startsWith('admincraft ');
    if (!bridgeDiagnostic &&
        !model.connectionSecurity.isDirectRcon &&
        !model.supportsBridgeCapability('commands')) {
      model.appendOutputCommand(
        'Permission denied: this bridge credential is read-only.',
      );
      await model.recordCommandAudit(
        command,
        source: source,
        outcome: 'permission denied',
      );
      return;
    }
    await model.addUserCommand(command);
    await model.recordCommandUsage(command);
    model.appendOutputCommand(command, isUserCommand: true);
    final sent = connectionService.executeCommand(command);
    await model.recordCommandAudit(
      command,
      source: source,
      outcome: sent ? 'sent' : 'not sent',
    );
    if (!sent) {
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
    _initialStatusTimer?.cancel();
    _statusTimer?.cancel();
    // Give a protocol-v2 bridge time to advertise a read-only credential
    // before issuing Minecraft status commands that scope cannot run.
    _initialStatusTimer = Timer(
      const Duration(milliseconds: 250),
      () => unawaited(_refreshServerStatus()),
    );
    _statusTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(_refreshServerStatus()),
    );
  }

  Future<void> _refreshServerStatus() async {
    if (_statusRefreshInFlight || status != ConnectionStatus.connected) return;
    final model = _model;
    if (model != null &&
        model.bridgeProtocol != null &&
        model.supportsBridgeCapability('state')) {
      return;
    }
    if (model != null &&
        !model.connectionSecurity.isDirectRcon &&
        !model.supportsBridgeCapability('commands')) {
      return;
    }
    _statusRefreshInFlight = true;
    try {
      await sendQuietly('time query daytime');
      if (status == ConnectionStatus.connected) await sendQuietly('list');
    } finally {
      _statusRefreshInFlight = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _retryTimer?.cancel();
    _initialStatusTimer?.cancel();
    _statusTimer?.cancel();
    super.dispose();
  }
}
