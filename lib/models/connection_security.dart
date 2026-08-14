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

  /// How this option reads in the picker: named after the setup someone has,
  /// not after the mechanism, since the setup is what they know.
  String get typeLabel {
    switch (this) {
      case ConnectionSecurity.privateNetwork:
        return 'Private network (Tailscale, VPN or LAN)';
      case ConnectionSecurity.trustedCertificate:
        return 'Public address, trusted certificate';
      case ConnectionSecurity.customCertificate:
        return 'Public address, self-signed certificate';
    }
  }

  /// The address field means something different per type, so it is labelled
  /// per type rather than left as a generic "Host".
  String get hostLabel {
    switch (this) {
      case ConnectionSecurity.privateNetwork:
        return 'Private address of the bridge';
      case ConnectionSecurity.trustedCertificate:
        return 'Public hostname of the bridge';
      case ConnectionSecurity.customCertificate:
        return 'Public address of the bridge';
    }
  }

  String get hostHint {
    switch (this) {
      case ConnectionSecurity.privateNetwork:
        return 'The Tailscale address, such as 100.101.102.103, or a LAN address.';
      case ConnectionSecurity.trustedCertificate:
        // The single most common failure in this mode: certificates are issued
        // to names, so an address that is only an IP can never validate.
        return 'A hostname, such as a Tailscale Funnel ts.net name or your own '
            'domain. A bare IP cannot work here, because certificates are '
            'issued to names.';
      case ConnectionSecurity.customCertificate:
        return 'Must match the certificate loaded below, or the check fails.';
    }
  }

  /// Filled in when switching type, so the port matches the new setup instead
  /// of silently keeping the previous one.
  int get suggestedPort =>
      this == ConnectionSecurity.trustedCertificate ? 443 : 8080;

  String get portHint {
    switch (this) {
      case ConnectionSecurity.privateNetwork:
        return 'The bridge port, normally 8080.';
      case ConnectionSecurity.trustedCertificate:
        return 'Usually 443. Funnel also allows 8443 and 10000.';
      case ConnectionSecurity.customCertificate:
        return 'Whichever port the bridge is published on.';
    }
  }

  /// Whether the connection is established over TLS (`wss://`).
  bool get usesTls => this != ConnectionSecurity.privateNetwork;

  /// Whether the user has to supply a certificate for this mode to work.
  bool get requiresCertificate => this == ConnectionSecurity.customCertificate;
}
