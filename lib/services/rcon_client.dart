/// Direct RCON, bypassing the WebSocket bridge.
///
/// The web implementation is the default and `dart:io` the override, matching
/// the other conditional services, so a target without sockets resolves to the
/// unsupported stub rather than failing to compile.
library;

export 'rcon_client_web.dart' if (dart.library.io) 'rcon_client_io.dart';
