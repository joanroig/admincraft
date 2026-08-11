/// Opens the WebSocket using whichever implementation the target platform has.
///
/// The browser has no `dart:io`, so `SecurityContext` and `IOWebSocketChannel`
/// are unavailable there: touching them throws
/// `Unsupported operation: SecurityContext constructor` at runtime. The web
/// build therefore goes through the browser's own WebSocket, which also means
/// TLS is validated by the browser and cannot be pointed at a custom
/// certificate.
///
/// The web implementation is the default so that targets without `dart:io`
/// (including WebAssembly) resolve correctly.
library;

export 'websocket_connector_web.dart' if (dart.library.io) 'websocket_connector_io.dart';
