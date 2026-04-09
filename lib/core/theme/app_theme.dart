import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- PREMIUM GOLD & BLACK DESIGN SYSTEM ---
  
  // Brand Colors (Gold accents)
  static const Color primaryGoldDark = Color(0xFFD4AF37);  // Rich Gold
  static const Color primaryGoldLight = Color(0xFFC9A227); // Deep Gold (Better contrast on white)
  static const Color accentCyan = Color(0xFF00B4D8); // Subtle highlight
  
  // Dark Mode Colors (Primary Experience)
  static const Color bgDark = Color(0xFF0B0F14); // Deep Black/Blue background
  static const Color surfaceDark = Color(0xFF121821); // Elevated Surface
  static const Color onSurfaceDark = Color(0xFFFFFFFF); // Pure White Text
  static const Color onSurfaceVariantDark = Color(0xFF94A3B8); // Muted Grey
  static const Color borderDark = Color(0xFF222B38); // Subtle border
  
  // Light Mode Colors
  static const Color bgLight = Color(0xFFF8F9FB); // Clean soft background
  static const Color surfaceLight = Colors.white; // Pure white cards
  static const Color onSurfaceLight = Color(0xFF1E293B); // Dark slate text
  static const Color onSurfaceVariantLight = Color(0xFF64748B); // Muted grey text
  static const Color borderLight = Color(0xFFE2E8F0);

  // Common styles
  static final _cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  );

  static final _buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  );

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGoldLight,
        primary: primaryGoldLight,
        secondary: accentCyan,
        surface: bgLight,
        onSurface: onSurfaceLight,
        onSurfaceVariant: onSurfaceVariantLight,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: bgLight,
      canvasColor: bgLight,
      useMaterial3: true,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(color: onSurfaceLight, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.inter(color: onSurfaceLight, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.inter(color: onSurfaceLight, fontWeight: FontWeight.w600, fontSize: 20),
        bodyLarge: GoogleFonts.inter(color: onSurfaceLight),
        bodyMedium: GoogleFonts.inter(color: onSurfaceVariantLight),
      ).apply(
        bodyColor: onSurfaceLight,
        displayColor: onSurfaceLight,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: onSurfaceLight),
        titleTextStyle: TextStyle(color: onSurfaceLight, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: primaryGoldLight.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            color: isSelected ? onSurfaceLight : onSurfaceVariantLight,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected ? onSurfaceLight : onSurfaceVariantLight,
          );
        }),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shadowColor: Colors.black.withAlpha(10), // Extremely subtle shadow
        shape: _cardShape.copyWith(side: const BorderSide(color: borderLight, width: 1)),
        color: surfaceLight,
        margin: EdgeInsets.zero,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: _buttonShape,
          side: const BorderSide(color: primaryGoldLight),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          foregroundColor: primaryGoldLight,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: _buttonShape,
          backgroundColor: primaryGoldLight,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      iconTheme: const IconThemeData(color: onSurfaceVariantLight),
      dividerTheme: const DividerThemeData(color: borderLight, space: 1, thickness: 1),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGoldDark,
        primary: primaryGoldDark,
        secondary: accentCyan,
        surface: surfaceDark,
        onSurface: onSurfaceDark,
        onSurfaceVariant: onSurfaceVariantDark,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: bgDark,
      canvasColor: bgDark,
      useMaterial3: true,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(color: onSurfaceDark, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.inter(color: onSurfaceDark, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.inter(color: onSurfaceDark, fontWeight: FontWeight.w600, fontSize: 20),
        bodyLarge: GoogleFonts.inter(color: onSurfaceDark),
        bodyMedium: GoogleFonts.inter(color: onSurfaceVariantDark),
      ).apply(
        bodyColor: onSurfaceDark,
        displayColor: onSurfaceDark,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: onSurfaceDark),
        titleTextStyle: TextStyle(color: onSurfaceDark, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: primaryGoldDark.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            color: isSelected ? onSurfaceDark : onSurfaceVariantDark,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected ? onSurfaceDark : onSurfaceVariantDark,
          );
        }),
      ),
      cardTheme: CardThemeData(
        elevation: 0, // No shadows in dark mode!
        shape: _cardShape.copyWith(
          side: const BorderSide(color: borderDark, width: 1),
        ),
        color: surfaceDark,
        margin: EdgeInsets.zero,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: _buttonShape,
          side: const BorderSide(color: primaryGoldDark),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          foregroundColor: primaryGoldDark,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: _buttonShape,
          backgroundColor: primaryGoldDark,
          foregroundColor: bgDark, // High contrast text on Gold button
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      iconTheme: const IconThemeData(color: onSurfaceVariantDark),
      dividerTheme: const DividerThemeData(color: borderDark, space: 1, thickness: 1),
    );
  }
}
