import 'package:admincraft/models/bedrock_command.dart';

/// Commands available from a vanilla-compatible Java server console.
///
/// Paper, Purpur, Fabric, Forge and NeoForge may add more commands, but this
/// catalog deliberately sticks to the common Java server surface.
class JavaCommands {
  static const List<BedrockCommand> all = [
    BedrockCommand('list', 'Show the players currently connected', 'Players'),
    BedrockCommand('kick', 'Disconnect a player', 'Players', args: [
      CommandArg('player', ArgType.player),
      CommandArg('reason', ArgType.text, required: false),
    ]),
    BedrockCommand('whitelist', 'Manage the whitelist', 'Players', args: [
      CommandArg('action', ArgType.literal,
          options: ['add', 'remove', 'list', 'on', 'off', 'reload']),
      CommandArg('player', ArgType.player, required: false),
    ]),
    BedrockCommand('ban', 'Ban a player', 'Players', args: [
      CommandArg('player', ArgType.player),
      CommandArg('reason', ArgType.text, required: false),
    ]),
    BedrockCommand('pardon', 'Remove a player ban', 'Players', args: [
      CommandArg('player', ArgType.player),
    ]),
    BedrockCommand('ban-ip', 'Ban an IP address', 'Players', args: [
      CommandArg('address', ArgType.text),
    ]),
    BedrockCommand('pardon-ip', 'Remove an IP address ban', 'Players', args: [
      CommandArg('address', ArgType.text),
    ]),
    BedrockCommand('banlist', 'Show player or IP bans', 'Players', args: [
      CommandArg('type', ArgType.literal,
          required: false, options: ['players', 'ips']),
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
    BedrockCommand('msg', 'Send a private message', 'Players', args: [
      CommandArg('player', ArgType.player),
      CommandArg('message', ArgType.text),
    ]),
    BedrockCommand('say', 'Broadcast a message to everyone', 'Players', args: [
      CommandArg('message', ArgType.text),
    ]),
    BedrockCommand('xp', 'Add or set player experience', 'Players', args: [
      CommandArg('action', ArgType.literal, options: ['add', 'set', 'query']),
      CommandArg('player', ArgType.player),
      CommandArg('amount', ArgType.number, required: false),
    ]),
    BedrockCommand('tp', 'Teleport a player', 'Players', args: [
      CommandArg('player', ArgType.player),
      CommandArg('destination or x y z', ArgType.text),
    ]),
    BedrockCommand('spawnpoint', 'Set a player spawn point', 'Players', args: [
      CommandArg('player', ArgType.player, required: false),
      CommandArg('x y z', ArgType.position, required: false),
    ]),
    BedrockCommand('kill', 'Kill a player or entity', 'Players', args: [
      CommandArg('target', ArgType.player, required: false),
    ]),
    BedrockCommand('give', 'Give an item to a player', 'Items', args: [
      CommandArg('player', ArgType.player),
      CommandArg('item', ArgType.item),
      CommandArg('amount', ArgType.number, required: false),
    ]),
    BedrockCommand('clear', 'Clear items from a player inventory', 'Items',
        args: [
          CommandArg('player', ArgType.player, required: false),
          CommandArg('item', ArgType.item, required: false),
        ]),
    BedrockCommand('enchant', 'Enchant the held item', 'Items', args: [
      CommandArg('player', ArgType.player),
      CommandArg('enchantment', ArgType.enchantment),
      CommandArg('level', ArgType.number, required: false),
    ]),
    BedrockCommand('effect', 'Manage status effects', 'Items', args: [
      CommandArg('action', ArgType.literal, options: ['give', 'clear']),
      CommandArg('player', ArgType.player),
      CommandArg('effect', ArgType.effect, required: false),
      CommandArg('seconds', ArgType.number, required: false),
    ]),
    BedrockCommand('time', 'Change or query the world time', 'World', args: [
      CommandArg('action', ArgType.literal, options: ['set', 'add', 'query']),
      CommandArg('value', ArgType.literal,
          options: ['day', 'night', 'noon', 'midnight', 'daytime']),
    ]),
    BedrockCommand('weather', 'Change the weather', 'World', args: [
      CommandArg('type', ArgType.literal,
          options: ['clear', 'rain', 'thunder']),
      CommandArg('duration', ArgType.number, required: false),
    ]),
    BedrockCommand('difficulty', 'Change the difficulty', 'World', args: [
      CommandArg('level', ArgType.literal,
          options: ['peaceful', 'easy', 'normal', 'hard']),
    ]),
    BedrockCommand('gamerule', 'Read or change a game rule', 'World', args: [
      CommandArg('rule', ArgType.gamerule),
      CommandArg('value', ArgType.literal,
          required: false, options: ['true', 'false']),
    ]),
    BedrockCommand('setworldspawn', 'Set the world spawn point', 'World',
        args: [
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
    BedrockCommand('worldborder', 'Manage the world border', 'World', args: [
      CommandArg('action', ArgType.literal,
          options: ['add', 'center', 'damage', 'get', 'set', 'warning']),
      CommandArg('value', ArgType.text, required: false),
    ]),
    BedrockCommand('seed', 'Show the world seed', 'World'),
    BedrockCommand('save-all', 'Save the world to disk', 'Server', args: [
      CommandArg('flush', ArgType.literal, required: false, options: ['flush']),
    ]),
    BedrockCommand('save-on', 'Enable automatic world saving', 'Server'),
    BedrockCommand('save-off', 'Disable automatic world saving', 'Server'),
    BedrockCommand('reload', 'Reload data packs and functions', 'Server'),
    BedrockCommand('stop', 'Stop the server', 'Server'),
    BedrockCommand('help', 'List available commands', 'Server', args: [
      CommandArg('command', ArgType.text, required: false),
    ]),
  ];

  static final Map<String, BedrockCommand> byName = {
    for (final command in all) command.name: command,
  };
}
