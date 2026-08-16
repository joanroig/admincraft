enum MinecraftEdition {
  bedrock,
  java;

  String get label => switch (this) {
        MinecraftEdition.bedrock => 'Bedrock Edition',
        MinecraftEdition.java => 'Java Edition',
      };

  /// What choosing this edition changes, which is the set of ways the app can
  /// reach the server.
  ///
  /// Said per edition rather than once: the editor used to explain Java's RCON
  /// under the picker whatever was selected, so a Bedrock server was described
  /// in terms of a protocol it does not have.
  String get connectivityHint => switch (this) {
        MinecraftEdition.bedrock =>
          'Bedrock is reached through the bridge, which must run SERVER_TYPE: bedrock.',
        MinecraftEdition.java =>
          'Java can go through the bridge or straight to RCON, chosen below.',
      };
}
