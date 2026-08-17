import 'package:admincraft/models/bedrock_command.dart';
import 'package:admincraft/utils/dialog_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('commands are alphabetical inside the existing category order', () {
    const commands = [
      BedrockCommand('zebra', '', 'Players'),
      BedrockCommand('apple', '', 'Players'),
      BedrockCommand('weather', '', 'World'),
      BedrockCommand('difficulty', '', 'World'),
      BedrockCommand('stop', '', 'Server'),
      BedrockCommand('help', '', 'Server'),
    ];

    final sorted = DialogUtils.sortCommandsWithinCategories(commands);

    expect(sorted.map((command) => command.name), [
      'apple',
      'zebra',
      'difficulty',
      'weather',
      'help',
      'stop',
    ]);
    expect(sorted.map((command) => command.category).toSet().toList(), [
      'Players',
      'World',
      'Server',
    ]);
  });
}
