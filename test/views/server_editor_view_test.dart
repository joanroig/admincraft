import 'package:admincraft/models/connection_security.dart';
import 'package:admincraft/models/minecraft_edition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The editor describes a bridge for three of the four connection types and
  // the Minecraft server for the fourth. Every one of these labels was once a
  // fixed string naming the bridge, so choosing direct RCON left the window
  // asking for a bridge port and a bridge key that do not exist in that mode,
  // and telling the reader the field was "not the RCON password" when the RCON
  // password is exactly what it wanted.
  test('direct RCON labels the fields after the Minecraft server', () {
    const rcon = ConnectionSecurity.directRcon;

    expect(rcon.portLabel, 'RCON port');
    expect(rcon.secretLabel, 'RCON password');
    expect(rcon.secretHint, contains('server.properties'));
    expect(rcon.secretMissingMessage, contains('RCON password'));
    expect(rcon.fieldsDescribe, contains('Minecraft server itself'));
    expect(rcon.hostLabel, contains('Minecraft server'));
  });

  test('the bridge modes label the fields after the bridge', () {
    for (final security in ConnectionSecurity.values.where((s) => !s.isDirectRcon)) {
      expect(security.portLabel, 'Bridge port', reason: security.name);
      expect(security.secretLabel, 'Bridge secret key', reason: security.name);
      expect(security.fieldsDescribe, contains('bridge'), reason: security.name);
    }
  });

  // Said per edition because it is the edition that decides it: the hint used
  // to describe Java's RCON while Bedrock was selected, which reads as though
  // Bedrock had RCON too.
  test('each edition explains only how it can be reached', () {
    expect(MinecraftEdition.java.connectivityHint, contains('RCON'));
    expect(MinecraftEdition.bedrock.connectivityHint, isNot(contains('RCON')));
    expect(MinecraftEdition.bedrock.connectivityHint, contains('bridge'));
  });
}
