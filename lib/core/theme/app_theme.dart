import 'package:flutter/material.dart';

abstract final class AppColors {
  static const navy = Color(0xFF0A2540);
  static const cyan = Color(0xFF00C2D1);
  static const teal = Color(0xFF0891B2);
  static const success = Color(0xFF22C55E);
  static const danger = Color(0xFFE5484D);
  static const queued = Color(0xFFF59E0B);
  static const surfaceRaised = Color(0xFF102F52);
}

ThemeData buildAppTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.cyan,
        brightness: Brightness.dark,
      ).copyWith(
        primary: AppColors.cyan,
        secondary: AppColors.teal,
        error: AppColors.danger,
        surface: AppColors.navy,
        onSurface: const Color(0xFFE8F1F8),
      );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.navy,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.navy,
      centerTitle: false,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceRaised,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceRaised,
      disabledColor: AppColors.surfaceRaised,
      side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surfaceRaised,
      modalBackgroundColor: AppColors.surfaceRaised,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48)),
    ),
  );
}
