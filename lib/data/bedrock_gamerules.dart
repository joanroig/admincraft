/// Human wording for game rules.
///
/// The server only ever reports the raw identifier, and names like
/// `doInsomnia` or `showBorderEffect` say very little about what switching
/// them off would actually do.
class GameruleInfo {
  final String label;
  final String description;

  const GameruleInfo(this.label, this.description);
}

class BedrockGamerules {
  static const Map<String, GameruleInfo> info = {
    'commandBlockOutput': GameruleInfo(
      'Command block messages',
      'Command blocks announce what they ran in chat.',
    ),
    'commandBlocksEnabled': GameruleInfo(
      'Command blocks work',
      'Command blocks are allowed to run at all.',
    ),
    'doDaylightCycle': GameruleInfo(
      'Time passes',
      'The sun moves. Turn off to freeze the time of day.',
    ),
    'doEntityDrops': GameruleInfo(
      'Entities drop items',
      'Things like minecarts and item frames drop their contents when broken.',
    ),
    'doFireTick': GameruleInfo(
      'Fire spreads',
      'Fire spreads to nearby blocks and burns out on its own.',
    ),
    'doImmediateRespawn': GameruleInfo(
      'Instant respawn',
      'Players respawn straight away instead of seeing the death screen.',
    ),
    'doInsomnia': GameruleInfo(
      'Phantoms appear',
      'Phantoms spawn around players who have not slept for a few nights.',
    ),
    'doLimitedCrafting': GameruleInfo(
      'Recipes must be unlocked',
      'Players can only craft recipes they have already discovered.',
    ),
    'doMobLoot': GameruleInfo(
      'Mobs drop loot',
      'Killed mobs drop items and experience.',
    ),
    'doMobSpawning': GameruleInfo(
      'Mobs spawn',
      'New mobs appear naturally around the world.',
    ),
    'doTileDrops': GameruleInfo(
      'Blocks drop items',
      'Broken blocks drop something to pick up.',
    ),
    'doWeatherCycle': GameruleInfo(
      'Weather changes',
      'Rain and storms come and go by themselves.',
    ),
    'drowningDamage': GameruleInfo(
      'Drowning hurts',
      'Players take damage when they run out of air.',
    ),
    'fallDamage': GameruleInfo(
      'Falling hurts',
      'Players take damage from long falls.',
    ),
    'fireDamage': GameruleInfo(
      'Fire hurts',
      'Players take damage from fire and lava.',
    ),
    'freezeDamage': GameruleInfo(
      'Freezing hurts',
      'Players take damage from powder snow.',
    ),
    'functionCommandLimit': GameruleInfo(
      'Function command limit',
      'How many commands a single function may run.',
    ),
    'keepInventory': GameruleInfo(
      'Keep items on death',
      'Players keep everything they were carrying when they die.',
    ),
    'maxCommandChainLength': GameruleInfo(
      'Command chain limit',
      'How many command blocks may run in one chain.',
    ),
    'mobGriefing': GameruleInfo(
      'Mobs change the world',
      'Creepers, endermen and others can break or move blocks.',
    ),
    'naturalRegeneration': GameruleInfo(
      'Health regenerates',
      'Players heal over time when well fed.',
    ),
    'pvp': GameruleInfo(
      'Players can fight',
      'Players are able to damage each other.',
    ),
    'randomTickSpeed': GameruleInfo(
      'World tick speed',
      'How fast crops grow and leaves decay. Higher values are heavier on the server.',
    ),
    'respawnBlocksExplode': GameruleInfo(
      'Beds explode in the wrong place',
      'Beds and respawn anchors explode when used in the Nether or the End.',
    ),
    'sendCommandFeedback': GameruleInfo(
      'Command replies',
      'Commands report their result back. Turning this off also hides them from the console.',
    ),
    'showBorderEffect': GameruleInfo(
      'World border effect',
      'The visual effect shown at the world border.',
    ),
    'showCoordinates': GameruleInfo(
      'Show coordinates',
      'Players see their position on screen.',
    ),
    'showDeathMessages': GameruleInfo(
      'Death messages',
      'Everyone is told when a player dies.',
    ),
    'showRecipeMessages': GameruleInfo(
      'Recipe unlocked messages',
      'Players are told when they discover a new recipe.',
    ),
    'showTags': GameruleInfo(
      'Show tags',
      'Item tags are visible in tooltips.',
    ),
    'spawnRadius': GameruleInfo(
      'Spawn spread',
      'How far from the spawn point players may appear.',
    ),
    'tntExplodes': GameruleInfo(
      'TNT explodes',
      'TNT can be lit and detonate.',
    ),
  };

  /// Falls back to the raw name so an unknown rule still renders sensibly:
  /// Mojang adds rules over time and the app should not hide them.
  static GameruleInfo forName(String name) {
    final match = info.entries.firstWhere(
      (entry) => entry.key.toLowerCase() == name.toLowerCase(),
      orElse: () => const MapEntry('', GameruleInfo('', '')),
    );
    if (match.key.isEmpty) return GameruleInfo(name, '');
    return match.value;
  }
}
