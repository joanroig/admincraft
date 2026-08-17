import 'package:admincraft/models/minecraft_edition.dart';
import 'package:admincraft/utils/command_completion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('numeric arguments offer common stack amounts', () {
    final values = CommandCompletion.suggest(
      'give Steve diamond ',
      onlinePlayers: {'Steve'},
    ).map((completion) => completion.value);

    expect(values, ['1', '5', '10', '20', '64', '128']);
  });

  test('Java completion includes Java-only commands', () {
    final java = CommandCompletion.suggest(
      'ban',
      edition: MinecraftEdition.java,
    );
    final bedrock = CommandCompletion.suggest(
      'ban',
      edition: MinecraftEdition.bedrock,
    );

    expect(java.map((entry) => entry.value), contains('ban'));
    expect(bedrock.map((entry) => entry.value), isNot(contains('ban')));
  });

  test('Java gamerule completion uses Java gamerules', () {
    final suggestions = CommandCompletion.suggest(
      'gamerule playersS',
      edition: MinecraftEdition.java,
    );

    expect(
      suggestions.map((entry) => entry.value),
      contains('playersSleepingPercentage'),
    );
  });

  test('bridge profiles complete container management commands', () {
    final command = CommandCompletion.suggest(
      'admin',
      includeBridgeManagement: true,
    );
    final actions = CommandCompletion.suggest(
      'admincraft ',
      includeBridgeManagement: true,
    );

    expect(command.map((entry) => entry.value), contains('admincraft'));
    expect(actions.map((entry) => entry.value), [
      'health',
      'help',
      'info',
      'logs',
      'restart-server',
      'start-server',
      'status',
      'stop-server',
      'uptime',
      'version',
    ]);
  });

  test('read-only bridge capabilities hide Minecraft and admin commands', () {
    final commands = CommandCompletion.suggest(
      '',
      includeMinecraftCommands: false,
      includeBridgeManagement: true,
      bridgeCapabilities: {'help', 'status', 'version'},
    );
    final actions = CommandCompletion.suggest(
      'admincraft ',
      includeMinecraftCommands: false,
      includeBridgeManagement: true,
      bridgeCapabilities: {'help', 'status', 'version'},
    );

    expect(commands.map((entry) => entry.value), ['admincraft']);
    expect(actions.map((entry) => entry.value), ['help', 'status', 'version']);
  });

  test('bridge log replay offers useful history sizes', () {
    final values = CommandCompletion.suggest(
      'admincraft logs ',
      includeBridgeManagement: true,
    ).map((completion) => completion.value);

    expect(values, ['50', '100', '250', '500', '1000']);
    expect(
      CommandCompletion.suggest(
        'admincraft status ',
        includeBridgeManagement: true,
      ),
      isEmpty,
    );
  });

  test('known commands report missing required arguments', () {
    expect(CommandCompletion.missingRequiredArgument('time')?.name, 'action');
    expect(
      CommandCompletion.missingRequiredArgument('time set')?.name,
      'value',
    );
    expect(CommandCompletion.missingRequiredArgument('time set day'), isNull);
    expect(CommandCompletion.missingRequiredArgument('plugin-command'), isNull);
  });
}
