import 'dart:convert';

import 'package:admincraft/models/connection_security.dart';
import 'package:admincraft/models/model.dart';
import 'package:admincraft/models/server_profile.dart';
import 'package:admincraft/services/persistence_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const existing = ServerProfile(
    id: 'existing',
    alias: 'Old name',
    ip: 'old.example.com',
    port: 8080,
    secretKey: 'old-secret',
    certificate: '',
    security: ConnectionSecurity.privateNetwork,
  );

  const updated = ServerProfile(
    id: 'existing',
    alias: 'Updated name',
    ip: 'new.example.com',
    port: 8081,
    secretKey: 'new-secret',
    certificate: '',
    security: ConnectionSecurity.trustedCertificate,
  );

  const added = ServerProfile(
    id: 'added',
    alias: 'Creative',
    ip: 'creative.example.com',
    port: 8082,
    secretKey: 'creative-secret',
    certificate: '',
    security: ConnectionSecurity.trustedCertificate,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'servers': [jsonEncode(existing.toJson())],
      'selectedServer': existing.id,
    });
  });

  test(
    'updates matching ids, appends new ids, and persists the merge',
    () async {
      final preferences = await SharedPreferences.getInstance();
      final model = Model(PersistenceService(preferences));

      final result = await model.importServers([updated, added]);

      expect(result.added, 1);
      expect(result.updated, 1);
      expect(model.servers.map((server) => server.toJson()), [
        updated.toJson(),
        added.toJson(),
      ]);

      final reloaded = Model(PersistenceService(preferences));
      expect(reloaded.servers.map((server) => server.toJson()), [
        updated.toJson(),
        added.toJson(),
      ]);
    },
  );

  test(
    'a configured persisted server completes onboarding without a flag',
    () async {
      final preferences = await SharedPreferences.getInstance();
      final model = Model(PersistenceService(preferences));

      expect(model.onboardingCompleted, isTrue);
    },
  );

  test('replacing servers from sync persists completed onboarding', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final model = Model(PersistenceService(preferences));

    await model.replaceServers([added]);

    expect(model.onboardingCompleted, isTrue);
    expect(preferences.getBool('onboardingCompleted'), isTrue);
  });
}
