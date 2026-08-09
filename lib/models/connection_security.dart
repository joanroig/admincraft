/// How the connection to the Admincraft WebSocket server is protected.
///
/// The WebSocket grants full control over the Minecraft container, so the
/// traffic always has to be encrypted by something: either the network it
/// travels over, or TLS.
enum ConnectionSecurity {
  /// Plain `ws://`. Only safe when the server is reachable exclusively over an
  /// already encrypted private network, such as Tailscale, a VPN or a LAN.
  privateNetwork,

  /// `wss://` validated against the certificate authorities the device already
  /// trusts. For servers presenting a publicly trusted certificate, such as
  /// Tailscale Funnel, Let's Encrypt or a reverse proxy.
  trustedCertificate,

  /// `wss://` validated against a certificate supplied by the user and nothing
  /// else. For self-signed setups.
  customCertificate,
}

extension ConnectionSecurityInfo on ConnectionSecurity {
  String get label {
    switch (this) {
      case ConnectionSecurity.privateNetwork:
        return 'Private network';
      case ConnectionSecurity.trustedCertificate:
        return 'Public certificate';
      case ConnectionSecurity.customCertificate:
        return 'Self-signed certificate';
    }
  }

  String get description {
    switch (this) {
      case ConnectionSecurity.privateNetwork:
        return 'No TLS. Use only with Tailscale, a VPN or a LAN, where the network already encrypts the traffic.';
      case ConnectionSecurity.trustedCertificate:
        return 'Encrypted with the server certificate, checked against the authorities this device trusts. Nothing to load.';
      case ConnectionSecurity.customCertificate:
        return 'Encrypted, trusting only the certificate loaded below.';
    }
  }

  /// Whether the connection is established over TLS (`wss://`).
  bool get usesTls => this != ConnectionSecurity.privateNetwork;

  /// Whether the user has to supply a certificate for this mode to work.
  bool get requiresCertificate => this == ConnectionSecurity.customCertificate;
}
