import 'package:admincraft/models/minecraft_edition.dart';
import 'package:admincraft/models/world_state.dart';
import 'package:admincraft/services/console_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses Java time, gamerules, and player counts', () {
    const output = '''
The time is 5231
Gamerule keepInventory is currently set to: false
There are 2 of a max of 20 players online: Alex, Steve
''';

    final state = ConsoleParser.apply(
      const WorldState(),
      output,
      edition: MinecraftEdition.java,
    );

    expect(state.daytime, 5231);
    expect(state.gamerules['keepInventory'], 'false');
    expect(state.playersOnline, 2);
    expect(state.playerLimit, 20);
    expect(
      ConsoleParser.namesFromPlayerCountHeader(
        'There are 2 of a max of 20 players online: Alex, Steve',
        edition: MinecraftEdition.java,
      ),
      ['Alex', 'Steve'],
    );
  });

  test('parses Java join and leave log messages', () {
    const output = '''
[12:00:00 INFO]: Alex joined the game
[12:01:00 INFO]: Steve left the game
''';

    expect(
      ConsoleParser.playerChanges(
        output,
        edition: MinecraftEdition.java,
      ),
      [('Alex', true), ('Steve', false)],
    );
  });
}
