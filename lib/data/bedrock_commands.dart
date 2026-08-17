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
    BedrockCommand(
      'kick',
      'Disconnect a player',
      'Players',
      args: [
        CommandArg('player', ArgType.player),
        CommandArg('reason', ArgType.text, required: false),
      ],
    ),
    BedrockCommand(
      'allowlist',
      'Manage the allowlist',
      'Players',
      args: [
        CommandArg(
          'action',
          ArgType.literal,
          options: ['add', 'remove', 'list', 'on', 'off', 'reload'],
        ),
        CommandArg('player', ArgType.player, required: false),
      ],
    ),
    BedrockCommand(
      'whitelist',
      'Manage the allowlist (legacy name)',
      'Players',
      args: [
        CommandArg(
          'action',
          ArgType.literal,
          options: ['add', 'remove', 'list', 'on', 'off', 'reload'],
        ),
        CommandArg('player', ArgType.player, required: false),
      ],
    ),
    BedrockCommand(
      'op',
      'Grant operator status',
      'Players',
      args: [CommandArg('player', ArgType.player)],
    ),
    BedrockCommand(
      'deop',
      'Revoke operator status',
      'Players',
      args: [CommandArg('player', ArgType.player)],
    ),
    BedrockCommand(
      'gamemode',
      'Change a player game mode',
      'Players',
      args: [
        CommandArg(
          'mode',
          ArgType.literal,
          options: ['survival', 'creative', 'adventure', 'spectator'],
        ),
        CommandArg('player', ArgType.player, required: false),
      ],
    ),
    BedrockCommand(
      'tell',
      'Send a private message',
      'Players',
      args: [
        CommandArg('player', ArgType.player),
        CommandArg('message', ArgType.text),
      ],
    ),
    BedrockCommand(
      'say',
      'Broadcast a message to everyone',
      'Players',
      args: [CommandArg('message', ArgType.text)],
    ),
    BedrockCommand(
      'me',
      'Broadcast an action',
      'Players',
      args: [CommandArg('action', ArgType.text)],
    ),
    BedrockCommand(
      'xp',
      'Give experience to a player',
      'Players',
      args: [
        CommandArg('amount', ArgType.number),
        CommandArg('player', ArgType.player, required: false),
      ],
    ),
    BedrockCommand(
      'tp',
      'Teleport a player',
      'Players',
      args: [
        CommandArg('player', ArgType.player),
        CommandArg('destination', ArgType.player),
      ],
    ),
    BedrockCommand(
      'teleport',
      'Teleport a player to coordinates',
      'Players',
      args: [
        CommandArg('player', ArgType.player),
        CommandArg('x y z', ArgType.position),
      ],
    ),
    BedrockCommand(
      'spawnpoint',
      'Set a player spawn point',
      'Players',
      args: [
        CommandArg('player', ArgType.player, required: false),
        CommandArg('x y z', ArgType.position, required: false),
      ],
    ),
    BedrockCommand(
      'kill',
      'Kill a player or entity',
      'Players',
      args: [CommandArg('target', ArgType.player)],
    ),
    BedrockCommand(
      'camera',
      'Change a player camera perspective',
      'Players',
      args: [CommandArg('arguments', ArgType.text, required: false)],
    ),
    BedrockCommand(
      'camerashake',
      'Add or stop player camera shake',
      'Players',
      args: [CommandArg('arguments', ArgType.text, required: false)],
    ),
    BedrockCommand(
      'clearspawnpoint',
      'Remove a player spawn point',
      'Players',
      args: [CommandArg('player', ArgType.player, required: false)],
    ),
    BedrockCommand(
      'controlscheme',
      'Set or clear a player control scheme',
      'Players',
      args: [CommandArg('arguments', ArgType.text, required: false)],
    ),
    BedrockCommand(
      'damage',
      'Apply damage to entities',
      'Players',
      args: [CommandArg('arguments', ArgType.text, required: false)],
    ),
    BedrockCommand(
      'dialogue',
      'Open or change NPC dialogue',
      'Players',
      args: [CommandArg('arguments', ArgType.text, required: false)],
    ),
    BedrockCommand(
      'hud',
      'Show or hide HUD elements',
      'Players',
      args: [CommandArg('arguments', ArgType.text, required: false)],
    ),
    BedrockCommand(
      'inputpermission',
      'Change player input permissions',
      'Players',
      args: [CommandArg('arguments', ArgType.text, required: false)],
    ),
    BedrockCommand(
      'playanimation',
      'Play an animation on entities',
      'Players',
      args: [CommandArg('arguments', ArgType.text, required: false)],
    ),
    BedrockCommand(
      'title',
      'Control player screen titles',
      'Players',
      args: [CommandArg('arguments', ArgType.text, required: false)],
    ),
    BedrockCommand(
      'titleraw',
      'Control player titles with JSON text',
      'Players',
      args: [CommandArg('arguments', ArgType.text, required: false)],
    ),
    BedrockCommand(
      'transfer',
      'Transfer a player to another server',
      'Players',
      args: [CommandArg('arguments', ArgType.text, required: false)],
    ),

    // ----- Items -----
    BedrockCommand(
      'give',
      'Give an item to a player',
      'Items',
      args: [
        CommandArg('player', ArgType.player),
        CommandArg('item', ArgType.item),
        CommandArg('amount', ArgType.number, required: false),
      ],
    ),
    BedrockCommand(
      'clear',
      'Clear items from a player inventory',
      'Items',
      args: [
        CommandArg('player', ArgType.player, required: false),
        CommandArg('item', ArgType.item, required: false),
      ],
    ),
    BedrockCommand(
      'enchant',
      'Enchant the held item',
      'Items',
      args: [
        CommandArg('player', ArgType.player),
        CommandArg('enchantment', ArgType.enchantment),
        CommandArg('level', ArgType.number, required: false),
      ],
    ),
    BedrockCommand(
      'effect',
      'Apply a status effect',
      'Items',
      args: [
        CommandArg('player', ArgType.player),
        CommandArg('effect', ArgType.effect),
        CommandArg('seconds', ArgType.number, required: false),
        CommandArg('amplifier', ArgType.number, required: false),
      ],
    ),
    BedrockCommand(
      'loot',
      'Place loot into the world or an inventory',
      'Items',
      args: [CommandArg('arguments', ArgType.text, required: false)],
    ),
    BedrockCommand(
      'recipe',
      'Lock or unlock player recipes',
      'Items',
      args: [CommandArg('arguments', ArgType.text, required: false)],
    ),
    BedrockCommand(
      'replaceitem',
      'Replace items in inventories',
      'Items',
      args: [CommandArg('arguments', ArgType.text, required: false)],
    ),

    // ----- World -----
    BedrockCommand(
      'time',
      'Change or query the world time',
      'World',
      args: [
        CommandArg('action', ArgType.literal, options: ['set', 'add', 'query']),
        CommandArg(
          'value',
          ArgType.literal,
          options: ['day', 'night', 'noon', 'midnight', 'sunrise', 'sunset'],
        ),
      ],
    ),
    BedrockCommand(
      'weather',
      'Change the weather',
      'World',
      args: [
        CommandArg(
          'type',
          ArgType.literal,
          options: ['clear', 'rain', 'thunder'],
        ),
        CommandArg('duration', ArgType.number, required: false),
      ],
    ),
    BedrockCommand(
      'difficulty',
      'Change the difficulty',
      'World',
      args: [
        CommandArg(
          'level',
          ArgType.literal,
          options: ['peaceful', 'easy', 'normal', 'hard'],
        ),
      ],
    ),
    BedrockCommand(
      'gamerule',
      'Read or change a game rule',
      'World',
      args: [
        CommandArg('rule', ArgType.gamerule),
        CommandArg(
          'value',
          ArgType.literal,
          required: false,
          options: ['true', 'false'],
        ),
      ],
    ),
    BedrockCommand(
      'setworldspawn',
      'Set the world spawn point',
      'World',
      args: [CommandArg('x y z', ArgType.position, required: false)],
    ),
    BedrockCommand(
      'summon',
      'Spawn an entity',
      'World',
      args: [
        CommandArg('entity', ArgType.entity),
        CommandArg('x y z', ArgType.position, required: false),
      ],
    ),
    BedrockCommand(
      'setblock',
      'Place a block',
      'World',
      args: [
        CommandArg('x y z', ArgType.position),
        CommandArg('block', ArgType.item),
      ],
    ),
    BedrockCommand(
      'fill',
      'Fill a region with a block',
      'World',
      args: [
        CommandArg('from x y z', ArgType.position),
        CommandArg('to x y z', ArgType.position),
        CommandArg('block', ArgType.item),
      ],
    ),
    BedrockCommand(
      'clone',
      'Clone blocks from one region to another',
      'World',
      args: [CommandArg('arguments', ArgType.text, required: false)],
    ),
    BedrockCommand(
      'daylock',
      'Lock or unlock the day-night cycle',
      'World',
      args: [
        CommandArg(
          'locked',
          ArgType.literal,
          required: false,
          options: ['true', 'false'],
        ),
      ],
    ),
    BedrockCommand(
      'event',
      'Trigger an entity event',
      'World',
      args: [CommandArg('arguments', ArgType.text, required: false)],
    ),
    BedrockCommand(
      'execute',
      'Run a command in another context',
      'World',
      args: [CommandArg('arguments', ArgType.text, required: false)],
    ),
    BedrockCommand(
      'fog',
      'Add or remove fog settings',
      'World',
      args: [CommandArg('arguments', ArgType.text, required: false)],
    ),
    BedrockCommand(
      'function',
      'Run a behavior-pack function',
      'World',
      args: [CommandArg('function', ArgType.text, required: false)],
    ),
    BedrockCommand(
      'locate',
      'Find the nearest biome or structure',
      'World',
      args: [CommandArg('arguments', ArgType.text, required: false)],
    ),
    BedrockCommand(
      'mobevent',
      'Control whether a mob event can run',
      'World',
      args: [CommandArg('arguments', ArgType.text, required: false)],
    ),
    BedrockCommand(
      'music',
      'Control music playback',
      'World',
      args: [CommandArg('arguments', ArgType.text, required: false)],
    ),
    BedrockCommand(
      'particle',
      'Create a particle emitter',
      'World',
      args: [CommandArg('arguments', ArgType.text, required: false)],
    ),
    BedrockCommand(
      'place',
      'Place a feature or jigsaw structure',
      'World',
      args: [CommandArg('arguments', ArgType.text, required: false)],
    ),
    BedrockCommand(
      'playsound',
      'Play a sound for players',
      'World',
      args: [CommandArg('arguments', ArgType.text, required: false)],
    ),
    BedrockCommand(
      'ride',
      'Manage entities riding other entities',
      'World',
      args: [CommandArg('arguments', ArgType.text, required: false)],
    ),
    BedrockCommand(
      'schedule',
      'Schedule a function to run later',
      'World',
      args: [CommandArg('arguments', ArgType.text, required: false)],
    ),
    BedrockCommand(
      'scoreboard',
      'Manage objectives and scores',
      'World',
      args: [CommandArg('arguments', ArgType.text, required: false)],
    ),
    BedrockCommand(
      'scriptevent',
      'Send an event to a script',
      'World',
      args: [CommandArg('arguments', ArgType.text, required: false)],
    ),
    BedrockCommand(
      'spreadplayers',
      'Spread entities across an area',
      'World',
      args: [CommandArg('arguments', ArgType.text, required: false)],
    ),
    BedrockCommand(
      'stopsound',
      'Stop a sound for players',
      'World',
      args: [CommandArg('arguments', ArgType.text, required: false)],
    ),
    BedrockCommand(
      'structure',
      'Save or load a structure',
      'World',
      args: [CommandArg('arguments', ArgType.text, required: false)],
    ),
    BedrockCommand(
      'tag',
      'Manage tags stored on entities',
      'World',
      args: [CommandArg('arguments', ArgType.text, required: false)],
    ),
    BedrockCommand(
      'tellraw',
      'Send a JSON message to players',
      'World',
      args: [CommandArg('arguments', ArgType.text, required: false)],
    ),
    BedrockCommand(
      'testfor',
      'Count entities matching a selector',
      'World',
      args: [CommandArg('arguments', ArgType.text, required: false)],
    ),
    BedrockCommand(
      'testforblock',
      'Test the block at a position',
      'World',
      args: [CommandArg('arguments', ArgType.text, required: false)],
    ),
    BedrockCommand(
      'testforblocks',
      'Compare blocks between regions',
      'World',
      args: [CommandArg('arguments', ArgType.text, required: false)],
    ),
    BedrockCommand(
      'tickingarea',
      'Manage ticking areas',
      'World',
      args: [CommandArg('arguments', ArgType.text, required: false)],
    ),
    BedrockCommand('toggledownfall', 'Toggle rain or clear weather', 'World'),

    // ----- Server -----
    BedrockCommand(
      'save',
      'Prepare or resume the world for backup',
      'Server',
      args: [
        CommandArg(
          'action',
          ArgType.literal,
          options: ['hold', 'query', 'resume'],
        ),
      ],
    ),
    BedrockCommand(
      'changesetting',
      'Change a runtime server setting',
      'Server',
      args: [
        CommandArg(
          'setting',
          ArgType.literal,
          options: ['allow-cheats', 'difficulty'],
        ),
        CommandArg('value', ArgType.text),
      ],
    ),
    BedrockCommand(
      'reload',
      'Reload behavior-pack functions and scripts',
      'Server',
    ),
    BedrockCommand(
      'packstack',
      'Print the active resource and behavior packs',
      'Server',
    ),
    BedrockCommand(
      'permission',
      'Reload dedicated-server permissions',
      'Server',
      args: [
        CommandArg(
          'action',
          ArgType.literal,
          required: false,
          options: ['list', 'reload'],
        ),
      ],
    ),
    BedrockCommand(
      'reloadconfig',
      'Reload server variables, secrets, and permissions',
      'Server',
    ),
    BedrockCommand(
      'reloadpacketlimitconfig',
      'Reload the packet limit configuration',
      'Server',
    ),
    BedrockCommand(
      'script',
      'Use server script debugging tools',
      'Server',
      args: [CommandArg('arguments', ArgType.text, required: false)],
    ),
    BedrockCommand(
      'sendshowstoreoffer',
      'Open a Marketplace page for players',
      'Server',
      args: [CommandArg('arguments', ArgType.text, required: false)],
    ),
    BedrockCommand(
      'setmaxplayers',
      'Set the maximum players for this session',
      'Server',
      args: [CommandArg('count', ArgType.number)],
    ),
    BedrockCommand(
      'stop',
      'Ask Minecraft to save and shut down gracefully',
      'Server',
    ),
    BedrockCommand(
      'wsserver',
      'Connect Minecraft to a WebSocket server',
      'Server',
      args: [CommandArg('url', ArgType.text, required: false)],
    ),
    BedrockCommand(
      'help',
      'List available commands',
      'Server',
      args: [CommandArg('page or command', ArgType.text, required: false)],
    ),
  ];

  static final Map<String, BedrockCommand> byName = {
    for (final command in all) command.name: command,
  };

  static List<String> get categories =>
      all.map((command) => command.category).toSet().toList();
}
