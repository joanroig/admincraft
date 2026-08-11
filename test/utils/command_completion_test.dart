import 'package:admincraft/models/minecraft_edition.dart';
import 'package:admincraft/utils/command_completion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
}
