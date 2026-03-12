import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Main backgrounds - sandy/beach tones
  static const Color background = Color(0xFFF2DFC3);
  static const Color backgroundDark = Color(0xFFE5CEAA);
  static const Color surface = Color(0xFFFFFEF5);
  static const Color surfaceWarm = Color(0xFFFFF5E6);

  // Teal accents
  static const Color teal = Color(0xFF6DC5B0);
  static const Color tealDark = Color(0xFF54A896);

  // Primary & accent
  static const Color primary = Color(0xFF5EBFAB);
  static const Color accent = Color(0xFFF5D76E);
  static const Color accentDark = Color(0xFFD4A843);
  static const Color leafGreen = Color(0xFF3AAA8A);
  static const Color warmBrown = Color(0xFF8B6914);

  // Text - warm browns on sandy background
  static const Color textDark = Color(0xFF3D2E1C);
  static const Color textMedium = Color(0xFF5C4A32);
  static const Color textLight = Color(0xFF9B8568);
  static const Color textOnSand = Color(0xFF4A3828);

  // Note card colors
  static const Color cream = Color(0xFFFFFEF2);
  static const Color pastelPink = Color(0xFFFFD4D4);
  static const Color pastelBlue = Color(0xFFD4E8FF);
  static const Color pastelYellow = Color(0xFFFFF4B8);
  static const Color pastelGreen = Color(0xFFD4F0D4);
  static const Color pastelOrange = Color(0xFFFFE4C4);
  static const Color pastelPurple = Color(0xFFE8D4F0);
  static const Color pastelMint = Color(0xFFD4F0E8);

  // UI elements
  static const Color scrollbar = Color(0xFFC4A87A);
  static const Color divider = Color(0xFFE0D0B8);
  static const Color shadow = Color(0x25000000);
  static const Color iconBg = Color(0xFFF0E4D0);
  static const Color danger = Color(0xFFE88B8B);

  // AI-specific
  static const Color aiShimmer = Color(0xFFB8E5D8);
  static const Color aiGlow = Color(0x206DC5B0);

  static Color getNoteColor(String colorName) {
    switch (colorName) {
      case 'pink':
        return pastelPink;
      case 'blue':
        return pastelBlue;
      case 'yellow':
        return pastelYellow;
      case 'green':
        return pastelGreen;
      case 'orange':
        return pastelOrange;
      case 'purple':
        return pastelPurple;
      case 'mint':
        return pastelMint;
      case 'cream':
      default:
        return cream;
    }
  }

  static const List<MapEntry<String, Color>> noteColorOptions = [
    MapEntry('cream', cream),
    MapEntry('pink', pastelPink),
    MapEntry('blue', pastelBlue),
    MapEntry('yellow', pastelYellow),
    MapEntry('green', pastelGreen),
    MapEntry('orange', pastelOrange),
    MapEntry('purple', pastelPurple),
    MapEntry('mint', pastelMint),
  ];
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        surface: AppColors.surface,
      ),
      textTheme: GoogleFonts.quicksandTextTheme().copyWith(
        headlineLarge: GoogleFonts.quicksand(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
        headlineMedium: GoogleFonts.quicksand(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
        titleLarge: GoogleFonts.quicksand(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
        titleMedium: GoogleFonts.quicksand(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        bodyLarge: GoogleFonts.quicksand(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textMedium,
        ),
        bodyMedium: GoogleFonts.quicksand(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textMedium,
        ),
        bodySmall: GoogleFonts.quicksand(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textLight,
        ),
        labelLarge: GoogleFonts.quicksand(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.quicksand(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textOnSand,
        ),
        iconTheme: const IconThemeData(color: AppColors.textOnSand),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        shadowColor: AppColors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      scrollbarTheme: const ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(AppColors.scrollbar),
        trackColor: WidgetStatePropertyAll(Colors.transparent),
        trackBorderColor: WidgetStatePropertyAll(Colors.transparent),
        radius: Radius.circular(6),
        thickness: WidgetStatePropertyAll(4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.divider, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: GoogleFonts.quicksand(
          color: AppColors.textLight,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class AppDecorations {
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      );

  static BoxDecoration noteCardDecoration(String colorName) => BoxDecoration(
        color: AppColors.getNoteColor(colorName),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getNoteColor(colorName).withValues(
            red: AppColors.getNoteColor(colorName).r * 0.85,
            green: AppColors.getNoteColor(colorName).g * 0.85,
            blue: AppColors.getNoteColor(colorName).b * 0.85,
          ),
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      );

  static BoxDecoration get searchBarDecoration => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      );

  static BoxDecoration get toolbarDecoration => BoxDecoration(
        color: AppColors.surfaceWarm,
        border: const Border(
          top: BorderSide(color: AppColors.divider, width: 1.5),
        ),
      );

  static BoxDecoration get aiResultDecoration => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.teal.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  static BoxDecoration get bottomBarDecoration => BoxDecoration(
        color: AppColors.surfaceWarm,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: const Border(
          top: BorderSide(color: AppColors.divider, width: 2),
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      );
}
