/// A live RCON session.
///
/// RCON is request and response only: there is no way to subscribe to the
/// server log, so [responses] carries replies to commands that were sent and
/// nothing else. Anything that relies on watching the log, such as noticing a
/// player joining, has to be polled instead.
abstract class RconConnection {
  Stream<String> get responses;

  void send(String command);

  Future<void> close();
}

/// Raised when direct RCON cannot work on this platform at all.
class RconUnsupportedException implements Exception {
  final String message;
  const RconUnsupportedException(this.message);

  @override
  String toString() => message;
}

/// Raised when the server rejects the password.
///
/// Distinguished from a connection failure because the two need different
/// advice: one is the wrong password, the other is the wrong address or a
/// closed port.
class RconAuthException implements Exception {
  const RconAuthException();

  @override
  String toString() => 'RCON rejected the password.';
}
