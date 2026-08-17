import 'package:admincraft/data/bedrock_commands.dart';
import 'package:admincraft/data/java_commands.dart';
import 'package:admincraft/models/bedrock_command.dart';
import 'package:admincraft/models/minecraft_edition.dart';

class MinecraftCommands {
  static const _bridgeActions = <String, String>{
    'help': 'help',
    'health': 'health',
    'info': 'info',
    'logs': 'logs',
    'status': 'status',
    'uptime': 'uptime',
    'version': 'version',
    'start': 'start-server',
    'restart': 'restart-server',
    'stop': 'stop-server',
  };

  static BedrockCommand bridgeManagement(Set<String>? capabilities) {
    final actions = capabilities == null
        ? _bridgeActions.values.toList()
        : _bridgeActions.entries
              .where((entry) => capabilities.contains(entry.key))
              .map((entry) => entry.value)
              .toList();
    return BedrockCommand(
      'admincraft',
      'Inspect and manage the bridge; logs accepts an optional line count',
      'Server',
      args: [CommandArg('action', ArgType.literal, options: actions)],
    );
  }

  static List<BedrockCommand> all(
    MinecraftEdition edition, {
    bool includeMinecraftCommands = true,
    bool includeBridgeManagement = false,
    Set<String>? bridgeCapabilities,
  }) => [
    if (includeMinecraftCommands)
      ...(edition == MinecraftEdition.java
          ? JavaCommands.all
          : BedrockCommands.all),
    if (includeBridgeManagement) bridgeManagement(bridgeCapabilities),
  ];

  static Map<String, BedrockCommand> byName(
    MinecraftEdition edition, {
    bool includeMinecraftCommands = true,
    bool includeBridgeManagement = false,
    Set<String>? bridgeCapabilities,
  }) => {
    if (includeMinecraftCommands)
      ...(edition == MinecraftEdition.java
          ? JavaCommands.byName
          : BedrockCommands.byName),
    if (includeBridgeManagement)
      'admincraft': bridgeManagement(bridgeCapabilities),
  };
}
