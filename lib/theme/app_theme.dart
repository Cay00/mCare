import 'package:flutter/material.dart';

abstract final class CareColors {
  static const canvas = Color(0xFFF4F7F4);
  static const ink = Color(0xFF172F2A);
  static const muted = Color(0xFF496059);
  static const primary = Color(0xFF0A6257);
  static const soft = Color(0xFFE4F1EB);
  static const line = Color(0xFFD3E0D9);
  static const warning = Color(0xFF82430D);
  static const warningSurface = Color(0xFFFFF2DE);
}

/// Shared visual tokens. Text scaling is deliberately left to the OS.
ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: CareColors.primary,
    primary: CareColors.primary,
    onPrimary: Colors.white,
    primaryContainer: CareColors.soft,
    onPrimaryContainer: const Color(0xFF164D40),
    surface: Colors.white,
    onSurface: CareColors.ink,
    onSurfaceVariant: CareColors.muted,
    outline: const Color(0xFF718B80),
    outlineVariant: CareColors.line,
    surfaceContainerHighest: const Color(0xFFEBF0EC),
    error: const Color(0xFFAC2929),
    errorContainer: const Color(0xFFFFEDE9),
    onErrorContainer: const Color(0xFF791E1E),
  );
  final text = const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1.15,
      letterSpacing: -0.8,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: -0.5,
    ),
    titleLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      height: 1.25,
      letterSpacing: -0.3,
    ),
    titleMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      height: 1.3,
    ),
    titleSmall: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      height: 1.3,
    ),
    bodyLarge: TextStyle(fontSize: 18, height: 1.45),
    bodyMedium: TextStyle(fontSize: 18, height: 1.4),
    bodySmall: TextStyle(fontSize: 15, height: 1.4),
    labelLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
    labelMedium: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
    labelSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
  ).apply(fontFamily: 'Roboto');
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(18));
  final button = ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(Size(64, 58)),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
    shape: WidgetStatePropertyAll(shape),
    textStyle: WidgetStatePropertyAll(text.labelLarge),
    tapTargetSize: MaterialTapTargetSize.padded,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: CareColors.canvas,
    textTheme: text.apply(
      bodyColor: CareColors.ink,
      displayColor: CareColors.ink,
    ),
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    appBarTheme: AppBarTheme(
      backgroundColor: CareColors.canvas,
      foregroundColor: CareColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 20,
      toolbarHeight: 76,
      titleTextStyle: text.titleLarge?.copyWith(color: CareColors.ink),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: CareColors.line),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(style: button),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: button.copyWith(
        backgroundColor: const WidgetStatePropertyAll(CareColors.primary),
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
        elevation: const WidgetStatePropertyAll(0),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: button.copyWith(
        side: const WidgetStatePropertyAll(
          BorderSide(color: CareColors.primary),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: button),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(52, 52),
        foregroundColor: CareColors.primary,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF718B80)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: CareColors.primary, width: 2),
      ),
      errorMaxLines: 6,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: CareColors.canvas,
      constraints: BoxConstraints(maxWidth: 720),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dialogTheme: DialogThemeData(backgroundColor: Colors.white, shape: shape),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: CareColors.ink,
      contentTextStyle: text.bodyLarge?.copyWith(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dividerTheme: const DividerThemeData(color: CareColors.line, space: 32),
    navigationBarTheme: NavigationBarThemeData(
      height: 88,
      backgroundColor: Colors.white,
      indicatorColor: CareColors.soft,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 14,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? CareColors.primary
              : CareColors.muted,
        ),
      ),
    ),
  );
}
