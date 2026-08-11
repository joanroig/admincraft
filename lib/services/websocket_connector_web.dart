import 'package:admincraft/models/connection_security.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// The browser validates TLS itself and exposes no way to trust an extra
/// certificate, so a self-signed server cannot be pinned from inside the app.
const bool supportsCustomCertificate = false;

WebSocketChannel connectWebSocket({
  required Uri uri,
  required ConnectionSecurity security,
  required String certificate,
}) {
  // Nothing to configure: the scheme in [uri] already reflects the selected
  // mode, and trust decisions belong to the browser. Reaching a server with a
  // self-signed certificate requires the user to accept it in the browser
  // first, by opening the address directly.
  return WebSocketChannel.connect(uri);
}
