import 'package:admincraft/utils/completion_icons.dart';
import 'package:flutter/material.dart';

/// The pixel icon for a Minecraft identifier, falling back to a Material icon.
///
/// Only the identifiers the app completes are bundled, and Mojang adds items
/// every release, so a missing file is expected rather than exceptional: the
/// grouped Material icon covers anything without artwork.
class ItemIcon extends StatelessWidget {
  final String id;
  final double size;
  final Color? fallbackColor;

  const ItemIcon(this.id, {super.key, this.size = 20, this.fallbackColor});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/mcicons/$id.png',
      width: size,
      height: size,
      // Pixel art: keep the hard edges instead of smoothing them away.
      filterQuality: FilterQuality.none,
      isAntiAlias: false,
      errorBuilder: (context, error, stack) => Icon(
        CompletionIcons.forItem(id),
        size: size,
        color: fallbackColor,
      ),
    );
  }
}
