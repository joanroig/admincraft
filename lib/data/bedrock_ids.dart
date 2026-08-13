/// Identifier vocabularies used to complete command arguments.
///
/// Identifiers are listed without the `minecraft:` namespace: Bedrock accepts
/// the short form, and the Admincraft WebSocket server rejects colons before a
/// command is ever run.
class BedrockIds {
  /// Status effects accepted by `effect`.
  static const List<String> effects = [
    'absorption', 'bad_omen', 'blindness', 'conduit_power', 'darkness',
    'fatal_poison', 'fire_resistance', 'haste', 'health_boost', 'hunger',
    'instant_damage', 'instant_health', 'invisibility', 'jump_boost',
    'levitation', 'mining_fatigue', 'nausea', 'night_vision', 'poison',
    'regeneration', 'resistance', 'saturation', 'slow_falling', 'slowness',
    'speed', 'strength', 'village_hero', 'weakness', 'wither',
  ];

  /// Enchantments accepted by `enchant`.
  static const List<String> enchantments = [
    'aqua_affinity', 'bane_of_arthropods', 'binding', 'blast_protection',
    'channeling', 'depth_strider', 'efficiency', 'feather_falling',
    'fire_aspect', 'fire_protection', 'flame', 'fortune', 'frost_walker',
    'impaling', 'infinity', 'knockback', 'looting', 'loyalty',
    'luck_of_the_sea', 'lure', 'mending', 'multishot', 'piercing', 'power',
    'projectile_protection', 'protection', 'punch', 'quick_charge',
    'respiration', 'riptide', 'sharpness', 'silk_touch', 'smite',
    'soul_speed', 'swift_sneak', 'thorns', 'unbreaking', 'vanishing',
  ];

  /// Game rules accepted by `gamerule`.
  static const List<String> gamerules = [
    'commandBlockOutput', 'commandBlocksEnabled', 'doDaylightCycle',
    'doEntityDrops', 'doFireTick', 'doImmediateRespawn', 'doInsomnia',
    'doLimitedCrafting', 'doMobLoot', 'doMobSpawning', 'doTileDrops',
    'doWeatherCycle', 'drowningDamage', 'fallDamage', 'fireDamage',
    'freezeDamage', 'functionCommandLimit', 'keepInventory',
    'maxCommandChainLength', 'mobGriefing', 'naturalRegeneration', 'pvp',
    'randomTickSpeed', 'respawnBlocksExplode', 'sendCommandFeedback',
    'showBorderEffect', 'showCoordinates', 'showDeathMessages',
    'showRecipeMessages', 'showTags', 'spawnRadius', 'tntExplodes',
  ];

  /// Entities accepted by `summon` and entity-targeting commands.
  static const List<String> entities = [
    'allay', 'armadillo', 'armor_stand', 'axolotl', 'bat', 'bee', 'blaze',
    'bogged', 'breeze', 'camel', 'cat', 'cave_spider', 'chicken', 'cod', 'cow',
    'creeper', 'dolphin', 'donkey', 'drowned', 'elder_guardian', 'enderman',
    'endermite', 'ender_dragon', 'evocation_illager', 'fox', 'frog', 'ghast',
    'glow_squid', 'goat', 'guardian', 'hoglin', 'horse', 'husk', 'iron_golem',
    'llama', 'magma_cube', 'mooshroom', 'mule', 'ocelot', 'panda', 'parrot',
    'phantom', 'pig', 'piglin', 'piglin_brute', 'pillager', 'polar_bear',
    'pufferfish', 'rabbit', 'ravager', 'salmon', 'sheep', 'shulker',
    'silverfish', 'skeleton', 'skeleton_horse', 'slime', 'sniffer',
    'snow_golem', 'spider', 'squid', 'stray', 'strider', 'tadpole',
    'trader_llama', 'tropicalfish', 'turtle', 'vex', 'villager', 'vindicator',
    'wandering_trader', 'warden', 'witch', 'wither', 'wither_skeleton', 'wolf',
    'zoglin', 'zombie', 'zombie_horse', 'zombie_villager', 'zombified_piglin',
  ];

  /// Items and blocks accepted by `give`, `clear` and block commands.
  ///
  /// A useful subset rather than the whole game: enough that the common cases
  /// complete, without carrying thousands of entries in the app.
  static const List<String> items = [
    // Ores, ingots and gems
    'coal', 'charcoal', 'raw_copper', 'raw_gold', 'raw_iron', 'copper_ingot',
    'gold_ingot', 'iron_ingot', 'netherite_ingot', 'netherite_scrap', 'diamond',
    'emerald', 'lapis_lazuli', 'quartz', 'amethyst_shard', 'redstone',
    'gold_nugget', 'iron_nugget', 'ancient_debris',
    // Blocks
    'stone', 'cobblestone', 'deepslate', 'granite', 'diorite', 'andesite',
    'calcite', 'tuff', 'dripstone_block', 'grass_block', 'dirt', 'coarse_dirt',
    'podzol', 'mycelium', 'sand', 'red_sand', 'gravel', 'clay', 'obsidian',
    'crying_obsidian', 'bedrock', 'netherrack', 'soul_sand', 'soul_soil',
    'magma', 'glowstone', 'end_stone', 'sandstone', 'red_sandstone',
    'stone_bricks', 'mossy_cobblestone', 'bricks', 'nether_brick',
    'red_nether_brick', 'blackstone', 'polished_blackstone',
    'polished_blackstone_bricks', 'basalt', 'smooth_basalt', 'prismarine',
    'sea_lantern', 'glass', 'tinted_glass', 'ice', 'packed_ice', 'blue_ice',
    'snow', 'moss_block', 'sculk', 'bone_block', 'honeycomb_block',
    'honey_block', 'slime', 'hay_block', 'sponge', 'tnt', 'scaffolding',
    // Metal and gem blocks
    'iron_block', 'gold_block', 'diamond_block', 'emerald_block',
    'netherite_block', 'copper_block', 'redstone_block', 'lapis_block',
    'coal_block', 'amethyst_block',
    // Wood
    'oak_log', 'spruce_log', 'birch_log', 'jungle_log', 'acacia_log',
    'dark_oak_log', 'mangrove_log', 'cherry_log', 'crimson_stem',
    'warped_stem', 'oak_planks', 'spruce_planks', 'birch_planks',
    'jungle_planks', 'acacia_planks', 'dark_oak_planks', 'mangrove_planks',
    'cherry_planks', 'bamboo_planks', 'crimson_planks', 'warped_planks',
    'oak_stairs', 'oak_slab', 'oak_fence', 'oak_fence_gate', 'oak_door',
    'oak_trapdoor', 'oak_sapling', 'oak_leaves', 'bamboo', 'stick',
    // Tools and weapons
    'wooden_sword', 'stone_sword', 'iron_sword', 'golden_sword',
    'diamond_sword', 'netherite_sword', 'wooden_pickaxe', 'stone_pickaxe',
    'iron_pickaxe', 'golden_pickaxe', 'diamond_pickaxe', 'netherite_pickaxe',
    'wooden_axe', 'stone_axe', 'iron_axe', 'golden_axe', 'diamond_axe',
    'netherite_axe', 'wooden_shovel', 'stone_shovel', 'iron_shovel',
    'golden_shovel', 'diamond_shovel', 'netherite_shovel', 'wooden_hoe',
    'stone_hoe', 'iron_hoe', 'golden_hoe', 'diamond_hoe', 'netherite_hoe',
    'bow', 'crossbow', 'arrow', 'spectral_arrow', 'trident', 'shield',
    'fishing_rod', 'flint_and_steel', 'shears', 'brush', 'mace',
    // Armour
    'leather_helmet', 'leather_chestplate', 'leather_leggings',
    'leather_boots', 'chainmail_helmet', 'chainmail_chestplate',
    'chainmail_leggings', 'chainmail_boots', 'iron_helmet', 'iron_chestplate',
    'iron_leggings', 'iron_boots', 'golden_helmet', 'golden_chestplate',
    'golden_leggings', 'golden_boots', 'diamond_helmet', 'diamond_chestplate',
    'diamond_leggings', 'diamond_boots', 'netherite_helmet',
    'netherite_chestplate', 'netherite_leggings', 'netherite_boots',
    'turtle_helmet', 'elytra',
    // Food
    'apple', 'golden_apple', 'enchanted_golden_apple', 'bread', 'cake',
    'cookie', 'melon_slice', 'pumpkin_pie', 'carrot', 'golden_carrot',
    'potato', 'baked_potato', 'beetroot', 'beetroot_soup', 'mushroom_stew',
    'rabbit_stew', 'suspicious_stew', 'beef', 'cooked_beef', 'porkchop',
    'cooked_porkchop', 'chicken', 'cooked_chicken', 'mutton', 'cooked_mutton',
    'rabbit', 'cooked_rabbit', 'cod', 'cooked_cod', 'salmon', 'cooked_salmon',
    'dried_kelp', 'sweet_berries', 'glow_berries', 'honey_bottle',
    // Utility blocks
    'crafting_table', 'furnace', 'blast_furnace', 'smoker', 'anvil',
    'enchanting_table', 'brewing_stand', 'cauldron', 'beacon', 'conduit',
    'chest', 'trapped_chest', 'ender_chest', 'shulker_box', 'barrel', 'hopper',
    'dropper', 'dispenser', 'observer', 'piston', 'sticky_piston', 'lectern',
    'grindstone', 'smithing_table', 'stonecutter', 'cartography_table',
    'fletching_table', 'loom', 'composter', 'bell', 'campfire',
    'soul_campfire', 'lantern', 'soul_lantern', 'torch', 'soul_torch',
    'redstone_torch', 'lever', 'tripwire_hook', 'target', 'lightning_rod',
    'respawn_anchor', 'bed', 'item_frame', 'armor_stand', 'flower_pot',
    'end_crystal',
    // Redstone and transport
    'redstone_lamp', 'repeater', 'comparator', 'daylight_detector', 'rail',
    'powered_rail', 'detector_rail', 'activator_rail', 'minecart',
    'chest_minecart', 'hopper_minecart', 'tnt_minecart', 'oak_boat', 'saddle',
    // Miscellaneous
    'bucket', 'water_bucket', 'lava_bucket', 'milk_bucket', 'powder_snow_bucket',
    'book', 'writable_book', 'written_book', 'enchanted_book', 'paper', 'map',
    'compass', 'recovery_compass', 'clock', 'spyglass', 'name_tag', 'lead',
    'ender_pearl', 'ender_eye', 'blaze_rod', 'blaze_powder', 'ghast_tear',
    'magma_cream', 'nether_star', 'nether_wart', 'gunpowder', 'string',
    'feather', 'leather', 'rabbit_hide', 'bone', 'bone_meal', 'slime_ball',
    'egg', 'snowball', 'firework_rocket', 'totem_of_undying', 'heart_of_the_sea',
    'nautilus_shell', 'phantom_membrane', 'scute', 'echo_shard',
    'experience_bottle', 'potion', 'splash_potion', 'lingering_potion',
    'glass_bottle', 'wheat', 'wheat_seeds', 'sugar', 'sugar_cane',
    'shulker_shell', 'prismarine_shard', 'prismarine_crystals', 'flint',
    'brick', 'nether_brick_item', 'clay_ball', 'wooden_sign', 'painting',
  ];

  /// Every vocabulary that is not derived at runtime, by argument kind.
  static List<String> forType(String type) {
    switch (type) {
      case 'item':
        return items;
      case 'entity':
        return entities;
      case 'effect':
        return effects;
      case 'enchantment':
        return enchantments;
      case 'gamerule':
        return gamerules;
      default:
        return const [];
    }
  }
}
