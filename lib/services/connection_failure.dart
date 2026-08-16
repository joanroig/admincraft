/// Why a connection attempt did not succeed.
///
/// The point of naming these is retry policy as much as wording: a timeout is
/// worth trying again, a rejected key never is. The app used to retry both,
/// so an unusable profile produced "connection lost, reconnecting" for as long
/// as anyone watched.
enum ConnectionFailureKind {
  /// The address does not resolve.
  unknownHost,

  /// Something answered the address and refused the port, or nothing did.
  refused,

  /// No answer within the time allowed.
  timeout,

  /// TLS could not be established or the certificate was not accepted.
  certificate,

  /// The bridge closed the connection because the key was wrong (close 4001),
  /// or RCON rejected the password.
  rejected,

  /// The profile's edition does not match the bridge's (close 4002).
  editionMismatch,

  /// The platform cannot make this kind of connection at all.
  unsupported,

  /// Established, then lost.
  dropped,

  unknown,
}

class ConnectionFailure implements Exception {
  final ConnectionFailureKind kind;

  /// What went wrong and what to do about it, in the reader's terms. The
  /// underlying exception text is not this: it describes a socket.
  final String message;

  const ConnectionFailure(this.kind, this.message);

  /// Whether trying again could plausibly work without anyone changing
  /// anything. Retrying the rest only delays telling the user what to fix.
  bool get isTransient =>
      kind == ConnectionFailureKind.timeout ||
      kind == ConnectionFailureKind.refused ||
      kind == ConnectionFailureKind.dropped;

  @override
  String toString() => message;
}
