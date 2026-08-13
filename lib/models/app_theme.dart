import 'package:flutter/material.dart';

enum AppTheme {
  dirt(
    label: 'Dirt',
    description: 'Warm and earthy',
    seedColor: Color(0xFF6F523D),
    logoAsset: 'docs/logo/variants/dirt.png',
  ),
  grass(
    label: 'Grass',
    description: 'Natural and balanced',
    seedColor: Color(0xFF4F772D),
    logoAsset: 'docs/logo/variants/grass.png',
  ),
  creeper(
    label: 'Creeper',
    description: 'Bright and energetic',
    seedColor: Color(0xFF4C8C2B),
    logoAsset: 'docs/logo/variants/creeper.png',
  ),
  diamond(
    label: 'Diamond',
    description: 'Cool and focused',
    seedColor: Color(0xFF168AAD),
    logoAsset: 'docs/logo/variants/diamond.png',
  ),
  obsidian(
    label: 'Obsidian',
    description: 'Deep and dramatic',
    seedColor: Color(0xFF654A91),
    logoAsset: 'docs/logo/variants/obsidian_glow.png',
  );

  final String label;
  final String description;
  final Color seedColor;
  final String logoAsset;

  const AppTheme({
    required this.label,
    required this.description,
    required this.seedColor,
    required this.logoAsset,
  });
}
