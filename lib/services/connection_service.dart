import 'dart:async';
import 'dart:convert';

import 'package:admincraft/models/connection_security.dart';
import 'package:admincraft/models/connection_status.dart';
import 'package:admincraft/models/model.dart';
import 'package:admincraft/services/connection_diagnosis.dart';
import 'package:admincraft/services/connection_failure.dart';
import 'package:admincraft/services/rcon_client.dart';
import 'package:admincraft/services/rcon_connection.dart';
import 'package:admincraft/services/quiet_command_filter.dart';
import 'package:admincraft/services/websocket_connector.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ConnectionService {
  /// How long to wait for the connection to be established.
  ///
  /// Without one the app waited forever: opening a socket to an address that
  /// silently drops packets never returns, and the button stayed on
  /// "Connecting" with nothing to say and nothing to press.
  static const Duration connectTimeout = Duration(seconds: 12);

  WebSocketChannel? _channel;
  RconConnection? _rcon;
  StreamSubscription? _subscription;
  final QuietCommandFilter _quietReplies = QuietCommandFilter();
  Completer<bool>? _heartbeat;
  Timer? _historyFallback;
  bool _supportsProtocol2 = false;

  /// Called when an established connection ends, with the reason if there is
  /// one. The controller decides from that whether trying again makes sense.
  void Function(Model model, ConnectionFailure? failure)? onConnectionLost;

  ConnectionStatus _status = ConnectionStatus.disconnected;
  ConnectionStatus get status => _status;

  /// Establishes the connection, or throws [ConnectionFailure] saying why not.
  ///
  /// Awaits the handshake rather than assuming it: the old code treated the
  /// channel object as success and only became "connected" once the server
  /// happened to send something, so a quiet or unreachable server was
  /// indistinguishable from a working one.
  Future<void> connect(Model model, {bool reconnect = false}) async {
    _completeConsoleHistoryLoad(model);
    // A delayed retry or rapid lifecycle transition must never leave two live
    // sockets feeding the same transcript.
    _teardown();
    _status = ConnectionStatus.connecting;

    if (model.connectionSecurity.isDirectRcon) {
      await _connectRcon(model, reconnect: reconnect);
      return;
    }

    model.beginBridgeConnection();

    String jwtToken = createJwt(
      'Admincraft',
      model.secretKey,
      edition: model.minecraftEdition.name,
      logTail: model.maxOutLines.clamp(0, 1000).toInt(),
    );

    final security = model.connectionSecurity;
    final protocol = security.usesTls ? 'wss' : 'ws';
    final uri = Uri.parse(
      '$protocol://${model.ip}:${model.port}?token=$jwtToken',
    );

    final channel = _openChannel(model, uri, security);
    _beginConsoleHistoryLoad(model);

    try {
      await channel.ready.timeout(connectTimeout);
    } catch (error) {
      _completeConsoleHistoryLoad(model);
      unawaited(channel.sink.close());
      _channel = null;
      _status = ConnectionStatus.disconnected;
      throw diagnoseConnectionError(
        error,
        security: security,
        host: model.ip,
        port: model.port,
      );
    }

    _status = ConnectionStatus.connected;
    _subscription = channel.stream.listen(
      (message) => _receive(model, message.toString()),
      onError: (error) => _endConnection(
        model,
        diagnoseConnectionError(
          error,
          security: security,
          host: model.ip,
          port: model.port,
        ),
      ),
      // The bridge reports a bad key or a mismatched edition by closing with a
      // code rather than by refusing the connection, so the reason is here.
      onDone: () => _endConnection(
        model,
        failureFromCloseCode(channel.closeCode, channel.closeReason) ??
            const ConnectionFailure(
              ConnectionFailureKind.dropped,
              'The connection to the bridge closed.',
            ),
      ),
      cancelOnError: true,
    );
  }

  WebSocketChannel _openChannel(
    Model model,
    Uri uri,
    ConnectionSecurity security,
  ) {
    try {
      return _channel = connectWebSocket(
        uri: uri,
        security: security,
        certificate: model.certificate,
      );
    } catch (error) {
      _status = ConnectionStatus.disconnected;
      throw diagnoseConnectionError(
        error,
        security: security,
        host: model.ip,
        port: model.port,
      );
    }
  }

  void _endConnection(Model model, ConnectionFailure failure) {
    _completeConsoleHistoryLoad(model);
    model.endBridgeConnection(failure.message);
    _teardown();
    onConnectionLost?.call(model, failure);
  }

  String createJwt(
    String userId,
    String secretKey, {
    required String edition,
    int logTail = 250,
  }) {
    final jwt = JWT({
      'userId': userId,
      'edition': edition,
      'protocol': 2,
      'logTail': logTail,
      'exp':
          DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
          1000,
    });
    return jwt.sign(SecretKey(secretKey));
  }

  /// Sends a command, reporting whether there was anywhere to send it.
  ///
  /// It used to swallow this, so a command typed while disconnected looked
  /// exactly like one that ran and produced no output.
  bool executeCommand(String message) {
    final rcon = _rcon;
    if (rcon != null) {
      // Echoed locally: RCON returns the reply but not the command itself.
      rcon.send(message);
      return true;
    }

    if (!isConnected()) return false;
    _channel?.sink.add(message);
    return true;
  }

  /// Sends an automatic status query and suppresses only its matching reply
  /// from visible history. The model still observes that reply first.
  bool executeQuietCommand(Model model, String message) {
    if (!isConnected()) return false;
    _quietReplies.expect(message, model.minecraftEdition);
    return executeCommand(message);
  }

  void _receive(Model model, String message) {
    try {
      final decoded = jsonDecode(message);
      if (decoded is Map<String, dynamic>) {
        switch (decoded['type']) {
          case 'admincraft.hello':
            _supportsProtocol2 = true;
            final rawCapabilities = decoded['capabilities'];
            model.updateBridgeHello(
              protocol: (decoded['protocol'] as num?)?.toInt() ?? 2,
              capabilities: rawCapabilities is List
                  ? rawCapabilities.map((value) => value.toString())
                  : const <String>[],
              version: decoded['version']?.toString(),
              permission: decoded['scope']?.toString(),
              connectedAt: DateTime.tryParse(
                decoded['connectedAt']?.toString() ?? '',
              )?.toLocal(),
            );
            return;
          case 'admincraft.pong':
            model.markBridgeHeartbeat();
            final heartbeat = _heartbeat;
            if (heartbeat != null && !heartbeat.isCompleted) {
              heartbeat.complete(true);
            }
            return;
          case 'admincraft.history-complete':
            _completeConsoleHistoryLoad(model);
            return;
          case 'admincraft.history-error':
            final detail = decoded['message'];
            if (detail is String && detail.trim().isNotEmpty) {
              model.recordBridgeError(detail);
              model.appendOutputCommand(detail);
            }
            return;
          case 'admincraft.server-state':
            final state = decoded['state'];
            if (state is String && state.trim().isNotEmpty) {
              model.updateServerRuntimeState(
                state,
                observedAt: DateTime.tryParse(
                  decoded['observedAt']?.toString() ?? '',
                )?.toLocal(),
                daytime: (decoded['daytime'] as num?)?.toInt(),
                playersOnline: (decoded['playersOnline'] as num?)?.toInt(),
                playerLimit: (decoded['playerLimit'] as num?)?.toInt(),
                onlinePlayers: decoded['onlinePlayers'] is List
                    ? (decoded['onlinePlayers'] as List).map(
                        (player) => player.toString(),
                      )
                    : null,
              );
            }
            return;
          case 'admincraft.log':
            final line = decoded['message'];
            if (line is String && line.trim().isNotEmpty) {
              model.markBridgeLogReceived();
              model.appendOutputCommand(
                line,
                visible: !_quietReplies.shouldHide(line),
                eventId: decoded['id']?.toString(),
              );
            }
            return;
        }
      }
    } on FormatException {
      // Legacy bridges send plain text. Keep accepting it during rollout.
    }

    // A legacy bridge has no explicit history boundary. Its greeting or first
    // output proves that the initial connection wait is over.
    model.markLegacyBridgeConnected();
    _completeConsoleHistoryLoad(model);

    for (final line in message.split('\n')) {
      if (line.trim().isEmpty) continue;
      if (RegExp(
        r'^Admincraft connected to (?:bedrock|java) bridge \([^)]*\)$',
        caseSensitive: false,
      ).hasMatch(line.trim())) {
        continue;
      }
      model.appendOutputCommand(line, visible: !_quietReplies.shouldHide(line));
    }
  }

  /// Verifies a protocol-v2 bridge without destroying a socket that survived
  /// backgrounding. Legacy bridges have no heartbeat command, so their stream
  /// state remains the best available signal until they are upgraded.
  Future<bool> checkAlive({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    if (!isConnected()) return false;
    if (_rcon != null || !_supportsProtocol2) return true;

    final existing = _heartbeat;
    if (existing != null && !existing.isCompleted) return existing.future;

    final heartbeat = Completer<bool>();
    _heartbeat = heartbeat;
    _channel?.sink.add('admincraft ping');
    try {
      return await heartbeat.future.timeout(timeout);
    } on TimeoutException {
      return false;
    } finally {
      if (identical(_heartbeat, heartbeat)) _heartbeat = null;
    }
  }

  /// Talks to the Minecraft server directly, with no bridge.
  ///
  /// RCON answers commands but never pushes anything, so there is no log to
  /// stream: the output shown is only what commands reply with.
  Future<void> _connectRcon(Model model, {bool reconnect = false}) async {
    _completeConsoleHistoryLoad(model);
    final RconConnection rcon;
    try {
      rcon = await connectRcon(
        host: model.ip,
        port: model.port,
        password: model.secretKey,
      ).timeout(connectTimeout);
    } on RconAuthException {
      _status = ConnectionStatus.disconnected;
      throw const ConnectionFailure(
        ConnectionFailureKind.rejected,
        'RCON rejected the password. It must match rcon.password in '
        'server.properties.',
      );
    } on RconUnsupportedException catch (error) {
      _status = ConnectionStatus.disconnected;
      throw ConnectionFailure(ConnectionFailureKind.unsupported, error.message);
    } catch (error) {
      _status = ConnectionStatus.disconnected;
      throw diagnoseConnectionError(
        error,
        security: model.connectionSecurity,
        host: model.ip,
        port: model.port,
      );
    }

    _rcon = rcon;
    _status = ConnectionStatus.connected;

    _subscription = rcon.responses.listen(
      (response) => _receive(model, response),
      onError: (Object error) => _endConnection(
        model,
        diagnoseConnectionError(
          error,
          security: model.connectionSecurity,
          host: model.ip,
          port: model.port,
        ),
      ),
      onDone: () => _endConnection(
        model,
        const ConnectionFailure(
          ConnectionFailureKind.dropped,
          'The RCON connection closed.',
        ),
      ),
      cancelOnError: true,
    );

    // Nothing arrives unprompted, so say something rather than leaving the
    // terminal blank and looking unconnected.
    model.appendOutputCommand(
      'Connected over RCON. Command replies appear here; RCON cannot stream the server log.',
    );
  }

  /// Closes the connection on purpose. Nothing is reported: the user did it.
  void disconnect(Model model) {
    _completeConsoleHistoryLoad(model);
    model.endBridgeConnection();
    _teardown();
  }

  void _beginConsoleHistoryLoad(Model model) {
    model.beginConsoleHistoryLoad();
    _historyFallback?.cancel();
    // Protocol 2 originally shipped without an explicit completion event.
    // Keep those bridges from leaving a quiet console spinning forever.
    _historyFallback = Timer(
      const Duration(seconds: 3),
      () => model.completeConsoleHistoryLoad(),
    );
  }

  void _completeConsoleHistoryLoad(Model model) {
    _historyFallback?.cancel();
    _historyFallback = null;
    model.completeConsoleHistoryLoad();
  }

  void _teardown() {
    _status = ConnectionStatus.disconnected;
    _subscription?.cancel();
    _channel?.sink.close();
    _rcon?.close();
    _subscription = null;
    _channel = null;
    _rcon = null;
    _supportsProtocol2 = false;
    final heartbeat = _heartbeat;
    if (heartbeat != null && !heartbeat.isCompleted) heartbeat.complete(false);
    _heartbeat = null;
    _historyFallback?.cancel();
    _historyFallback = null;
    _quietReplies.clear();
  }

  bool isConnected() {
    if (_rcon != null) return _subscription != null;
    return _channel != null && _subscription != null;
  }
}
