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
  // Identifying the user is what makes Android raise an account sheet, so a
  // device that has never connected Drive must not ask at all: the prompt
  // otherwise appears on every launch, including during onboarding, before
  // anything has offered the feature.
  test('startup does not touch Google until sync has been connected', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final model = Model(PersistenceService(prefs));
    final auth = _FakeAuth(
      MockClient((_) async => http.Response('{}', 200)),
      signedInValue: false,
    );
    final controller = GoogleDriveSyncController(prefs, auth: auth);

    await controller.initialize(model);
    expect(auth.initializeCalls, 0);

    // Signing in is the point at which the user has asked for it.
    await controller.signIn();
    expect(auth.signInCalls, 1);
  });

  test(
    'startup prepares prior sync without prompting Android sign-in',
    () async {
      SharedPreferences.setMockInitialValues({'googleDriveConnected': true});
      final prefs = await SharedPreferences.getInstance();
      final model = Model(PersistenceService(prefs));
      final auth = _FakeAuth(MockClient((_) async => http.Response('{}', 200)));
      final controller = GoogleDriveSyncController(prefs, auth: auth);

      await controller.initialize(model);

      expect(auth.initializeCalls, 1);
      expect(auth.lastRestoreMobileSession, isFalse);
    },
  );

  test(
    'automatic sync restores auth at startup to check remote changes',
    () async {
      SharedPreferences.setMockInitialValues({
        'googleDriveConnected': true,
        'googleDriveSyncEnabled': true,
      });
      final prefs = await SharedPreferences.getInstance();
      final model = Model(PersistenceService(prefs));
      final auth = _FakeAuth(
        MockClient((_) async => http.Response('{}', 200)),
        signedInValue: false,
        restoreResult: true,
      );
      final controller = GoogleDriveSyncController(prefs, auth: auth);

      await controller.initialize(model);

      expect(auth.lastRestoreMobileSession, isTrue);
      expect(controller.signedIn, isTrue);
      controller.dispose();
    },
  );

  test(
    'a server-profile change schedules sync after startup restore',
    () async {
      SharedPreferences.setMockInitialValues({
        'servers': [jsonEncode(localServer.toJson())],
        'selectedServer': localServer.id,
        'googleDriveConnected': true,
        'googleDriveSyncEnabled': true,
      });
      final prefs = await SharedPreferences.getInstance();
      final model = Model(PersistenceService(prefs));
      final secureValues = _MemorySecureValues()
        ..values['admincraft.google-drive.passphrase'] = 'drive passphrase';
      final uploaded = Completer<void>();
      final client = MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(jsonEncode({'files': []}), 200);
        }
        if (!uploaded.isCompleted) uploaded.complete();
        return http.Response(
          jsonEncode({
            'id': 'created',
            'modifiedTime': DateTime.now().toUtc().toIso8601String(),
          }),
          200,
        );
      });
      final auth = _FakeAuth(client, signedInValue: false, restoreResult: true);
      final controller = GoogleDriveSyncController(
        prefs,
        auth: auth,
        secureValues: secureValues,
      );

      await controller.initialize(model);
      expect(auth.restoreCalls, 0);

      await model.setConnectionDetails(
        alias: 'Changed world',
        ip: localServer.ip,
        port: localServer.port,
        secretKey: localServer.secretKey,
        certificate: localServer.certificate,
        connectionSecurity: localServer.security,
        minecraftEdition: localServer.edition,
      );
      await uploaded.future.timeout(const Duration(seconds: 4));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(auth.lastRestoreMobileSession, isTrue);
      expect(auth.restoreCalls, 0);
      expect(controller.lastSyncAt, isNotNull);
      controller.dispose();
    },
  );

  test('device-only preferences do not schedule profile sync', () async {
    SharedPreferences.setMockInitialValues({
      'googleDriveConnected': true,
      'googleDriveSyncEnabled': true,
    });
    final prefs = await SharedPreferences.getInstance();
    final model = Model(PersistenceService(prefs));
    final auth = _FakeAuth(
      MockClient((_) async => http.Response('{}', 200)),
      signedInValue: false,
      restoreResult: true,
    );
    final controller = GoogleDriveSyncController(prefs, auth: auth);

    await controller.initialize(model);
    await model.setFontSize(18);
    await Future<void>.delayed(const Duration(milliseconds: 1100));

    expect(auth.restoreCalls, 0);
    controller.dispose();
  });

  test('disconnecting stops the next start from restoring', () async {
    SharedPreferences.setMockInitialValues({'googleDriveConnected': true});
    final prefs = await SharedPreferences.getInstance();
    final model = Model(PersistenceService(prefs));
    final auth = _FakeAuth(MockClient((_) async => http.Response('{}', 200)));

    await GoogleDriveSyncController(
      prefs,
      auth: auth,
      secureValues: _MemorySecureValues(),
    ).disconnect();

    final next = _FakeAuth(MockClient((_) async => http.Response('{}', 200)));
    await GoogleDriveSyncController(
      prefs,
      auth: next,
      secureValues: _MemorySecureValues(),
    ).initialize(model);

    expect(next.initializeCalls, 0);
  });

  test(
    'first upload enables automatic sync and stores only ciphertext',
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
    },
  );

  test('first download replaces local profiles and enables sync', () async {
    SharedPreferences.setMockInitialValues({
      'servers': [jsonEncode(localServer.toJson())],
      'selectedServer': localServer.id,
    });
    final prefs = await SharedPreferences.getInstance();
    final model = Model(PersistenceService(prefs));
    final blob = await ConfigTransfer.export(const [
      remoteServer,
    ], 'drive passphrase');
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
            },
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

    expect(model.servers.map((server) => server.toJson()), [
      remoteServer.toJson(),
    ]);
    expect(model.selectedServerId, remoteServer.id);
    expect(controller.automaticSyncEnabled, isTrue);
  });

  test('startup automatic sync applies a newer Drive copy', () async {
    final now = DateTime.now().toUtc();
    final blob = await ConfigTransfer.export(const [
      remoteServer,
    ], 'drive passphrase');
    SharedPreferences.setMockInitialValues({
      'servers': [jsonEncode(localServer.toJson())],
      'selectedServer': localServer.id,
      'serversUpdatedAt': now
          .subtract(const Duration(hours: 3))
          .millisecondsSinceEpoch,
      'googleDriveSyncEnabled': true,
      'googleDriveLastSync': now
          .subtract(const Duration(hours: 2))
          .millisecondsSinceEpoch,
    });
    final prefs = await SharedPreferences.getInstance();
    final model = Model(PersistenceService(prefs));
    final secureValues = _MemorySecureValues()
      ..values['admincraft.google-drive.passphrase'] = 'drive passphrase';
    final downloaded = Completer<void>();
    final client = MockClient((request) async {
      if (request.url.queryParameters['alt'] == 'media') {
        if (!downloaded.isCompleted) downloaded.complete();
        return http.Response(blob, 200);
      }
      return http.Response(
        jsonEncode({
          'files': [
            {
              'id': 'remote-file',
              'modifiedTime': now
                  .subtract(const Duration(hours: 1))
                  .toIso8601String(),
            },
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
    await downloaded.future.timeout(const Duration(seconds: 4));
    final deadline = DateTime.now().add(const Duration(seconds: 3));
    while (model.selectedServerId != remoteServer.id &&
        DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }

    expect(model.servers.map((server) => server.toJson()), [
      remoteServer.toJson(),
    ]);
    controller.dispose();
  });
}

class _FakeAuth implements GoogleAuthProvider {
  final http.Client client;
  bool signedInValue;
  final bool restoreResult;
  int initializeCalls = 0;
  bool? lastRestoreMobileSession;
  int restoreCalls = 0;
  int signInCalls = 0;

  _FakeAuth(this.client, {this.signedInValue = true, bool? restoreResult})
    : restoreResult = restoreResult ?? signedInValue;

  @override
  bool get configured => true;

  @override
  bool get signedIn => signedInValue;

  @override
  String? get email => 'test@example.com';

  @override
  Stream<bool> get authenticationChanges => const Stream.empty();

  @override
  Future<void> initialize({bool restoreMobileSession = true}) async {
    initializeCalls++;
    lastRestoreMobileSession = restoreMobileSession;
    if (restoreMobileSession && restoreResult) signedInValue = true;
  }

  @override
  Future<bool> restoreSession() async {
    restoreCalls++;
    signedInValue = restoreResult;
    return signedInValue;
  }

  @override
  Future<bool> signIn() async {
    signInCalls++;
    return true;
  }

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
