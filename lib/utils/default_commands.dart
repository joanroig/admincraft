// default_commands.dart
class DefaultCommands {
  static final List<String> commands = [
    'help',
    'list',
    'kick <player>',
    'ban <player>',
    'unban <player>',
    'give <player> <item> [amount] [dataTag]',
    'tp <player> <destination>',
    'teleport <player> <x> <y> <z>',
    'setworldspawn <x> <y> <z>',
    'spawnpoint <player> [x] [y] [z]',
    'weather <clear|rain|thunder>',
    'time set <day|night|<value>>',
    'difficulty <peaceful|easy|normal|hard>',
    'gamerule <rule> <value>',
    'effect <player> <effect> [seconds] [amplifier] [hideParticles]',
    'fill <x1> <y1> <z1> <x2> <y2> <z2> <block> [dataTag]',
    'clone <fromX> <fromY> <fromZ> <toX> <toY> <toZ> <destinationX> <destinationY> <destinationZ> [mode]',
    'say <message>',
    'me <action>',
    'scoreboard objectives add <name> <criteria>',
    'scoreboard players set <player> <objective> <value>',
    'worldborder <set|add|center|damage|warning> [parameters]',
    'whitelist add <player>',
    'whitelist remove <player>',
    'whitelist list',
    'whitelist reload'
  ];
}
