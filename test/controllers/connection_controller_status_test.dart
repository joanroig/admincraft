import 'dart:convert';

import 'package:admincraft/controllers/connection_controller.dart';
import 'package:admincraft/models/connection_security.dart';
import 'package:admincraft/models/connection_status.dart';
import 'package:admincraft/models/model.dart';
import 'package:admincraft/models/server_profile.dart';
import 'package:admincraft/services/connection_service.dart';
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
}

class _RecordingConnectionService extends ConnectionService {
  ConnectionStatus _fakeStatus = ConnectionStatus.disconnected;
  final List<String> quietCommands = [];
  final List<String> regularCommands = [];

  @override
  ConnectionStatus get status => _fakeStatus;

  @override
  Future<void> connect(Model model, {bool reconnect = false}) async {
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
