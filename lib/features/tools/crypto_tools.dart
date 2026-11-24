import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Logika murni buat alat Hash & Encode dan Cipher Klasik (tanpa Flutter, gampang dites).

String _shiftChar(int code, int shift) {
  if (code >= 65 && code <= 90) return String.fromCharCode((code - 65 + shift) % 26 + 65);
  if (code >= 97 && code <= 122) return String.fromCharCode((code - 97 + shift) % 26 + 97);
  return String.fromCharCode(code);
}

int _norm(int shift) => ((shift % 26) + 26) % 26;

/// Geser tiap huruf A-Z/a-z sejauh [shift]; selain huruf dibiarkan.
String caesar(String text, int shift, {bool decrypt = false}) {
  final s = _norm(decrypt ? -shift : shift);
  final b = StringBuffer();
  for (final c in text.runes) {
    b.write(_shiftChar(c, s));
  }
  return b.toString();
}

/// Vigenère: kunci cuma huruf. Karakter non-huruf gak memajukan posisi kunci.
String vigenere(String text, String key, {bool decrypt = false}) {
  final shifts = key.toUpperCase().runes.where((c) => c >= 65 && c <= 90).map((c) => c - 65).toList();
  if (shifts.isEmpty) return text;
  final b = StringBuffer();
  var i = 0;
  for (final c in text.runes) {
    final isLetter = (c >= 65 && c <= 90) || (c >= 97 && c <= 122);
    if (!isLetter) {
      b.writeCharCode(c);
      continue;
    }
    final k = shifts[i % shifts.length];
    b.write(_shiftChar(c, _norm(decrypt ? -k : k)));
    i++;
  }
  return b.toString();
}

/// Semua 25 kemungkinan geseran Caesar (buat demo brute force).
List<(int, String)> caesarBruteForce(String text) =>
    [for (var s = 1; s < 26; s++) (s, caesar(text, s, decrypt: true))];

/// Frekuensi huruf A-Z (persen), diurutkan dari yang paling sering.
List<(String, double)> letterFrequency(String text, {int top = 6}) {
  final counts = <int, int>{};
  var total = 0;
  for (final c in text.toUpperCase().runes) {
    if (c >= 65 && c <= 90) {
      counts[c] = (counts[c] ?? 0) + 1;
      total++;
    }
  }
  if (total == 0) return const [];
  final list = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  return [for (final e in list.take(top)) (String.fromCharCode(e.key), e.value * 100 / total)];
}

String sha256Hex(String text) => sha256.convert(utf8.encode(text)).toString();
String sha1Hex(String text) => sha1.convert(utf8.encode(text)).toString();
String md5Hex(String text) => md5.convert(utf8.encode(text)).toString();
String toBase64(String text) => base64.encode(utf8.encode(text));
String toHex(String text) => utf8.encode(text).map((b) => b.toRadixString(16).padLeft(2, '0')).join();

/// null kalau input bukan Base64 / UTF-8 yang valid.
String? fromBase64(String text) {
  try {
    var t = text.trim().replaceAll(RegExp(r'\s'), '').replaceAll('-', '+').replaceAll('_', '/');
    if (t.isEmpty) return null;
    t = t.padRight((t.length + 3) ~/ 4 * 4, '=');
    return utf8.decode(base64.decode(t));
  } catch (_) {
    return null;
  }
}

/// null kalau input bukan hex genap / UTF-8 yang valid.
String? fromHex(String text) {
  final t = text.trim().replaceAll(RegExp(r'[\s:]'), '').toLowerCase();
  if (t.isEmpty || t.length.isOdd || !RegExp(r'^[0-9a-f]+$').hasMatch(t)) return null;
  try {
    return utf8.decode([for (var i = 0; i < t.length; i += 2) int.parse(t.substring(i, i + 2), radix: 16)]);
  } catch (_) {
    return null;
  }
}
