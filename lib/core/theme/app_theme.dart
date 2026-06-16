import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  // Base surfaces
  static const Color background    = Color(0xFF080C14);
  static const Color surface       = Color(0xFF0D1117);
  static const Color surfaceRaised = Color(0xFF1A1F2E);

  // Accent — Premium Glass purple
  static const Color accent         = Color(0xFF6C63FF);
  static const Color accentLight    = Color(0xFF7C74FF);
  static const Color accentDark     = Color(0xFF5A52D5);
  static const Color accentGlow     = Color(0x4D6C63FF); // 30% opacity
  static const Color accentBorder   = Color(0x666C63FF); // 40% opacity

  // Power button red
  static const Color powerRed = Color(0xFFE05252);

  // Glass button borders
  static const Color glassButtonBorder       = Color(0x1AFFFFFF); // white 10%
  static const Color glassButtonBorderActive = Color(0xB36C63FF); // purple 70%

  // Text
  static const Color textPrimary = Color(0xFFCCCCCC);
  static const Color textMuted   = Color(0xFF888888);
  static const Color textDim     = Color(0xFF555555);

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme(
      brightness:  Brightness.dark,
      primary:     accent,
      onPrimary:   Colors.white,
      secondary:   accentLight,
      onSecondary: Colors.white,
      error:       powerRed,
      onError:     Colors.white,
      surface:     surface,
      onSurface:   textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surfaceRaised,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: glassButtonBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: glassButtonBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 2),
        ),
        hintStyle: const TextStyle(color: textDim),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}
