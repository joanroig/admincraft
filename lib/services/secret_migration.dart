import 'package:admincraft/services/persistence_service.dart';
import 'package:admincraft/services/server_secrets.dart';

/// Moves server keys and certificates out of plain storage into the keystore.
///
/// Deliberately cautious: the key is what makes a profile usable, so the plain
/// copy is only dropped after the keystore has handed the same value back.
/// If anything fails the profiles are left exactly as they were, which keeps a
/// device with no working keystore usable instead of silently unable to connect.
Future<void> migrateServerSecrets(
  PersistenceService persistence,
  ServerSecrets secrets,
) async {
  if (!secrets.available) return;

  final servers = persistence.servers;
  final pending =
      servers.where((server) => secrets.isEmptyFor(server.id) && server.secretKey.isNotEmpty);
  if (pending.isEmpty) return;

  for (final server in pending) {
    await secrets.write(
      server.id,
      secretKey: server.secretKey,
      certificate: server.certificate,
    );
    if (!await secrets.verify(server.id, server.secretKey)) return;
  }

  // Rewrites the list, which now omits the secrets because the vault holds them.
  await persistence.saveServers(servers);
}
