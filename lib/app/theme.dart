import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Pilihan warna aksen Cipher. Tiap aksen punya versi gelap & terang.
enum ThemeAccent { violet, amber, neon, sakura }

/// Mode tampilan: gelap, terang, atau ikut setelan HP.
enum AppThemeMode { dark, light, system }

/// Satu set warna lengkap. Semua layar baca warna lewat [C],
/// jadi ganti palet = seluruh app ikut berubah.
class Palette {
  const Palette({
    required this.brightness,
    required this.bg,
    required this.bgDeep,
    required this.surface,
    required this.surface2,
    required this.line,
    required this.lineStrong,
    required this.accent,
    required this.accentSoft,
    required this.accentDeep,
    required this.accentTint,
    required this.onAccent,
    required this.ok,
    required this.okDeep,
    required this.okTint,
    required this.mint,
    required this.text,
    required this.textSoft,
    required this.muted,
    required this.hint,
    required this.yellow,
    required this.orange,
    required this.red,
  });

  final Brightness brightness;
  final Color bg, bgDeep, surface, surface2, line, lineStrong;
  final Color accent, accentSoft, accentDeep, accentTint, onAccent;
  final Color ok, okDeep, okTint, mint;
  final Color text, textSoft, muted, hint;
  final Color yellow, orange, red;

  bool get isDark => brightness == Brightness.dark;
}

const _violetDark = Palette(
  brightness: Brightness.dark,
  bg: Color(0xFF0F0B19), bgDeep: Color(0xFF07050D), surface: Color(0xFF181229),
  surface2: Color(0xFF211A36), line: Color(0xFF2C2245), lineStrong: Color(0xFF3A2F5C),
  accent: Color(0xFFB79CFF), accentSoft: Color(0xFFD4C4FF), accentDeep: Color(0xFF5E4A9E),
  accentTint: Color(0xFF2D2452), onAccent: Color(0xFF150C2B),
  ok: Color(0xFFC6F36B), okDeep: Color(0xFF4D6128), okTint: Color(0xFF1A2210), mint: Color(0xFFE4FFA8),
  text: Color(0xFFF1ECFF), textSoft: Color(0xFFCFC6E6), muted: Color(0xFFA89CC4), hint: Color(0xFF8E82AE),
  yellow: Color(0xFFFFD166), orange: Color(0xFFFF9F43), red: Color(0xFFFF6B5B),
);

const _violetLight = Palette(
  brightness: Brightness.light,
  bg: Color(0xFFF5F2FC), bgDeep: Color(0xFFD9D0EE), surface: Color(0xFFFFFFFF),
  surface2: Color(0xFFEEE9F9), line: Color(0xFFDCD3F0), lineStrong: Color(0xFFC4B7E6),
  accent: Color(0xFF6A4FD6), accentSoft: Color(0xFF9A85EA), accentDeep: Color(0xFF3F2B99),
  accentTint: Color(0xFFE6DEFF), onAccent: Color(0xFFFFFFFF),
  ok: Color(0xFF3E7A10), okDeep: Color(0xFF2A560A), okTint: Color(0xFFEAF6D6), mint: Color(0xFF8CC94A),
  text: Color(0xFF1B1530), textSoft: Color(0xFF3D3460), muted: Color(0xFF625880), hint: Color(0xFF8C83A6),
  yellow: Color(0xFF9A6B00), orange: Color(0xFFB85400), red: Color(0xFFC0352A),
);

const _amberDark = Palette(
  brightness: Brightness.dark,
  bg: Color(0xFF0E0D0B), bgDeep: Color(0xFF070605), surface: Color(0xFF17150F),
  surface2: Color(0xFF1F1C14), line: Color(0xFF2E2A1E), lineStrong: Color(0xFF3A3526),
  accent: Color(0xFFF5B83D), accentSoft: Color(0xFFFFD27A), accentDeep: Color(0xFF8C6C2A),
  accentTint: Color(0xFF3A2F15), onAccent: Color(0xFF1A1405),
  ok: Color(0xFF7FD1C7), okDeep: Color(0xFF2F5752), okTint: Color(0xFF10201D), mint: Color(0xFFB8F0E8),
  text: Color(0xFFF3EEE2), textSoft: Color(0xFFCFC7B4), muted: Color(0xFFA9A18E), hint: Color(0xFF8A8371),
  yellow: Color(0xFFFFE08A), orange: Color(0xFFFF9F43), red: Color(0xFFFF6B5B),
);

const _amberLight = Palette(
  brightness: Brightness.light,
  bg: Color(0xFFFBF7EE), bgDeep: Color(0xFFE4D8BD), surface: Color(0xFFFFFFFF),
  surface2: Color(0xFFF5EEDF), line: Color(0xFFE6DCC6), lineStrong: Color(0xFFD3C5A6),
  accent: Color(0xFF9C6200), accentSoft: Color(0xFFD49A2A), accentDeep: Color(0xFF6A4200),
  accentTint: Color(0xFFF8E7C2), onAccent: Color(0xFFFFFFFF),
  ok: Color(0xFF0F7A6D), okDeep: Color(0xFF0A574E), okTint: Color(0xFFDDF3EF), mint: Color(0xFF5CC2B4),
  text: Color(0xFF1F1A12), textSoft: Color(0xFF4A4031), muted: Color(0xFF6E6450), hint: Color(0xFF978C76),
  yellow: Color(0xFF8F6A00), orange: Color(0xFFB85400), red: Color(0xFFC0352A),
);

const _neonDark = Palette(
  brightness: Brightness.dark,
  bg: Color(0xFF080D1C), bgDeep: Color(0xFF040712), surface: Color(0xFF0F1730),
  surface2: Color(0xFF16203D), line: Color(0xFF1E2A4D), lineStrong: Color(0xFF2A3A66),
  accent: Color(0xFF4FD6FF), accentSoft: Color(0xFF9BE8FF), accentDeep: Color(0xFF1D6F8C),
  accentTint: Color(0xFF123A52), onAccent: Color(0xFF04121A),
  ok: Color(0xFF7CF5B0), okDeep: Color(0xFF256B4A), okTint: Color(0xFF0C2419), mint: Color(0xFFC2FFE0),
  text: Color(0xFFEAF1FF), textSoft: Color(0xFFC3CEEA), muted: Color(0xFF94A3C7), hint: Color(0xFF7584AA),
  yellow: Color(0xFFFFD166), orange: Color(0xFFFF9F43), red: Color(0xFFFF6B7F),
);

const _neonLight = Palette(
  brightness: Brightness.light,
  bg: Color(0xFFF1F6FF), bgDeep: Color(0xFFCFDCF2), surface: Color(0xFFFFFFFF),
  surface2: Color(0xFFE8F0FD), line: Color(0xFFD3DFF3), lineStrong: Color(0xFFB4C6E6),
  accent: Color(0xFF0A6A9C), accentSoft: Color(0xFF3A9BCF), accentDeep: Color(0xFF064A6E),
  accentTint: Color(0xFFD6EEFB), onAccent: Color(0xFFFFFFFF),
  ok: Color(0xFF0E7444), okDeep: Color(0xFF0A5432), okTint: Color(0xFFDCF5E8), mint: Color(0xFF4CC98A),
  text: Color(0xFF0E1630), textSoft: Color(0xFF33405F), muted: Color(0xFF56637F), hint: Color(0xFF8290AA),
  yellow: Color(0xFF9A6B00), orange: Color(0xFFB85400), red: Color(0xFFC0352A),
);

const _sakuraDark = Palette(
  brightness: Brightness.dark,
  bg: Color(0xFF140D14), bgDeep: Color(0xFF0B070B), surface: Color(0xFF1E141E),
  surface2: Color(0xFF281B28), line: Color(0xFF3A2838), lineStrong: Color(0xFF4E3550),
  accent: Color(0xFFFF8FC7), accentSoft: Color(0xFFFFC2E1), accentDeep: Color(0xFF9C4A78),
  accentTint: Color(0xFF46213A), onAccent: Color(0xFF2A0A1C),
  ok: Color(0xFFC6F36B), okDeep: Color(0xFF4D6128), okTint: Color(0xFF1A2210), mint: Color(0xFFE4FFA8),
  text: Color(0xFFFFEEF7), textSoft: Color(0xFFE8CFDD), muted: Color(0xFFC0A3B5), hint: Color(0xFF9B7F90),
  yellow: Color(0xFFFFD166), orange: Color(0xFFFF9F43), red: Color(0xFFFF6B5B),
);

const _sakuraLight = Palette(
  brightness: Brightness.light,
  bg: Color(0xFFFFF4F9), bgDeep: Color(0xFFEBCFDC), surface: Color(0xFFFFFFFF),
  surface2: Color(0xFFFBEAF2), line: Color(0xFFF0D5E2), lineStrong: Color(0xFFE2B8CC),
  accent: Color(0xFFAD2D6A), accentSoft: Color(0xFFD9649D), accentDeep: Color(0xFF7A1C4A),
  accentTint: Color(0xFFFADCEA), onAccent: Color(0xFFFFFFFF),
  ok: Color(0xFF3E7A10), okDeep: Color(0xFF2A560A), okTint: Color(0xFFEAF6D6), mint: Color(0xFF8CC94A),
  text: Color(0xFF2A1020), textSoft: Color(0xFF553447), muted: Color(0xFF7A5A6C), hint: Color(0xFFA08596),
  yellow: Color(0xFF9A6B00), orange: Color(0xFFB85400), red: Color(0xFFC0352A),
);

Palette paletteFor(ThemeAccent accent, {required bool dark}) => switch (accent) {
      ThemeAccent.violet => dark ? _violetDark : _violetLight,
      ThemeAccent.amber => dark ? _amberDark : _amberLight,
      ThemeAccent.neon => dark ? _neonDark : _neonLight,
      ThemeAccent.sakura => dark ? _sakuraDark : _sakuraLight,
    };

/// Pintu warna aktif. Isinya diganti lewat [C.use] tiap tema berubah.
class C {
  static Palette _p = _violetDark;
  static Palette get palette => _p;
  static void use(Palette p) => _p = p;

  static Color get bg => _p.bg;
  static Color get bgDeep => _p.bgDeep;
  static Color get surface => _p.surface;
  static Color get surface2 => _p.surface2;
  static Color get line => _p.line;
  static Color get lineStrong => _p.lineStrong;
  static Color get accent => _p.accent;
  static Color get accentSoft => _p.accentSoft;
  static Color get accentDeep => _p.accentDeep;
  static Color get accentTint => _p.accentTint;
  static Color get onAccent => _p.onAccent;
  static Color get ok => _p.ok;
  static Color get okDeep => _p.okDeep;
  static Color get okTint => _p.okTint;
  static Color get mint => _p.mint;
  static Color get yellow => _p.yellow;
  static Color get orange => _p.orange;
  static Color get red => _p.red;
  static Color get text => _p.text;
  static Color get textSoft => _p.textSoft;
  static Color get muted => _p.muted;
  static Color get hint => _p.hint;
  static bool get isDark => _p.isDark;
}

/// Tipografi Cipher:
/// - Chakra Petch: judul, bersudut tajam ala panel kokpit
/// - Plus Jakarta Sans: isi materi, enak dibaca lama (font identitas kota Jakarta)
/// - Martian Mono: label terminal, kode, angka XP (variable font, bobot lewat wght)
const String kMono = 'MartianMono';
const String kDisplay = 'ChakraPetch';
const String kBody = 'PlusJakartaSans';

List<FontVariation> wght(FontWeight w) => [FontVariation('wght', w.value.toDouble())];

TextStyle mono({
  double size = 12,
  Color? color,
  FontWeight weight = FontWeight.w500,
  double spacing = 0.4,
}) =>
    TextStyle(
      fontFamily: kMono,
      fontSize: size,
      color: color ?? C.muted,
      fontWeight: weight,
      fontVariations: wght(weight),
      letterSpacing: spacing,
    );

TextStyle display({
  double size = 26,
  Color? color,
  FontWeight weight = FontWeight.w700,
  double height = 1.15,
}) =>
    TextStyle(
      fontFamily: kDisplay,
      fontSize: size,
      color: color ?? C.text,
      fontWeight: weight,
      height: height,
      letterSpacing: -0.2,
    );

ThemeData buildTheme(Palette p) {
  final dark = p.isDark;
  final scheme = (dark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
    primary: p.accent,
    onPrimary: p.onAccent,
    secondary: p.ok,
    onSecondary: p.onAccent,
    surface: p.surface,
    onSurface: p.text,
    error: p.red,
  );
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: kBody,
    brightness: p.brightness,
    scaffoldBackgroundColor: p.bg,
    colorScheme: scheme,
  );

  final radius = BorderRadius.circular(14);

  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: p.text, displayColor: p.text),
    dividerColor: p.line,
    appBarTheme: AppBarTheme(
      backgroundColor: p.bg,
      foregroundColor: p.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      titleTextStyle: TextStyle(
        fontFamily: kMono,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        fontVariations: const [FontVariation('wght', 700)],
        color: p.text,
        letterSpacing: 0.3,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surface2,
      hintStyle: TextStyle(color: p.hint),
      labelStyle: TextStyle(color: p.textSoft),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: p.line)),
      enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: p.line)),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: p.accent, width: 1.5),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.surface,
      indicatorColor: p.accentTint,
      height: 70,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: s.contains(WidgetState.selected) ? p.accent : p.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? p.accent : p.muted),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.surface2,
      contentTextStyle: TextStyle(color: p.text),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: radius),
    ),
  );
}
