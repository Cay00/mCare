import 'package:flutter/material.dart';

abstract final class CareColors {
  static const canvas = Color(0xFFF7F8F7);
  static const ink = Color(0xFF1A1D1C);
  static const muted = Color(0xFF6B756F);
  static const primary = Color(0xFF1AA35A);
  static const soft = Color(0xFFE7F6EE);
  static const line = Color(0xFFE4E8E5);
  static const warning = Color(0xFFB45309);
  static const warningSurface = Color(0xFFFFF4E5);
  static const headerMint = Color(0xFFD7F5E4);
}

/// Shared visual tokens. Text scaling is deliberately left to the OS.
ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: CareColors.primary,
    primary: CareColors.primary,
    onPrimary: Colors.white,
    primaryContainer: CareColors.soft,
    onPrimaryContainer: const Color(0xFF0E6B38),
    surface: Colors.white,
    onSurface: CareColors.ink,
    onSurfaceVariant: CareColors.muted,
    outline: const Color(0xFF8AA099),
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
      height: 1.12,
      letterSpacing: -0.6,
    ),
    headlineMedium: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      height: 1.15,
      letterSpacing: -0.4,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: -0.2,
    ),
    titleMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.25,
    ),
    titleSmall: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      height: 1.45,
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: TextStyle(
      fontSize: 15,
      height: 1.4,
      fontWeight: FontWeight.w400,
    ),
    bodySmall: TextStyle(
      fontSize: 14,
      height: 1.4,
      fontWeight: FontWeight.w400,
    ),
    labelLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.2,
    ),
    labelMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.3,
      letterSpacing: 0.2,
    ),
    labelSmall: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: 0.2,
    ),
  ).apply(fontFamily: 'Roboto');
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
  final button = ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(Size(64, 52)),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
      toolbarHeight: 64,
      surfaceTintColor: Colors.white,
      titleTextStyle: text.titleLarge?.copyWith(color: CareColors.ink),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
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
    listTileTheme: ListTileThemeData(
      titleTextStyle: text.titleSmall?.copyWith(color: CareColors.ink),
      subtitleTextStyle: text.bodyMedium?.copyWith(color: CareColors.muted),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: text.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: CareColors.muted,
      ),
      floatingLabelStyle: text.labelMedium?.copyWith(color: CareColors.primary),
      hintStyle: text.bodyMedium?.copyWith(color: CareColors.muted),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD5DDD8)),
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
      height: 72,
      backgroundColor: Colors.white,
      elevation: 0,
      indicatorColor: CareColors.soft,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 24,
          color: states.contains(WidgetState.selected)
              ? CareColors.primary
              : CareColors.muted,
        ),
      ),
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
