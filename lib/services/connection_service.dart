import 'dart:async';

import 'package:admincraft/models/connection_security.dart';
import 'package:admincraft/models/connection_status.dart';
import 'package:admincraft/models/model.dart';
import 'package:admincraft/services/rcon_client.dart';
import 'package:admincraft/services/rcon_connection.dart';
import 'package:admincraft/services/websocket_connector.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ConnectionService {
  WebSocketChannel? _channel;
  RconConnection? _rcon;
  StreamSubscription? _subscription;
  Function? onConnectionLost; // Callback to handle connection loss
  ConnectionStatus _status = ConnectionStatus.disconnected;
  ConnectionStatus get status => _status;

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

    // Determine protocol and URI
    final security = model.connectionSecurity;
    final protocol = security.usesTls ? 'wss' : 'ws';
    final uri =
        Uri.parse('$protocol://${model.ip}:${model.port}?token=$jwtToken');

    // Connect using whichever WebSocket the platform provides
    try {
      _channel = connectWebSocket(
        uri: uri,
        security: security,
        certificate: model.certificate,
      );

      // Listen for incoming messages
      _subscription = _channel?.stream.listen(
        (message) {
          _status = ConnectionStatus.connected;
          print('New message: $message');
          model.appendOutputCommand(message);
        },
        onError: (error) {
          print('Error: $error');
          disconnect(model, reconnect: true);
        },
        onDone: () {
          print('Connection closed.');
          disconnect(model, reconnect: reconnect);
        },
        cancelOnError: true,
      );
    } catch (e) {
      print('WebSocket connection error: $e');
    }
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

  void executeCommand(String message) {
    final rcon = _rcon;
    if (rcon != null) {
      // Echoed locally: RCON returns the reply but not the command itself.
      rcon.send(message);
      return;
    }

    if (isConnected()) {
      _channel?.sink.add(message);
    } else {
      print('WebSocket is not connected.');
    }
  }

  /// Talks to the Minecraft server directly, with no bridge.
  ///
  /// RCON answers commands but never pushes anything, so there is no log to
  /// stream: the output shown is only what commands reply with.
  Future<void> _connectRcon(Model model, {bool reconnect = false}) async {
    try {
      final rcon = await connectRcon(
        host: model.ip,
        port: model.port,
        password: model.secretKey,
      );
      _rcon = rcon;
      _status = ConnectionStatus.connected;

      _subscription = rcon.responses.listen(
        (response) {
          _status = ConnectionStatus.connected;
          model.appendOutputCommand(response);
        },
        onError: (Object error) {
          model.appendOutputCommand('RCON error: $error');
          disconnect(model, reconnect: true);
        },
        onDone: () => disconnect(model, reconnect: reconnect),
        cancelOnError: true,
      );

      // Nothing arrives unprompted, so say something rather than leaving the
      // terminal blank and looking unconnected.
      model.appendOutputCommand(
          'Connected over RCON. Command replies appear here; RCON cannot stream the server log.');
    } on RconAuthException {
      model.appendOutputCommand('RCON rejected the password.');
      disconnect(model);
    } on RconUnsupportedException catch (e) {
      model.appendOutputCommand(e.message);
      disconnect(model);
    } catch (e) {
      model.appendOutputCommand('Could not reach RCON at ${model.ip}:${model.port} ($e)');
      disconnect(model);
    }
  }

  void disconnect(Model model, {bool reconnect = false}) {
    _status = ConnectionStatus.disconnected;
    _subscription?.cancel();
    _channel?.sink.close();
    _rcon?.close();
    _subscription = null;
    _channel = null;
    _rcon = null;
    // Notify the model or update the state
    if (onConnectionLost != null) {
      onConnectionLost!(model, reconnect); // Notify controller
    }
  }

  bool isConnected() {
    if (_rcon != null) return _subscription != null;
    return _channel != null && _subscription != null;
  }
}
