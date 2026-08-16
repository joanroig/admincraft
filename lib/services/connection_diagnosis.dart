import 'dart:async';

import 'package:admincraft/models/connection_security.dart';
import 'package:admincraft/services/connection_failure.dart';

/// Turns whatever the transport threw into something worth showing.
///
/// The strings are matched rather than the types, because the types differ per
/// platform: `dart:io` raises SocketException and HandshakeException, the
/// browser raises an opaque WebSocketChannelException with no cause at all, and
/// both arrive wrapped. Matching text is not elegant, but the alternative is
/// showing the user "WebSocketChannelException" and letting them guess.
ConnectionFailure diagnoseConnectionError(
  Object error, {
  required ConnectionSecurity security,
  required String host,
  required int port,
}) {
  final text = error.toString().toLowerCase();
  final where = '$host:$port';

  if (error is TimeoutException || text.contains('timed out')) {
    return ConnectionFailure(
      ConnectionFailureKind.timeout,
      'No answer from $where. The address may be unreachable from this device, '
      'or a firewall may be dropping the connection.',
    );
  }

  if (text.contains('failed host lookup') ||
      text.contains('nodename nor servname') ||
      text.contains('name or service not known') ||
      text.contains('no such host')) {
    return ConnectionFailure(
      ConnectionFailureKind.unknownHost,
      'The address $host could not be found. Check it for typos, and enter '
      'only the host, without https:// or a path.',
    );
  }

  if (text.contains('connection refused') || text.contains('errno = 111')) {
    return ConnectionFailure(
      ConnectionFailureKind.refused,
      'Nothing is listening on port $port at $host. Check the port, and that '
      'the bridge is running.',
    );
  }

  if (text.contains('certificate') ||
      text.contains('handshake') ||
      text.contains('tls') ||
      text.contains('ssl')) {
    final extra = switch (security) {
      ConnectionSecurity.trustedCertificate =>
        ' A trusted certificate must be issued to this hostname, so an IP '
            'address can never work here.',
      ConnectionSecurity.customCertificate =>
        ' The loaded certificate must be the one this server presents, and '
            'must cover the address above.',
      _ => '',
    };
    return ConnectionFailure(
      ConnectionFailureKind.certificate,
      'The secure connection to $where was refused.$extra',
    );
  }

  if (text.contains('unsupported') || text.contains('not supported')) {
    return const ConnectionFailure(
      ConnectionFailureKind.unsupported,
      'This connection type is not available on this platform.',
    );
  }

  // The browser deliberately hides the reason, so name the candidates instead
  // of pretending to know which one it was.
  return ConnectionFailure(
    ConnectionFailureKind.unknown,
    'Could not connect to $where. The server may be down, the address or port '
    'wrong, or the connection blocked by the network.',
  );
}

/// Reads the close code the bridge sent, which is where it reports refusals.
///
/// The bridge accepts the WebSocket handshake before checking the key, so a
/// wrong key is not a connection error: it is a normal connection that closes
/// immediately with 4001. Treating that as a dropped connection is why a
/// mistyped key used to reconnect forever instead of saying it was wrong.
ConnectionFailure? failureFromCloseCode(int? code, String? reason) {
  return switch (code) {
    4001 => const ConnectionFailure(
        ConnectionFailureKind.rejected,
        'The bridge rejected the secret key. It must match SECRET_KEY in the '
        "bridge's compose file exactly.",
      ),
    4002 => ConnectionFailure(
        ConnectionFailureKind.editionMismatch,
        reason?.isNotEmpty == true
            ? '$reason. Change the edition in this profile, or SERVER_TYPE on '
                'the bridge, so the two agree.'
            : 'This profile and the bridge disagree about the Minecraft '
                'edition.',
      ),
    _ => null,
  };
}
