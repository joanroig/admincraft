import 'package:admincraft/services/rcon_connection.dart';

/// RCON is a raw TCP protocol, and a browser can only open HTTP and WebSocket
/// connections. There is no shim for this: the web app has to go through the
/// WebSocket bridge.
const bool supportsDirectRcon = false;

Future<RconConnection> connectRcon({
  required String host,
  required int port,
  required String password,
  Duration timeout = const Duration(seconds: 10),
}) async {
  throw const RconUnsupportedException(
    'A browser cannot open the raw TCP connection RCON needs. Use the '
    'WebSocket bridge, or the Windows, macOS, Linux or Android build.',
  );
}
