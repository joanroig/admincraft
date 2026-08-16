import 'dart:convert';

import 'package:admincraft/controllers/connection_controller.dart';
import 'package:admincraft/models/connection_security.dart';
import 'package:admincraft/models/connection_status.dart';
import 'package:admincraft/models/model.dart';
import 'package:admincraft/models/server_profile.dart';
import 'package:admincraft/services/connection_service.dart';
import 'package:admincraft/services/connection_failure.dart';
import 'package:admincraft/services/connection_platform_capabilities.dart';
import 'package:admincraft/services/persistence_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('a connection monitors status through quiet commands', (
    tester,
  ) async {
    const server = ServerProfile(
      id: 'test',
      alias: 'Test server',
      ip: 'server.test',
      port: 8080,
      secretKey: 'secret',
      certificate: '',
      security: ConnectionSecurity.privateNetwork,
    );
    SharedPreferences.setMockInitialValues({
      'servers': [jsonEncode(server.toJson())],
      'selectedServer': server.id,
      'onboardingCompleted': true,
    });
    final preferences = await SharedPreferences.getInstance();
    final model = Model(PersistenceService(preferences));
    final service = _RecordingConnectionService();
    final controller = ConnectionController(connectionService: service);

    await controller.attemptConnection(model);
    await tester.pump(const Duration(milliseconds: 400));

    expect(service.quietCommands, ['time query daytime', 'list']);
    expect(service.regularCommands, isEmpty);
    controller.dispose();
  });

  testWidgets('an unsupported synced certificate never opens a web socket', (
    tester,
  ) async {
    const server = ServerProfile(
      id: 'android-certificate',
      alias: 'Android server',
      ip: 'server.example.com',
      port: 8080,
      secretKey: 'secret',
      certificate: 'self-signed certificate',
      security: ConnectionSecurity.customCertificate,
    );
    SharedPreferences.setMockInitialValues({
      'servers': [jsonEncode(server.toJson())],
      'selectedServer': server.id,
      'onboardingCompleted': true,
    });
    final preferences = await SharedPreferences.getInstance();
    final model = Model(PersistenceService(preferences));
    final service = _RecordingConnectionService();
    final controller = ConnectionController(
      connectionService: service,
      capabilities: const ConnectionPlatformCapabilities(
        supportsCustomCertificates: false,
        supportsDirectRcon: false,
      ),
    );

    await controller.attemptConnection(model);
    await tester.pump();

    expect(service.connectCalls, 0);
    expect(controller.lastFailure?.kind, ConnectionFailureKind.unsupported);
    expect(model.connectionSecurity, ConnectionSecurity.customCertificate);
    expect(model.certificate, 'self-signed certificate');
    controller.dispose();
  });
}

class _RecordingConnectionService extends ConnectionService {
  ConnectionStatus _fakeStatus = ConnectionStatus.disconnected;
  final List<String> quietCommands = [];
  final List<String> regularCommands = [];
  int connectCalls = 0;

  @override
  ConnectionStatus get status => _fakeStatus;

  @override
  Future<void> connect(Model model, {bool reconnect = false}) async {
    connectCalls++;
    _fakeStatus = ConnectionStatus.connected;
  }

  @override
  bool executeCommand(String message) {
    regularCommands.add(message);
    return true;
  }

  @override
  bool executeQuietCommand(Model model, String message) {
    quietCommands.add(message);
    return true;
  }

  @override
  void disconnect(Model model) {
    _fakeStatus = ConnectionStatus.disconnected;
  }
}
