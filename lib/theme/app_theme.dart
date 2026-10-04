import 'package:flutter/material.dart';

/// The colour tokens from docs/MVP_PLAN.md. Screens use these; nothing
/// hard-codes a colour.
class AppColors {
  AppColors._();

  static const ground = Color(0xFFE8F5F2);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFC6E3DD);
  static const ink = Color(0xFF0F2E2B);
  static const muted = Color(0xFF5B7773);
  static const accent = Color(0xFF0F8F84);
  static const good = Color(0xFF0F8F84);
  static const okay = Color(0xFFE39B2B);
  static const okayText = Color(0xFFA86F12);
  static const morePractice = Color(0xFFD9365A);
  static const guideline = Color(0xFFBFDDD7);
  static const baseline = Color(0xFF86B5AD);
  static const letterGhost = Color(0xFFD9ECE8);
  static const pickedTile = Color(0xFFDDF0EE);
}

/// Shape tokens from docs/MVP_PLAN.md.
class AppShapes {
  AppShapes._();

  static const double cardRadius = 24;
  static const double buttonHeight = 58;
  static const double buttonRadius = 16;
  static const double progressBarHeight = 10;
}

const uiFontFamily = 'Manrope';

ThemeData buildAppTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.accent,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
        outline: AppColors.border,
      );
  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppShapes.buttonRadius),
  );
  const buttonSize = Size.fromHeight(AppShapes.buttonHeight);
  const buttonText = TextStyle(
    fontFamily: uiFontFamily,
    fontWeight: FontWeight.w800,
    fontSize: 17,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: uiFontFamily,
    scaffoldBackgroundColor: AppColors.ground,
    textTheme: ThemeData.light().textTheme.apply(
      fontFamily: uiFontFamily,
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.ground,
      foregroundColor: AppColors.ink,
      elevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        minimumSize: buttonSize,
        shape: buttonShape,
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accent,
        minimumSize: buttonSize,
        shape: buttonShape,
        side: const BorderSide(color: AppColors.accent, width: 2),
        textStyle: buttonText,
      ),
    ),
  );
}
