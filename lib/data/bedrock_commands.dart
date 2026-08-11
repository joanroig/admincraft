import 'package:admincraft/models/bedrock_command.dart';

/// Bedrock Dedicated Server commands, with the argument structure used to
/// drive completion and the syntax hint.
///
/// Limited to commands a dedicated server console actually accepts. Java-only
/// commands are deliberately absent: `ban` and `worldborder`, for instance,
/// do not exist on Bedrock, and suggesting them only produces errors.
class BedrockCommands {
  static const List<BedrockCommand> all = [
    // ----- Players -----
    BedrockCommand('list', 'Show the players currently connected', 'Players'),
    BedrockCommand('kick', 'Disconnect a player', 'Players', args: [
      CommandArg('player', ArgType.player),
      CommandArg('reason', ArgType.text, required: false),
    ]),
    BedrockCommand('allowlist', 'Manage the allowlist', 'Players', args: [
      CommandArg('action', ArgType.literal,
          options: ['add', 'remove', 'list', 'on', 'off', 'reload']),
      CommandArg('player', ArgType.player, required: false),
    ]),
    BedrockCommand('whitelist', 'Manage the allowlist (legacy name)', 'Players', args: [
      CommandArg('action', ArgType.literal,
          options: ['add', 'remove', 'list', 'on', 'off', 'reload']),
      CommandArg('player', ArgType.player, required: false),
    ]),
    BedrockCommand('op', 'Grant operator status', 'Players', args: [
      CommandArg('player', ArgType.player),
    ]),
    BedrockCommand('deop', 'Revoke operator status', 'Players', args: [
      CommandArg('player', ArgType.player),
    ]),
    BedrockCommand('gamemode', 'Change a player game mode', 'Players', args: [
      CommandArg('mode', ArgType.literal,
          options: ['survival', 'creative', 'adventure', 'spectator']),
      CommandArg('player', ArgType.player, required: false),
    ]),
    BedrockCommand('tell', 'Send a private message', 'Players', args: [
      CommandArg('player', ArgType.player),
      CommandArg('message', ArgType.text),
    ]),
    BedrockCommand('say', 'Broadcast a message to everyone', 'Players', args: [
      CommandArg('message', ArgType.text),
    ]),
    BedrockCommand('me', 'Broadcast an action', 'Players', args: [
      CommandArg('action', ArgType.text),
    ]),
    BedrockCommand('xp', 'Give experience to a player', 'Players', args: [
      CommandArg('amount', ArgType.number),
      CommandArg('player', ArgType.player, required: false),
    ]),
    BedrockCommand('tp', 'Teleport a player', 'Players', args: [
      CommandArg('player', ArgType.player),
      CommandArg('destination', ArgType.player),
    ]),
    BedrockCommand('teleport', 'Teleport a player to coordinates', 'Players', args: [
      CommandArg('player', ArgType.player),
      CommandArg('x y z', ArgType.position),
    ]),
    BedrockCommand('spawnpoint', 'Set a player spawn point', 'Players', args: [
      CommandArg('player', ArgType.player, required: false),
      CommandArg('x y z', ArgType.position, required: false),
    ]),
    BedrockCommand('kill', 'Kill a player or entity', 'Players', args: [
      CommandArg('target', ArgType.player),
    ]),

    // ----- Items -----
    BedrockCommand('give', 'Give an item to a player', 'Items', args: [
      CommandArg('player', ArgType.player),
      CommandArg('item', ArgType.item),
      CommandArg('amount', ArgType.number, required: false),
    ]),
    BedrockCommand('clear', 'Clear items from a player inventory', 'Items', args: [
      CommandArg('player', ArgType.player, required: false),
      CommandArg('item', ArgType.item, required: false),
    ]),
    BedrockCommand('enchant', 'Enchant the held item', 'Items', args: [
      CommandArg('player', ArgType.player),
      CommandArg('enchantment', ArgType.enchantment),
      CommandArg('level', ArgType.number, required: false),
    ]),
    BedrockCommand('effect', 'Apply a status effect', 'Items', args: [
      CommandArg('player', ArgType.player),
      CommandArg('effect', ArgType.effect),
      CommandArg('seconds', ArgType.number, required: false),
      CommandArg('amplifier', ArgType.number, required: false),
    ]),

    // ----- World -----
    BedrockCommand('time', 'Change or query the world time', 'World', args: [
      CommandArg('action', ArgType.literal, options: ['set', 'add', 'query']),
      CommandArg('value', ArgType.literal,
          options: ['day', 'night', 'noon', 'midnight', 'sunrise', 'sunset']),
    ]),
    BedrockCommand('weather', 'Change the weather', 'World', args: [
      CommandArg('type', ArgType.literal, options: ['clear', 'rain', 'thunder']),
      CommandArg('duration', ArgType.number, required: false),
    ]),
    BedrockCommand('difficulty', 'Change the difficulty', 'World', args: [
      CommandArg('level', ArgType.literal,
          options: ['peaceful', 'easy', 'normal', 'hard']),
    ]),
    BedrockCommand('gamerule', 'Read or change a game rule', 'World', args: [
      CommandArg('rule', ArgType.gamerule),
      CommandArg('value', ArgType.literal, required: false, options: ['true', 'false']),
    ]),
    BedrockCommand('setworldspawn', 'Set the world spawn point', 'World', args: [
      CommandArg('x y z', ArgType.position, required: false),
    ]),
    BedrockCommand('summon', 'Spawn an entity', 'World', args: [
      CommandArg('entity', ArgType.entity),
      CommandArg('x y z', ArgType.position, required: false),
    ]),
    BedrockCommand('setblock', 'Place a block', 'World', args: [
      CommandArg('x y z', ArgType.position),
      CommandArg('block', ArgType.item),
    ]),
    BedrockCommand('fill', 'Fill a region with a block', 'World', args: [
      CommandArg('from x y z', ArgType.position),
      CommandArg('to x y z', ArgType.position),
      CommandArg('block', ArgType.item),
    ]),

    // ----- Server -----
    BedrockCommand('save', 'Prepare or resume the world for backup', 'Server', args: [
      CommandArg('action', ArgType.literal, options: ['hold', 'query', 'resume']),
    ]),
    BedrockCommand('changesetting', 'Change a runtime server setting', 'Server', args: [
      CommandArg('setting', ArgType.literal, options: ['allow-cheats', 'difficulty']),
      CommandArg('value', ArgType.text),
    ]),
    BedrockCommand('reload', 'Reload behaviour and resource packs', 'Server'),
    BedrockCommand('stop', 'Stop the server', 'Server'),
    BedrockCommand('help', 'List available commands', 'Server', args: [
      CommandArg('page or command', ArgType.text, required: false),
    ]),
  ];

  static final Map<String, BedrockCommand> byName = {
    for (final command in all) command.name: command,
  };

  static List<String> get categories =>
      all.map((command) => command.category).toSet().toList();
}
