import 'package:flutter/material.dart';

enum AppTheme {
  dirt(
    label: 'Dirt',
    description: 'Warm and earthy',
    seedColor: Color(0xFF6F523D),
    logoAsset: 'docs/logo/variants/dirt.png',
  ),
  // Two greens can only differ so much by hue, and the default tonalSpot
  // variant throws the seed's chroma away, so shifting saturation alone
  // changed nothing. These differ in hue and in variant: Grass stays a muted
  // yellow-green, Creeper is pushed to a vivid one.
  grass(
    label: 'Grass',
    description: 'Muted and outdoorsy',
    seedColor: Color(0xFF7CB342),
    logoAsset: 'docs/logo/variants/grass.png',
  ),
  creeper(
    label: 'Creeper',
    description: 'Electric and energetic',
    seedColor: Color(0xFF00C853),
    logoAsset: 'docs/logo/variants/creeper.png',
    variant: DynamicSchemeVariant.vibrant,
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

  /// How Material turns the seed into a palette.
  ///
  /// tonalSpot, the default, pins chroma to a constant and keeps only the hue,
  /// which is why two seeds of the same hue family look alike however
  /// differently they are saturated. Choosing another variant is the only way
  /// to make one theme read as vivid and another as muted.
  final DynamicSchemeVariant variant;

  const AppTheme({
    required this.label,
    required this.description,
    required this.seedColor,
    required this.logoAsset,
    this.variant = DynamicSchemeVariant.tonalSpot,
  });
}
