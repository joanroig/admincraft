import 'package:admincraft/models/connection_security.dart';
import 'package:admincraft/models/minecraft_edition.dart';

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
  final MinecraftEdition edition;

  const ServerProfile({
    required this.id,
    required this.alias,
    required this.ip,
    required this.port,
    required this.secretKey,
    required this.certificate,
    required this.security,
    this.edition = MinecraftEdition.bedrock,
  });

  factory ServerProfile.empty(String id) => ServerProfile(
        id: id,
        alias: 'New Server',
        ip: '',
        port: 8080,
        secretKey: '',
        certificate: '',
        security: ConnectionSecurity.privateNetwork,
        edition: MinecraftEdition.bedrock,
      );

  ServerProfile copyWith({
    String? alias,
    String? ip,
    int? port,
    String? secretKey,
    String? certificate,
    ConnectionSecurity? security,
    MinecraftEdition? edition,
  }) {
    return ServerProfile(
      id: id,
      alias: alias ?? this.alias,
      ip: ip ?? this.ip,
      port: port ?? this.port,
      secretKey: secretKey ?? this.secretKey,
      certificate: certificate ?? this.certificate,
      security: security ?? this.security,
      edition: edition ?? this.edition,
    );
  }

  /// True once there is enough here to attempt a connection.
  bool get isComplete => ip.isNotEmpty && secretKey.isNotEmpty;

  /// [includeSecrets] must stay true for an encrypted export, which is useless
  /// without the key, and false for plain storage, where the key does not belong.
  Map<String, dynamic> toJson({bool includeSecrets = true}) => {
        'id': id,
        'alias': alias,
        'ip': ip,
        'port': port,
        if (includeSecrets) 'secretKey': secretKey,
        if (includeSecrets) 'certificate': certificate,
        'security': security.name,
        'edition': edition.name,
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
      // Profiles saved before Java support were always Bedrock profiles.
      edition: MinecraftEdition.values.firstWhere(
        (value) => value.name == json['edition'],
        orElse: () => MinecraftEdition.bedrock,
      ),
    );
  }
}
