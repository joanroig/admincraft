import 'package:admincraft/models/connection_security.dart';

/// One saved server, with everything needed to connect to it.
class ServerProfile {
  /// Stable identifier, so renaming a server does not lose the selection.
  final String id;
  final String alias;
  final String ip;
  final int port;
  final String secretKey;
  final String certificate;
  final ConnectionSecurity security;

  const ServerProfile({
    required this.id,
    required this.alias,
    required this.ip,
    required this.port,
    required this.secretKey,
    required this.certificate,
    required this.security,
  });

  factory ServerProfile.empty(String id) => ServerProfile(
        id: id,
        alias: 'New Server',
        ip: '',
        port: 8080,
        secretKey: '',
        certificate: '',
        security: ConnectionSecurity.privateNetwork,
      );

  ServerProfile copyWith({
    String? alias,
    String? ip,
    int? port,
    String? secretKey,
    String? certificate,
    ConnectionSecurity? security,
  }) {
    return ServerProfile(
      id: id,
      alias: alias ?? this.alias,
      ip: ip ?? this.ip,
      port: port ?? this.port,
      secretKey: secretKey ?? this.secretKey,
      certificate: certificate ?? this.certificate,
      security: security ?? this.security,
    );
  }

  /// True once there is enough here to attempt a connection.
  bool get isComplete => ip.isNotEmpty && secretKey.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'alias': alias,
        'ip': ip,
        'port': port,
        'secretKey': secretKey,
        'certificate': certificate,
        'security': security.name,
      };

  factory ServerProfile.fromJson(Map<String, dynamic> json) {
    return ServerProfile(
      id: json['id'] as String,
      alias: json['alias'] as String? ?? 'Server',
      ip: json['ip'] as String? ?? '',
      port: json['port'] as int? ?? 8080,
      secretKey: json['secretKey'] as String? ?? '',
      certificate: json['certificate'] as String? ?? '',
      security: ConnectionSecurity.values.firstWhere(
        (value) => value.name == json['security'],
        // Matches the pre-profile rule: a stored certificate meant TLS was on.
        orElse: () => (json['certificate'] as String? ?? '').isEmpty
            ? ConnectionSecurity.privateNetwork
            : ConnectionSecurity.customCertificate,
      ),
    );
  }
}
