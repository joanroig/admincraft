import 'package:flutter/material.dart';

/// A faint blocky texture behind the app, in the spirit of Minecraft's terrain.
///
/// Drawn rather than shipped as an image: a texture wants to tile at any size
/// and follow the current theme, and a fixed asset would do neither. The noise
/// is derived from the cell coordinates, so it is stable across repaints and
/// identical on every device rather than shimmering as the layout changes.
class PixelBackdrop extends StatelessWidget {
  final Widget child;

  /// Size of one block. Large enough to read as pixel art rather than grain.
  static const double cell = 24;

  const PixelBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              // On a light page the blocks have to be darker than what they sit
              // on, and the primary alone is too pale to register, so it is
              // pulled towards the foreground colour first.
              painter: _PixelPainter(
                tint: dark
                    ? scheme.primary
                    : Color.lerp(scheme.primary, scheme.onSurface, 0.45)!,
                dark: dark,
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _PixelPainter extends CustomPainter {
  final Color tint;
  final bool dark;

  const _PixelPainter({required this.tint, required this.dark});

  /// Cheap deterministic hash. Any stable scatter will do; what matters is that
  /// the same cell always yields the same value.
  int _noise(int x, int y) {
    var h = x * 374761393 + y * 668265263;
    h = (h ^ (h >> 13)) * 1274126177;
    return (h ^ (h >> 16)) & 0x7fffffff;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // No background is painted: the scaffold already supplies one, and painting
    // a second copy here would mean keeping the two in step forever.
    final columns = (size.width / PixelBackdrop.cell).ceil();
    final rows = (size.height / PixelBackdrop.cell).ceil();
    final paint = Paint();

    for (var x = 0; x < columns; x++) {
      for (var y = 0; y < rows; y++) {
        final value = _noise(x, y) % 100;

        // Only a scattering of cells are tinted at all. A full grid reads as a
        // pattern rather than as texture, and fights everything on top of it.
        if (value > 22) continue;

        // Kept low: this sits behind text, and anything stronger competes with
        // it. Light pages need more than dark ones, not less, because a faint
        // wash over near-white disappears entirely.
        final strength = (value % 3 + 1) * (dark ? 0.012 : 0.018);
        paint.color = tint.withValues(alpha: strength);

        canvas.drawRect(
          Rect.fromLTWH(
            x * PixelBackdrop.cell,
            y * PixelBackdrop.cell,
            PixelBackdrop.cell,
            PixelBackdrop.cell,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PixelPainter old) => old.tint != tint || old.dark != dark;
}
