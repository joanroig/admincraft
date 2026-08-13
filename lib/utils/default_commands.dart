import 'package:admincraft/data/bedrock_commands.dart';
import 'package:admincraft/data/java_commands.dart';
import 'package:admincraft/models/minecraft_edition.dart';

class DefaultCommands {
  /// The browsable command list, derived from the same definitions that drive
  /// completion so the two can never disagree. Entries carry their full
  /// syntax, and the `<placeholder>` markers are what the command picker
  /// prompts for.
  static final List<String> commands =
      BedrockCommands.all.map((command) => command.syntax).toList();

  static List<String> forEdition(MinecraftEdition edition) =>
      (edition == MinecraftEdition.java
              ? JavaCommands.all
              : BedrockCommands.all)
          .map((command) => command.syntax)
          .toList();
}
