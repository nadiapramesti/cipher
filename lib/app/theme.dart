import 'package:flutter/material.dart';

/// Palet Cipher "Violet Vault": tinta ungu gelap + violet + hijau limau.
/// Violet buat aksi & identitas, limau buat status benar/aman/progres.
class C {
  static const bg = Color(0xFF0F0B19);
  static const bgDeep = Color(0xFF07050D);
  static const surface = Color(0xFF181229);
  static const surface2 = Color(0xFF211A36);
  static const line = Color(0xFF2C2245);
  static const lineStrong = Color(0xFF3A2F5C);
  static const accent = Color(0xFFB79CFF);
  static const accentSoft = Color(0xFFD4C4FF);
  static const accentDeep = Color(0xFF5E4A9E);
  static const accentTint = Color(0xFF2D2452);
  static const onAccent = Color(0xFF150C2B);
  static const ok = Color(0xFFC6F36B);
  static const okDeep = Color(0xFF4D6128);
  static const okTint = Color(0xFF1A2210);
  static const mint = Color(0xFFE4FFA8);
  static const yellow = Color(0xFFFFD166);
  static const orange = Color(0xFFFF9F43);
  static const red = Color(0xFFFF6B5B);
  static const text = Color(0xFFF1ECFF);
  static const textSoft = Color(0xFFCFC6E6);
  static const muted = Color(0xFFA89CC4);
}

const String kMono = 'JetBrainsMono';
const String kDisplay = 'SpaceGrotesk';

TextStyle mono({
  double size = 12,
  Color color = C.muted,
  FontWeight weight = FontWeight.w500,
  double spacing = 0.4,
}) =>
    TextStyle(
      fontFamily: kMono,
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: spacing,
    );

TextStyle display({
  double size = 26,
  Color color = C.text,
  FontWeight weight = FontWeight.w700,
  double height = 1.15,
}) =>
    TextStyle(
      fontFamily: kDisplay,
      fontSize: size,
      color: color,
      fontWeight: weight,
      height: height,
      letterSpacing: -0.4,
    );

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: C.bg,
    colorScheme: const ColorScheme.dark(
      primary: C.accent,
      onPrimary: C.onAccent,
      secondary: C.ok,
      onSecondary: C.onAccent,
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
        letterSpacing: 0.3,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.surface2,
      hintStyle: const TextStyle(color: Color(0xFF8E82AE)),
      labelStyle: const TextStyle(color: C.textSoft),
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
        borderSide: const BorderSide(color: C.accent, width: 1.5),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: C.surface,
      indicatorColor: C.accentTint,
      height: 70,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: s.contains(WidgetState.selected) ? C.accent : C.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected) ? C.accent : C.muted,
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
