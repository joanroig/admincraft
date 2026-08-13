import 'dart:convert';

import 'package:admincraft/models/connection_security.dart';
import 'package:admincraft/models/server_profile.dart';
import 'package:admincraft/services/config_transfer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const server = ServerProfile(
    id: 'server-1',
    alias: 'Survival',
    ip: 'minecraft.example.com',
    port: 8080,
    secretKey: 'very-secret',
    certificate: 'certificate-data',
    security: ConnectionSecurity.customCertificate,
  );

  test('round-trips every server profile field', () async {
    final blob = await ConfigTransfer.export([server], 'correct horse');

    final imported = await ConfigTransfer.import(blob, 'correct horse');

    expect(imported, hasLength(1));
    expect(imported.single.toJson(), server.toJson());
  });

  test('uses fresh randomness for every export', () async {
    final first = await ConfigTransfer.export([server], 'same passphrase');
    final second = await ConfigTransfer.export([server], 'same passphrase');

    expect(first, isNot(second));
  });

  test('rejects a wrong passphrase without exposing profile data', () async {
    final blob = await ConfigTransfer.export([server], 'right passphrase');

    await expectLater(
      ConfigTransfer.import(blob, 'wrong passphrase'),
      throwsA(
        isA<ConfigTransferException>().having(
          (error) => error.message,
          'message',
          'Wrong passphrase, or the config is damaged.',
        ),
      ),
    );
  });

  test('rejects a truncated envelope with an actionable error', () async {
    final blob = await ConfigTransfer.export([server], 'passphrase');
    final envelope = jsonDecode(blob) as Map<String, dynamic>;
    envelope.remove('nonce');

    await expectLater(
      ConfigTransfer.import(jsonEncode(envelope), 'passphrase'),
      throwsA(
        isA<ConfigTransferException>().having(
          (error) => error.message,
          'message',
          'This Admincraft config is incomplete or damaged.',
        ),
      ),
    );
  });

  test('directs configs from a future format to a newer app', () async {
    final blob = await ConfigTransfer.export([server], 'passphrase');
    final envelope = jsonDecode(blob) as Map<String, dynamic>;
    envelope['version'] = 2;

    await expectLater(
      ConfigTransfer.import(jsonEncode(envelope), 'passphrase'),
      throwsA(
        isA<ConfigTransferException>().having(
          (error) => error.message,
          'message',
          contains('newer version'),
        ),
      ),
    );
  });
}
