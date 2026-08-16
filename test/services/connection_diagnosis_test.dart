import 'dart:async';

import 'package:admincraft/models/connection_security.dart';
import 'package:admincraft/services/connection_diagnosis.dart';
import 'package:admincraft/services/connection_failure.dart';
import 'package:flutter_test/flutter_test.dart';

ConnectionFailure diagnose(
  Object error, {
  ConnectionSecurity security = ConnectionSecurity.privateNetwork,
}) =>
    diagnoseConnectionError(error,
        security: security, host: 'server.example', port: 8080);

void main() {
  group('what the transport says becomes what the user reads', () {
    test('an address that does not resolve', () {
      final failure =
          diagnose('SocketException: Failed host lookup: "server.example"');

      expect(failure.kind, ConnectionFailureKind.unknownHost);
      expect(failure.message, contains('server.example'));
      // The mistake this one usually is.
      expect(failure.message, contains('https://'));
      expect(failure.isTransient, isFalse);
    });

    test('a port with nothing behind it', () {
      final failure = diagnose('SocketException: Connection refused');

      expect(failure.kind, ConnectionFailureKind.refused);
      expect(failure.message, contains('8080'));
      expect(failure.isTransient, isTrue);
    });

    test('no answer at all', () {
      expect(diagnose(TimeoutException('x')).kind, ConnectionFailureKind.timeout);
      expect(diagnose(TimeoutException('x')).isTransient, isTrue);
    });

    test('a certificate that cannot be accepted names the reason per mode', () {
      final trusted = diagnose(
        'HandshakeException: certificate verify failed',
        security: ConnectionSecurity.trustedCertificate,
      );
      expect(trusted.kind, ConnectionFailureKind.certificate);
      expect(trusted.message, contains('IP address can never work'));

      final custom = diagnose(
        'HandshakeException: certificate verify failed',
        security: ConnectionSecurity.customCertificate,
      );
      expect(custom.message, contains('loaded certificate'));
    });

    test('anything else names the candidates instead of guessing', () {
      final failure = diagnose('WebSocketChannelException: connection failed');

      expect(failure.kind, ConnectionFailureKind.unknown);
      expect(failure.message, contains('server.example:8080'));
      expect(failure.isTransient, isFalse);
    });
  });

  group('the bridge reports refusals by closing', () {
    // It accepts the handshake and then closes, so these are not connection
    // errors. Read as dropped connections, a wrong key reconnected forever.
    test('4001 is a rejected key, and is not worth retrying', () {
      final failure = failureFromCloseCode(4001, 'Authentication failed')!;

      expect(failure.kind, ConnectionFailureKind.rejected);
      expect(failure.message, contains('SECRET_KEY'));
      expect(failure.isTransient, isFalse);
    });

    test('4002 carries the edition mismatch the bridge described', () {
      final failure = failureFromCloseCode(
          4002, 'Profile is java, but this bridge is bedrock')!;

      expect(failure.kind, ConnectionFailureKind.editionMismatch);
      expect(failure.message, contains('bridge is bedrock'));
      expect(failure.isTransient, isFalse);
    });

    test('an ordinary close is not turned into a diagnosis', () {
      expect(failureFromCloseCode(1000, null), isNull);
      expect(failureFromCloseCode(null, null), isNull);
    });
  });
}
