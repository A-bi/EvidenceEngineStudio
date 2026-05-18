import 'package:flutter/material.dart';

class AppTheme {
  static const Color sidebar = Color(0xFF26382E);
  static const Color canvas = Color(0xFFF0F5EB);
  static const Color card = Color(0xFFE3EEDF);
  static const Color selectedCard = Color(0xFFC7DEC2);
  static const Color accent = Color(0xFF477D54);
  static const Color accentSoft = Color(0xFFA8CCA3);
  static const Color primaryText = Color(0xFF1D261F);
  static const Color secondaryText = Color(0xFF5C6B60);
  static const Color mutedText = Color(0xFF7B897F);
  static const Color border = Color(0xFFD1D8CF);
  static const Color borderStrong = Color(0xFF6B946B);
  static const Color warning = Color(0xFFFF9800);

  static const double cardPadding = 18;
  static const double cornerRadius = 22;
  static const double sectionSpacing = 20;

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: canvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        primary: accent,
        surface: canvas,
      ),
      fontFamily: 'Arial',
    );
  }
}
