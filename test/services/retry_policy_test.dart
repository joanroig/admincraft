import 'package:admincraft/services/connection_failure.dart';
import 'package:admincraft/services/retry_policy.dart';
import 'package:flutter_test/flutter_test.dart';

const _rejected = ConnectionFailure(
    ConnectionFailureKind.rejected, 'The bridge rejected the secret key.');
const _timeout =
    ConnectionFailure(ConnectionFailureKind.timeout, 'No answer from host.');

void main() {
  // The complaint this policy exists for: a wrong key produced "connection
  // lost, reconnecting" over and over, so the one thing the user needed to
  // read was buried under attempts that could never succeed.
  test('a failure the user must fix is never retried', () {
    for (final kind in [
      ConnectionFailureKind.rejected,
      ConnectionFailureKind.unknownHost,
      ConnectionFailureKind.certificate,
      ConnectionFailureKind.editionMismatch,
      ConnectionFailureKind.unsupported,
    ]) {
      final decision = decideRetry(
        failure: ConnectionFailure(kind, 'why'),
        attemptsMade: 0,
      );
      expect(decision.willRetry, isFalse, reason: kind.name);
      expect(decision.message, 'why', reason: kind.name);
    }
  });

  test('a failure that might pass is retried, further apart each time', () {
    final delays = [
      for (var made = 0; made < 3; made++)
        decideRetry(failure: _timeout, attemptsMade: made).delay!.inSeconds,
    ];

    expect(delays, [3, 6, 9]);
  });

  test('the message says what will happen next', () {
    final decision = decideRetry(failure: _timeout, attemptsMade: 0);

    expect(decision.message, contains('No answer from host.'));
    expect(decision.message, contains('Retrying in 3s'));
    expect(decision.message, contains('1 of 3'));
  });

  test('retrying stops, and says so, rather than going on forever', () {
    final decision = decideRetry(failure: _timeout, attemptsMade: 3);

    expect(decision.willRetry, isFalse);
    expect(decision.message, contains('Gave up after 4 attempts'));
  });

  test('the message for a permanent failure adds nothing to it', () {
    final decision = decideRetry(failure: _rejected, attemptsMade: 0);

    expect(decision.message, _rejected.message);
  });
}
