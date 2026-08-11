enum MinecraftEdition {
  bedrock,
  java;

  String get label => switch (this) {
        MinecraftEdition.bedrock => 'Bedrock Edition',
        MinecraftEdition.java => 'Java Edition',
      };
}
