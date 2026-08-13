import 'dart:async';
import 'dart:convert';

import 'package:admincraft/controllers/google_drive_sync_controller.dart';
import 'package:admincraft/models/connection_security.dart';
import 'package:admincraft/models/model.dart';
import 'package:admincraft/models/server_profile.dart';
import 'package:admincraft/services/config_transfer.dart';
import 'package:admincraft/services/google_auth_provider_base.dart';
import 'package:admincraft/services/persistence_service.dart';
import 'package:admincraft/services/secure_value_store.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const localServer = ServerProfile(
  id: 'local',
  alias: 'Local world',
  ip: 'local.example.com',
  port: 8080,
  secretKey: 'local-secret',
  certificate: '',
  security: ConnectionSecurity.privateNetwork,
);

const remoteServer = ServerProfile(
  id: 'remote',
  alias: 'Remote world',
  ip: 'remote.example.com',
  port: 8081,
  secretKey: 'remote-secret',
  certificate: '',
  security: ConnectionSecurity.trustedCertificate,
);

void main() {
  test('first upload enables automatic sync and stores only ciphertext',
      () async {
    SharedPreferences.setMockInitialValues({
      'servers': [jsonEncode(localServer.toJson())],
      'selectedServer': localServer.id,
    });
    final prefs = await SharedPreferences.getInstance();
    final model = Model(PersistenceService(prefs));
    final secureValues = _MemorySecureValues();
    String? uploadedBody;
    final client = MockClient((request) async {
      if (request.method == 'GET') {
        return http.Response(jsonEncode({'files': []}), 200);
      }
      uploadedBody = request.body;
      return http.Response(
        jsonEncode({
          'id': 'created',
          'modifiedTime': DateTime.now().toUtc().toIso8601String(),
        }),
        200,
      );
    });
    final controller = GoogleDriveSyncController(
      prefs,
      auth: _FakeAuth(client),
      secureValues: secureValues,
    );

    await controller.initialize(model);
    await controller.enableWithUpload(model, 'drive passphrase');

    expect(controller.automaticSyncEnabled, isTrue);
    expect(controller.lastSyncAt, isNotNull);
    expect(secureValues.values.values, contains('drive passphrase'));
    expect(uploadedBody, isNot(contains('local-secret')));
    expect(uploadedBody, contains('admincraft-config'));
  });

  test('first download replaces local profiles and enables sync', () async {
    SharedPreferences.setMockInitialValues({
      'servers': [jsonEncode(localServer.toJson())],
      'selectedServer': localServer.id,
    });
    final prefs = await SharedPreferences.getInstance();
    final model = Model(PersistenceService(prefs));
    final blob = await ConfigTransfer.export(
      const [remoteServer],
      'drive passphrase',
    );
    final client = MockClient((request) async {
      if (request.url.queryParameters['alt'] == 'media') {
        return http.Response(blob, 200);
      }
      return http.Response(
        jsonEncode({
          'files': [
            {
              'id': 'remote-file',
              'modifiedTime': DateTime.now().toUtc().toIso8601String(),
            }
          ],
        }),
        200,
      );
    });
    final controller = GoogleDriveSyncController(
      prefs,
      auth: _FakeAuth(client),
      secureValues: _MemorySecureValues(),
    );

    await controller.initialize(model);
    await controller.enableWithDownload(model, 'drive passphrase');

    expect(
      model.servers.map((server) => server.toJson()),
      [remoteServer.toJson()],
    );
    expect(model.selectedServerId, remoteServer.id);
    expect(controller.automaticSyncEnabled, isTrue);
  });

  test('automatic sync applies a Drive copy changed since the last sync',
      () async {
    final now = DateTime.now().toUtc();
    final blob = await ConfigTransfer.export(
      const [remoteServer],
      'drive passphrase',
    );
    SharedPreferences.setMockInitialValues({
      'servers': [jsonEncode(localServer.toJson())],
      'selectedServer': localServer.id,
      'serversUpdatedAt':
          now.subtract(const Duration(hours: 3)).millisecondsSinceEpoch,
      'googleDriveSyncEnabled': true,
      'googleDriveLastSync':
          now.subtract(const Duration(hours: 2)).millisecondsSinceEpoch,
    });
    final prefs = await SharedPreferences.getInstance();
    final model = Model(PersistenceService(prefs));
    final secureValues = _MemorySecureValues()
      ..values['admincraft.google-drive.passphrase'] = 'drive passphrase';
    final client = MockClient((request) async {
      if (request.url.queryParameters['alt'] == 'media') {
        return http.Response(blob, 200);
      }
      return http.Response(
        jsonEncode({
          'files': [
            {
              'id': 'remote-file',
              'modifiedTime':
                  now.subtract(const Duration(hours: 1)).toIso8601String(),
            }
          ],
        }),
        200,
      );
    });
    final controller = GoogleDriveSyncController(
      prefs,
      auth: _FakeAuth(client),
      secureValues: secureValues,
    );

    await controller.initialize(model);
    await controller.syncNow(model);
    controller.dispose();

    expect(
      model.servers.map((server) => server.toJson()),
      [remoteServer.toJson()],
    );
  });
}

class _FakeAuth implements GoogleAuthProvider {
  final http.Client client;

  _FakeAuth(this.client);

  @override
  bool get configured => true;

  @override
  bool get signedIn => true;

  @override
  String? get email => 'test@example.com';

  @override
  Stream<bool> get authenticationChanges => const Stream.empty();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> signIn() async => true;

  @override
  Widget? buildSignInButton() => null;

  @override
  Future<http.Client?> authenticatedClient({required bool interactive}) async =>
      client;

  @override
  Future<void> signOut() async {}

  @override
  void dispose() {}
}

class _MemorySecureValues implements SecureValueStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}
