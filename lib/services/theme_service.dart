import 'package:admincraft/models/model.dart';
import 'package:flutter/material.dart';

class ThemeService {
  static String font = 'Roboto';
  static double fontSize = 24.0;

  static TextTheme textThemeFromStyles(Model model) {
    font = model.font;
    fontSize = model.fontSize;

    TextStyle light = TextStyle(fontFamily: font, fontWeight: FontWeight.w300);
    TextStyle regular = TextStyle(fontFamily: font, fontWeight: FontWeight.w400);
    TextStyle medium = TextStyle(fontFamily: font, fontWeight: FontWeight.w500);
    TextStyle semiBold = TextStyle(fontFamily: font, fontWeight: FontWeight.w600);

    return TextTheme(
      displayLarge: light.copyWith(fontSize: fontSize * 3.375), // 54 is 16 * 3.375
      displayMedium: light.copyWith(fontSize: fontSize * 2.625), // 42 is 16 * 2.625
      displaySmall: light.copyWith(fontSize: fontSize * 1.875), // Default: 16 * 1.875
      headlineLarge: regular.copyWith(fontSize: fontSize * 1.5), // Default: 16 * 1.5
      headlineMedium: regular.copyWith(fontSize: fontSize * 1.25), // Default: 16 * 1.25
      headlineSmall: regular.copyWith(fontSize: fontSize * 1.0), // Default: 16 * 1.0
      titleLarge: semiBold.copyWith(fontSize: fontSize * 1.25), // Default: 16 * 1.25
      titleMedium: medium.copyWith(fontSize: fontSize * 1.0), // Default: 16 * 1.0
      titleSmall: medium.copyWith(fontSize: fontSize * 0.875), // Default: 16 * 0.875
      bodyLarge: regular.copyWith(fontSize: fontSize), // Regular is base size: 16 * 1.0
      bodyMedium: regular.copyWith(fontSize: fontSize * 0.875), // Regular is base size: 16 * 0.875
      bodySmall: regular.copyWith(fontSize: fontSize * 0.75), // Regular is base size: 16 * 0.75
      labelLarge: medium.copyWith(fontSize: fontSize * 0.9375), // 15 is 16 * 0.9375
      labelMedium: medium.copyWith(fontSize: fontSize * 0.875), // Default: 16 * 0.875
      labelSmall: medium.copyWith(fontSize: fontSize * 0.8125), // Default: 16 * 0.8125
    );
  }
}
