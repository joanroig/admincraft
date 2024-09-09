import 'dart:async';
import 'dart:io'; // For SecurityContext

import 'package:admincraft/models/connection_status.dart';
import 'package:admincraft/models/model.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/io.dart'; // For IOWebSocketChannel

class ConnectionService {
  IOWebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Function? onConnectionLost; // Callback to handle connection loss
  ConnectionStatus _status = ConnectionStatus.disconnected;
  ConnectionStatus get status => _status;
  SecurityContext? _context;

// Initialize SecurityContext for custom certificate
  Future<void> _initSecurityContext(String certificateData) async {
    _context = SecurityContext(withTrustedRoots: false);
    try {
      // Convert the certificate string to bytes
      _context!.setTrustedCertificatesBytes(Uint8List.fromList(certificateData.codeUnits));
    } catch (e) {
      print('Error loading certificate: $e');
    }
  }

  Future<void> connect(Model model, {bool reconnect = false}) async {
    _status = ConnectionStatus.connecting;
    String jwtToken = createJwt('Admincraft', model.secretKey);

    // Determine protocol and URI
    final useWss = model.certificate.isNotEmpty;
    final protocol = useWss ? 'wss' : 'ws';
    final uri = Uri.parse('$protocol://${model.ip}:${model.port}?token=$jwtToken');

    // Initialize security context if using wss
    if (useWss && _context == null) {
      await _initSecurityContext(model.certificate);
    }

    // Connect using the appropriate protocol
    try {
      _channel = IOWebSocketChannel.connect(
        uri,
        customClient: useWss ? HttpClient(context: _context) : null,
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

  String createJwt(String userId, String secretKey) {
    final jwt = JWT({
      'userId': userId,
      'exp': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
    });
    return jwt.sign(SecretKey(secretKey));
  }

  void executeCommand(String message) {
    if (isConnected()) {
      _channel?.sink.add(message);
    } else {
      print('WebSocket is not connected.');
    }
  }

  void disconnect(Model model, {bool reconnect = false}) {
    _status = ConnectionStatus.disconnected;
    _subscription?.cancel();
    _channel?.sink.close();
    _subscription = null;
    _channel = null;
    // Notify the model or update the state
    if (onConnectionLost != null) {
      onConnectionLost!(model, reconnect); // Notify controller
    }
  }

  bool isConnected() {
    return _channel != null && _subscription != null;
  }
}
