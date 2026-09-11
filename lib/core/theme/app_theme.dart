import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// -- LumaApp Design Tokens --------------------------------------------------
// Accent: Luma Lime (#B8FF22) - used ONLY on interactive focal points (buttons,
//   toggles, active seek bar, active indicator).
// Rationale: 2 core neutrals + 1 deliberate accent per DESIGN.md.
// Contrast ratio against pure black (#000000) is 15.6:1 (exceeds WCAG AAA).
// --------------------------------------------------------------------------

class LumaColors {
  LumaColors._();

  // Accent: one deliberate accent, used sparingly
  static const Color accent = Color(0xFFB8FF22); // Luma Lime

  // Dark Mode palette
  static const Color darkBg              = Color(0xFF000000);
  static const Color darkSurface        = Color(0xFF111111);
  static const Color darkDivider        = Color(0xFF2A2A2A);
  static const Color darkTextPrimary    = Color(0xFFFFFFFF);
  static const Color darkTextSecondary  = Color(0xFFB3B3B3); // WCAG AA 8.5:1 on black
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: LumaColors.darkBg,
    colorScheme: const ColorScheme.dark(
      primary: LumaColors.accent,
      secondary: LumaColors.accent,
      surface: LumaColors.darkSurface,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: LumaColors.darkTextPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: LumaColors.darkBg,
      foregroundColor: LumaColors.darkTextPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: LumaColors.darkTextPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        color: LumaColors.darkTextPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      titleMedium: TextStyle(
        color: LumaColors.darkTextPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      bodyMedium: TextStyle(
        color: LumaColors.darkTextSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      labelSmall: TextStyle(
        color: LumaColors.darkTextSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    ),
    dividerColor: LumaColors.darkDivider,
    dividerTheme: const DividerThemeData(
      color: LumaColors.darkDivider,
      thickness: 0.5,
      space: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: LumaColors.accent,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          letterSpacing: -0.2,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: LumaColors.darkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: LumaColors.accent, width: 1.5),
      ),
      hintStyle: const TextStyle(
        color: LumaColors.darkTextSecondary,
        fontSize: 15,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected) ? Colors.black : LumaColors.darkTextSecondary),
      trackColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected) ? LumaColors.accent : LumaColors.darkDivider),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: LumaColors.accent,
      inactiveTrackColor: LumaColors.darkDivider,
      thumbColor: LumaColors.accent,
      trackHeight: 3,
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
      overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: LumaColors.darkSurface,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      showCloseIcon: true,
      closeIconColor: Colors.white70,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
    ),
  );
}
