import 'package:admincraft/models/model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The current theme's pixel-art logo.
///
/// Switching theme repaints everything at once, and the logo changing in the
/// same frame reads as a glitch rather than as a choice taking effect, so it
/// fades and scales across instead.
class ThemeLogo extends StatelessWidget {
  /// Kept a multiple of 16: the source is 16x16, and anything else lands the
  /// pixel grid between device pixels and softens it.
  final double size;

  const ThemeLogo({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    final appTheme = context.select((Model model) => model.appTheme);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.86, end: 1).animate(animation),
          child: child,
        ),
      ),
      child: Image.asset(
        appTheme.logoAsset,
        key: ValueKey(appTheme),
        width: size,
        height: size,
        // Required, not cosmetic: the default is scaleDown, which never
        // enlarges, so the 16px source rendered at 16px however large the box
        // was asked to be.
        fit: BoxFit.fill,
        filterQuality: FilterQuality.none,
        isAntiAlias: false,
      ),
    );
  }
}
