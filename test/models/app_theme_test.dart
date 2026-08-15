import 'dart:io';
import 'dart:math' as math;

import 'package:admincraft/models/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rough perceptual distance between two colours, enough to catch palettes
/// that collapse into each other without pulling in a colour-science package.
double _distance(Color a, Color b) {
  final dr = ((a.r - b.r) * 255).toDouble();
  final dg = ((a.g - b.g) * 255).toDouble();
  final db = ((a.b - b.b) * 255).toDouble();
  return math.sqrt(dr * dr + dg * dg + db * db);
}

ColorScheme _schemeFor(AppTheme theme, Brightness brightness) =>
    ColorScheme.fromSeed(
      seedColor: theme.seedColor,
      brightness: brightness,
      dynamicSchemeVariant: theme.variant,
    );

void main() {
  test('every theme produces a distinguishable palette', () {
    for (final brightness in Brightness.values) {
      final schemes = {
        for (final theme in AppTheme.values) theme: _schemeFor(theme, brightness),
      };

      for (final a in AppTheme.values) {
        for (final b in AppTheme.values) {
          if (a.index >= b.index) continue;
          final gap = _distance(schemes[a]!.primary, schemes[b]!.primary);
          // The closest pair in the set measures about 49. The old threshold
          // of 24 was low enough to pass the two greens that were reported as
          // indistinguishable, at 40.6, so it never guarded anything: this is
          // set just under what the set actually holds.
          expect(
            gap,
            greaterThan(45),
            reason: '${a.label} and ${b.label} look alike in $brightness '
                '(primary distance ${gap.toStringAsFixed(1)})',
          );
        }
      }
    }
  });

  // A theme whose art is not bundled looks fine in every test and throws only
  // when someone selects it in a real build.
  test('every theme logo is bundled', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final theme in AppTheme.values) {
      expect(
        File(theme.logoAsset).existsSync(),
        isTrue,
        reason: '${theme.label} points at a missing file: ${theme.logoAsset}',
      );
      expect(
        pubspec.contains('- ${theme.logoAsset}'),
        isTrue,
        reason: '${theme.label} logo is not declared in pubspec assets',
      );
    }
  });
}
