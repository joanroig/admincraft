import 'dart:convert';

import 'package:admincraft/models/connection_security.dart';
import 'package:admincraft/models/model.dart';
import 'package:admincraft/models/server_profile.dart';
import 'package:admincraft/services/persistence_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('deleting the final server returns the model to onboarding', () async {
    const server = ServerProfile(
      id: 'only-server',
      alias: 'Only server',
      ip: 'server.example.com',
      port: 8080,
      secretKey: 'secret',
      certificate: '',
      security: ConnectionSecurity.privateNetwork,
    );
    SharedPreferences.setMockInitialValues({
      'onboardingCompleted': true,
      'selectedServer': server.id,
      'servers': [jsonEncode(server.toJson())],
    });
    final preferences = await SharedPreferences.getInstance();
    final model = Model(PersistenceService(preferences));

    await model.deleteServer(server.id);

    expect(model.servers, hasLength(1));
    expect(model.selectedServer.isComplete, isFalse);
    expect(model.onboardingCompleted, isFalse);
    expect(model.selectedServerId, isNot(server.id));

    final reopened = Model(PersistenceService(preferences));
    expect(reopened.servers, hasLength(1));
    expect(reopened.selectedServer.isComplete, isFalse);
    expect(reopened.onboardingCompleted, isFalse);
  });
}
