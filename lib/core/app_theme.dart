import 'package:flutter/material.dart';

class AppTheme {
  // ── Core palette ────────────────────────────────────────────────
  static const Color background    = Color(0xFF0A1020);
  static const Color surface       = Color(0xFF111827);
  static const Color surfaceLight  = Color(0xFF1A2333);
  static const Color cardBackground = Color(0xFF131D2B);
  static const Color primaryNeon   = Color(0xFF39FFA8);
  static const Color primaryCyan   = Color(0xFF00D4FF);
  static const Color accentPurple  = Color(0xFFB57BFF);
  static const Color accentOrange  = Color(0xFFFF9F43);
  static const Color textPrimary   = Colors.white;
  static const Color textSecondary = Color(0xFF8A9BB5);
  static const Color dangerRed     = Color(0xFFFF4757);
  static const Color warningOrange = Color(0xFFFFAA00);
  static const Color successGreen  = Color(0xFF39FFA8);

  // ── Gradient presets ────────────────────────────────────────────
  static const LinearGradient neonGradient = LinearGradient(
    colors: [primaryNeon, primaryCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFFB57BFF), Color(0xFF7B5FFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1A2639), Color(0xFF111827)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Glow shadow presets ─────────────────────────────────────────
  static List<BoxShadow> neonGlow({double intensity = 0.35, double blur = 20}) => [
    BoxShadow(color: primaryNeon.withValues(alpha: intensity), blurRadius: blur),
  ];

  static List<BoxShadow> cyanGlow({double intensity = 0.3, double blur = 16}) => [
    BoxShadow(color: primaryCyan.withValues(alpha: intensity), blurRadius: blur),
  ];

  static List<BoxShadow> purpleGlow({double intensity = 0.3, double blur = 16}) => [
    BoxShadow(color: accentPurple.withValues(alpha: intensity), blurRadius: blur),
  ];

  static List<BoxShadow> cardShadow() => [
    BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 8)),
  ];

  // ── Shared card decorations ──────────────────────────────────────
  static BoxDecoration glassCard({Color? borderColor, double radius = 20}) => BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor ?? Colors.white.withValues(alpha: 0.07)),
    boxShadow: cardShadow(),
  );

  static BoxDecoration glowCard({required Color color, double radius = 20}) => BoxDecoration(
    gradient: LinearGradient(
      colors: [color.withValues(alpha: 0.12), cardBackground],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: color.withValues(alpha: 0.3)),
    boxShadow: [
      BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 20),
      ...cardShadow(),
    ],
  );

  // ── Theme ───────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primaryNeon,
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textSecondary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: primaryNeon),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: primaryNeon,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
        elevation: 0,
      ),
    );
  }
}
