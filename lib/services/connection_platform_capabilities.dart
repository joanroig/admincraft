import 'package:admincraft/models/connection_security.dart';
import 'package:admincraft/models/minecraft_edition.dart';
import 'package:admincraft/services/connection_failure.dart';
import 'package:admincraft/services/rcon_client.dart' as rcon;
import 'package:admincraft/services/websocket_connector.dart' as websocket;

/// Connection features the current platform can implement.
///
/// Profiles are synced unchanged between devices, but the transports are not
/// interchangeable: browsers cannot pin a certificate or open a raw RCON
/// socket. Keeping this decision outside the profile prevents a web download
/// from silently rewriting a configuration that still works on Android.
class ConnectionPlatformCapabilities {
  final bool supportsCustomCertificates;
  final bool supportsDirectRcon;

  const ConnectionPlatformCapabilities({
    required this.supportsCustomCertificates,
    required this.supportsDirectRcon,
  });

  bool supports(ConnectionSecurity security, MinecraftEdition edition) {
    if (security.requiresCertificate) return supportsCustomCertificates;
    if (security.isDirectRcon) {
      return supportsDirectRcon && edition == MinecraftEdition.java;
    }
    return true;
  }

  String? unsupportedMessage(
    ConnectionSecurity security,
    MinecraftEdition edition,
  ) {
    if (supports(security, edition)) return null;
    if (security.requiresCertificate) {
      return 'Web browsers cannot use the self-signed certificate stored in '
          'this synced profile. Keep this profile for Android or desktop, or '
          'switch to Public certificate with a hostname the browser trusts. '
          'If the browser uses a different address, add a separate server '
          'profile for it.';
    }
    if (security.isDirectRcon) {
      return 'Web browsers cannot open a Direct RCON connection. Keep this '
          'profile for a native app, or add a browser profile that connects '
          'through the Admincraft WebSocket bridge.';
    }
    return 'This connection type is not available on this platform.';
  }

  ConnectionFailure? failureFor(
    ConnectionSecurity security,
    MinecraftEdition edition,
  ) {
    final message = unsupportedMessage(security, edition);
    return message == null
        ? null
        : ConnectionFailure(ConnectionFailureKind.unsupported, message);
  }
}

const currentConnectionPlatformCapabilities = ConnectionPlatformCapabilities(
  supportsCustomCertificates: websocket.supportsCustomCertificate,
  supportsDirectRcon: rcon.supportsDirectRcon,
);
