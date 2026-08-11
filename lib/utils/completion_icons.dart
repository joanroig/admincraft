import 'package:admincraft/models/bedrock_command.dart';
import 'package:flutter/material.dart';

/// Icons for completion entries.
///
/// Minecraft's own item textures are not shipped with the app, so identifiers
/// are classified by name into a handful of familiar shapes. It is a rough
/// grouping rather than a per-item icon, which is enough to tell a sword from
/// a food item at a glance while scrolling.
class CompletionIcons {
  static bool _any(String id, List<String> keywords) => keywords.any(id.contains);

  /// Written as direct returns rather than a table of (keywords, icon) pairs.
  ///
  /// Flutter's icon tree shaker finds `IconData` constants by static analysis
  /// and does not see them nested inside records, so a lookup table silently
  /// produced blank glyphs in release builds while working in debug.
  static IconData forItem(String id) {
    if (_any(id, const ['sword', 'axe', 'pickaxe', 'shovel', 'hoe', 'trident', 'mace'])) {
      return Icons.hardware;
    }
    if (_any(id, const ['bow', 'crossbow', 'arrow'])) return Icons.arrow_outward;
    if (_any(id, const ['helmet', 'chestplate', 'leggings', 'boots', 'shield', 'elytra'])) {
      return Icons.shield;
    }
    if (_any(id, const [
      'apple', 'bread', 'cake', 'cookie', 'melon', 'pie', 'carrot', 'potato',
      'beetroot', 'stew', 'beef', 'porkchop', 'chicken', 'mutton', 'rabbit',
      'cod', 'salmon', 'kelp', 'berries', 'honey'
    ])) {
      return Icons.restaurant;
    }
    if (_any(id, const [
      'diamond', 'emerald', 'gold', 'iron', 'copper', 'netherite', 'lapis', 'quartz', 'amethyst'
    ])) {
      return Icons.diamond;
    }
    if (_any(id, const [
      'log', 'planks', 'stairs', 'slab', 'fence', 'door', 'trapdoor', 'sapling', 'leaves', 'bamboo'
    ])) {
      return Icons.park;
    }
    if (_any(id, const ['potion', 'bottle'])) return Icons.science;
    if (_any(id, const ['bucket', 'water', 'lava', 'milk'])) return Icons.water_drop;
    if (_any(id, const [
      'redstone', 'repeater', 'comparator', 'piston', 'observer', 'lever', 'rail'
    ])) {
      return Icons.electrical_services;
    }
    if (_any(id, const ['book', 'map', 'compass', 'clock', 'paper', 'spyglass'])) {
      return Icons.menu_book;
    }
    if (_any(id, const ['minecart', 'boat', 'saddle'])) return Icons.directions_transit;
    if (_any(id, const ['torch', 'lantern', 'campfire', 'glowstone', 'lamp'])) {
      return Icons.lightbulb;
    }
    if (_any(id, const ['chest', 'barrel', 'shulker', 'hopper', 'dropper', 'dispenser'])) {
      return Icons.inventory_2;
    }
    return Icons.widgets;
  }

  static IconData forType(ArgType? type, String value) {
    switch (type) {
      case ArgType.item:
        return forItem(value);
      case ArgType.player:
        return Icons.person;
      case ArgType.entity:
        return Icons.pets;
      case ArgType.effect:
        return Icons.auto_fix_high;
      case ArgType.enchantment:
        return Icons.auto_awesome;
      case ArgType.gamerule:
        return Icons.rule;
      case ArgType.literal:
        return Icons.label_outline;
      default:
        return Icons.terminal;
    }
  }

  /// A colour per kind, so the strip reads as grouped rather than uniform.
  static Color colorFor(ArgType? type, ColorScheme scheme) {
    switch (type) {
      case ArgType.item:
        return scheme.primary;
      case ArgType.player:
        return scheme.tertiary;
      case ArgType.entity:
        return scheme.secondary;
      case ArgType.effect:
      case ArgType.enchantment:
        return scheme.tertiary;
      case ArgType.gamerule:
        return scheme.secondary;
      default:
        return scheme.primary;
    }
  }
}
