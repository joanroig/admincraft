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

  /// A raw TCP RCON connection straight to a Java server, with no bridge in
  /// between.
  ///
  /// RCON has no encryption of any kind, so the password and every command
  /// cross the network in clear text. Only safe over a private network, and
  /// impossible in a browser, which cannot open raw sockets.
  directRcon,
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
      case ConnectionSecurity.directRcon:
        return 'Direct RCON';
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
      case ConnectionSecurity.directRcon:
        return 'No bridge and no encryption. Only over a private network.';
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
      case ConnectionSecurity.directRcon:
        return 'Direct RCON, no bridge (Java only)';
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
      case ConnectionSecurity.directRcon:
        // The only mode where the address is the Minecraft server itself.
        return 'Address of the Minecraft server';
    }
  }

  String get hostHint {
    switch (this) {
      case ConnectionSecurity.privateNetwork:
        return 'Tailscale or LAN address.';
      case ConnectionSecurity.trustedCertificate:
        // Worth the words: an IP can never validate, and it is the mistake this
        // mode invites.
        return 'A hostname, not an IP.';
      case ConnectionSecurity.customCertificate:
        return 'Must match the loaded certificate.';
      case ConnectionSecurity.directRcon:
        return 'The server itself, over Tailscale, a VPN or a LAN.';
    }
  }

  /// Filled in when switching type, so the port matches the new setup instead
  /// of silently keeping the previous one.
  int get suggestedPort {
    switch (this) {
      case ConnectionSecurity.trustedCertificate:
        return 443;
      case ConnectionSecurity.directRcon:
        return 25575;
      default:
        return 8080;
    }
  }

  String get portHint {
    switch (this) {
      case ConnectionSecurity.privateNetwork:
        return 'Normally 8080.';
      case ConnectionSecurity.trustedCertificate:
        return 'Usually 443.';
      case ConnectionSecurity.customCertificate:
        return 'The published port.';
      case ConnectionSecurity.directRcon:
        return 'The rcon.port from server.properties, normally 25575.';
    }
  }

  /// Whether the connection is established over TLS (`wss://`).
  bool get usesTls =>
      this != ConnectionSecurity.privateNetwork &&
      this != ConnectionSecurity.directRcon;

  /// Whether this mode talks to the Minecraft server directly instead of to the
  /// bridge, which changes what every other field means.
  bool get isDirectRcon => this == ConnectionSecurity.directRcon;

  /// Whether the server log arrives unprompted.
  ///
  /// The bridge streams the container log. RCON only ever answers what it is
  /// asked, so anything that depends on watching for events has to be polled.
  bool get streamsServerLog => !isDirectRcon;

  /// Whether the server can be restarted from the app.
  ///
  /// Restarting is a container operation performed by the bridge. Direct RCON
  /// does not go through Docker, so the command has nowhere to land and the
  /// control is hidden rather than left to fail.
  bool get supportsServerRestart => !isDirectRcon;

  /// Whether the user has to supply a certificate for this mode to work.
  bool get requiresCertificate => this == ConnectionSecurity.customCertificate;
}
