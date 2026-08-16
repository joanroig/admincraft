import 'dart:async';

import 'package:admincraft/models/connection_security.dart';
import 'package:admincraft/models/connection_status.dart';
import 'package:admincraft/models/model.dart';
import 'package:admincraft/services/connection_diagnosis.dart';
import 'package:admincraft/services/connection_failure.dart';
import 'package:admincraft/services/rcon_client.dart';
import 'package:admincraft/services/rcon_connection.dart';
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
    _status = ConnectionStatus.connecting;

    if (model.connectionSecurity.isDirectRcon) {
      await _connectRcon(model, reconnect: reconnect);
      return;
    }

    String jwtToken = createJwt(
      'Admincraft',
      model.secretKey,
      edition: model.minecraftEdition.name,
    );

    final security = model.connectionSecurity;
    final protocol = security.usesTls ? 'wss' : 'ws';
    final uri =
        Uri.parse('$protocol://${model.ip}:${model.port}?token=$jwtToken');

    final channel = _openChannel(model, uri, security);

    try {
      await channel.ready.timeout(connectTimeout);
    } catch (error) {
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
      (message) => model.appendOutputCommand(message),
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
    _teardown();
    onConnectionLost?.call(model, failure);
  }

  String createJwt(
    String userId,
    String secretKey, {
    required String edition,
  }) {
    final jwt = JWT({
      'userId': userId,
      'edition': edition,
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

  /// Talks to the Minecraft server directly, with no bridge.
  ///
  /// RCON answers commands but never pushes anything, so there is no log to
  /// stream: the output shown is only what commands reply with.
  Future<void> _connectRcon(Model model, {bool reconnect = false}) async {
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
      throw ConnectionFailure(
          ConnectionFailureKind.unsupported, error.message);
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
      (response) => model.appendOutputCommand(response),
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
        'Connected over RCON. Command replies appear here; RCON cannot stream the server log.');
  }

  /// Closes the connection on purpose. Nothing is reported: the user did it.
  void disconnect(Model model) => _teardown();

  void _teardown() {
    _status = ConnectionStatus.disconnected;
    _subscription?.cancel();
    _channel?.sink.close();
    _rcon?.close();
    _subscription = null;
    _channel = null;
    _rcon = null;
  }

  bool isConnected() {
    if (_rcon != null) return _subscription != null;
    return _channel != null && _subscription != null;
  }
}
