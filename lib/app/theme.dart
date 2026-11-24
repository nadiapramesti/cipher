import 'package:flutter/material.dart';

/// Palet Cipher: hitam tinta hangat + amber sinyal + teal buat status aman.
/// Sengaja gak pakai "hijau hacker" biar gak klise dan tetap ramah orang awam.
class C {
  static const bg = Color(0xFF0E0D0B);
  static const surface = Color(0xFF17150F);
  static const surface2 = Color(0xFF1F1C14);
  static const line = Color(0xFF2E2A1E);
  static const amber = Color(0xFFF5B83D);
  static const onAmber = Color(0xFF1A1405);
  static const teal = Color(0xFF7FD1C7);
  static const mint = Color(0xFF9BE58B);
  static const orange = Color(0xFFFF9F43);
  static const red = Color(0xFFFF6B5B);
  static const text = Color(0xFFF3EEE2);
  static const muted = Color(0xFF9C9482);
}

const String kMono = 'monospace';

TextStyle mono({
  double size = 12,
  Color color = C.muted,
  FontWeight weight = FontWeight.w600,
  double spacing = 0.6,
}) =>
    TextStyle(
      fontFamily: kMono,
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: spacing,
    );

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: C.bg,
    colorScheme: const ColorScheme.dark(
      primary: C.amber,
      onPrimary: C.onAmber,
      secondary: C.teal,
      onSecondary: C.onAmber,
      surface: C.surface,
      onSurface: C.text,
      error: C.red,
    ),
  );

  final radius = BorderRadius.circular(14);

  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: C.text, displayColor: C.text),
    dividerColor: C.line,
    appBarTheme: const AppBarTheme(
      backgroundColor: C.bg,
      foregroundColor: C.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: kMono,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: C.text,
        letterSpacing: 0.4,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: C.amber,
        foregroundColor: C.onAmber,
        disabledBackgroundColor: C.line,
        disabledForegroundColor: C.muted,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 16,
          letterSpacing: 0.2,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: C.amber,
        backgroundColor: C.surface,
        minimumSize: const Size.fromHeight(54),
        side: BorderSide(color: C.amber.withValues(alpha: 0.55), width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.surface2,
      hintStyle: TextStyle(color: C.muted.withValues(alpha: 0.75)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: C.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: C.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: C.amber, width: 1.5),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: C.surface,
      indicatorColor: C.amber.withValues(alpha: 0.18),
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: s.contains(WidgetState.selected) ? C.amber : C.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected) ? C.amber : C.muted,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: C.surface2,
      contentTextStyle: const TextStyle(color: C.text),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: radius),
    ),
  );
}
