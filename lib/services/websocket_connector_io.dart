import 'dart:convert';
import 'dart:io';

import 'package:admincraft/models/connection_security.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Native platforms can decide for themselves which certificates to trust.
const bool supportsCustomCertificate = true;

/// Builds the trust configuration for the selected security mode.
///
/// Rebuilt on every connection so that changing the mode or the certificate in
/// the settings takes effect right away, without restarting the app.
SecurityContext _buildSecurityContext(ConnectionSecurity security, String certificateData) {
  // Loading a certificate is a deliberate pin: trust it and nothing else, so
  // a self-signed setup cannot be silently satisfied by a public authority.
  final context = SecurityContext(withTrustedRoots: !security.requiresCertificate);

  if (security.requiresCertificate && certificateData.isNotEmpty) {
    try {
      context.setTrustedCertificatesBytes(utf8.encode(certificateData));
    } catch (e) {
      print('Error loading certificate: $e');
    }
  }

  return context;
}

WebSocketChannel connectWebSocket({
  required Uri uri,
  required ConnectionSecurity security,
  required String certificate,
}) {
  return IOWebSocketChannel.connect(
    uri,
    customClient: security.usesTls ? HttpClient(context: _buildSecurityContext(security, certificate)) : null,
  );
}
