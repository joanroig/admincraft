import 'package:flutter/material.dart';

enum AppTheme {
  dirt(
    label: 'Dirt',
    description: 'Warm and earthy',
    seedColor: Color(0xFF6F523D),
    logoAsset: 'docs/logo/variants/dirt.png',
  ),
  // Grass and Creeper were nine degrees apart in hue, which Material's tonal
  // mapping flattened into near-identical schemes. Grass now leans olive and
  // Creeper toward a vivid spring green, far enough apart to tell at a glance.
  grass(
    label: 'Grass',
    description: 'Olive and outdoorsy',
    seedColor: Color(0xFF6F8F1E),
    logoAsset: 'docs/logo/variants/grass.png',
  ),
  creeper(
    label: 'Creeper',
    description: 'Bright and energetic',
    seedColor: Color(0xFF16A34A),
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
  ),
  // Fills the one hue the set was missing. The others sit between brown and
  // purple going through green and cyan, leaving nothing on the red side.
  pig(
    label: 'Pig',
    description: 'Soft and rosy',
    seedColor: Color(0xFFD2536B),
    logoAsset: 'docs/logo/variants/pig.png',
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
