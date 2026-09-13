import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// -- LumaApp Design Tokens --------------------------------------------------
// Accent: Luma Lime (#B8FF22) - used ONLY on interactive focal points.
// Rationale: 2 core neutrals + 1 deliberate accent per DESIGN.md.
// Contrast ratio against pure black (#000000) is 15.6:1 (exceeds WCAG AAA).
// --------------------------------------------------------------------------

class LumaColors {
  LumaColors._();

  // Accent: Monochrome primary accent
  // In the grey-white theme, Obsidian Charcoal (#18181B) serves as the high-contrast focal accent.
  static const Color accent = Color(0xFF18181B); // Obsidian Zinc-900

  // Dark Mode palette
  static const Color darkBg              = Color(0xFF000000);
  static const Color darkSurface        = Color(0xFF141414);
  static const Color darkSurfaceElevated = Color(0xFF1F1F1F);
  static const Color darkDivider        = Color(0xFF262626);
  static const Color darkTextPrimary    = Color(0xFFFFFFFF);
  static const Color darkTextSecondary  = Color(0xFFA1A1AA);

  // Light Mode palette (Grey-White Minimalist)
  static const Color lightBg              = Color(0xFFFAFAFA); // Soft pure zinc backdrop
  static const Color lightSurface        = Color(0xFFF4F4F5); // Zinc-100
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF); // Pure white elevated card
  static const Color lightDivider        = Color(0xFFE4E4E7); // Zinc-200
  static const Color lightBorder         = Color(0xFFD4D4D8); // Zinc-300
  static const Color lightTextPrimary    = Color(0xFF09090B); // Zinc-950
  static const Color lightTextSecondary  = Color(0xFF71717A); // Zinc-500
  static const Color lightTextMuted      = Color(0xFFA1A1AA); // Zinc-400
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark => _buildDarkTheme(
    bgColor: LumaColors.darkBg,
    surfaceColor: LumaColors.darkSurface,
    surfaceElevatedColor: LumaColors.darkSurfaceElevated,
    dividerColor: LumaColors.darkDivider,
  );

  static ThemeData get midnight => _buildDarkTheme(
    bgColor: const Color(0xFF0B0F17),
    surfaceColor: const Color(0xFF131924),
    surfaceElevatedColor: const Color(0xFF1A2130),
    dividerColor: const Color(0xFF242C3D),
  );

  static ThemeData _buildDarkTheme({
    required Color bgColor,
    required Color surfaceColor,
    required Color surfaceElevatedColor,
    required Color dividerColor,
  }) {
    final baseTextTheme = Typography.material2021().black;
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: bgColor,
      colorScheme: ColorScheme.dark(
        primary: Colors.white,
        secondary: const Color(0xFFE4E4E7),
        surface: surfaceColor,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: LumaColors.darkTextPrimary,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(baseTextTheme).copyWith(
        headlineMedium: GoogleFonts.plusJakartaSans(
          color: LumaColors.darkTextPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          color: LumaColors.darkTextPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          color: LumaColors.darkTextSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.2,
        ),
        labelSmall: GoogleFonts.plusJakartaSans(
          color: LumaColors.darkTextSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
        foregroundColor: LumaColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: LumaColors.darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      dividerColor: dividerColor,
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 1, // 1px subtle divider
        space: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: -0.2,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: LumaColors.darkTextSecondary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? Colors.black : LumaColors.darkTextSecondary),
        trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? Colors.white : dividerColor),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: Colors.white,
        inactiveTrackColor: dividerColor,
        thumbColor: Colors.white,
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceElevatedColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        showCloseIcon: true,
        closeIconColor: Colors.white70,
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static ThemeData get light {
    final baseTextTheme = Typography.material2021().black;
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: LumaColors.lightBg,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF18181B), // Obsidian Zinc-900
        secondary: Color(0xFF27272A), // Zinc-800
        surface: LumaColors.lightSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: LumaColors.lightTextPrimary,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(baseTextTheme).copyWith(
        headlineMedium: GoogleFonts.plusJakartaSans(
          color: LumaColors.lightTextPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          color: LumaColors.lightTextPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          color: LumaColors.lightTextSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.2,
        ),
        labelSmall: GoogleFonts.plusJakartaSans(
          color: LumaColors.lightTextSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: LumaColors.lightBg,
        foregroundColor: LumaColors.lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: LumaColors.lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      dividerColor: LumaColors.lightDivider,
      dividerTheme: const DividerThemeData(
        color: LumaColors.lightDivider,
        thickness: 1,
        space: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF18181B),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: -0.2,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LumaColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF18181B), width: 1.5),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: LumaColors.lightTextSecondary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? Colors.white : LumaColors.lightTextSecondary),
        trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? const Color(0xFF18181B) : LumaColors.lightDivider),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: Color(0xFF18181B),
        inactiveTrackColor: LumaColors.lightDivider,
        thumbColor: Color(0xFF18181B),
        trackHeight: 4,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF18181B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        showCloseIcon: true,
        closeIconColor: Colors.white70,
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
