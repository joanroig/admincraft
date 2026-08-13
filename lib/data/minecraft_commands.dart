import 'package:admincraft/data/bedrock_commands.dart';
import 'package:admincraft/data/java_commands.dart';
import 'package:admincraft/models/bedrock_command.dart';
import 'package:admincraft/models/minecraft_edition.dart';

class MinecraftCommands {
  static List<BedrockCommand> all(MinecraftEdition edition) =>
      edition == MinecraftEdition.java ? JavaCommands.all : BedrockCommands.all;

  static Map<String, BedrockCommand> byName(MinecraftEdition edition) =>
      edition == MinecraftEdition.java
          ? JavaCommands.byName
          : BedrockCommands.byName;
}
