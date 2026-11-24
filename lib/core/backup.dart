import 'dart:convert';

/// Kode backup progres Cipher: `CIPHER1.<data base64url>.<checksum>`.
/// Gak berisi data pribadi, cuma progres belajar + setelan tampilan.
class BackupData {
  const BackupData({
    required this.onboardingDone,
    required this.startLevel,
    required this.xp,
    required this.streak,
    required this.lastActive,
    required this.bestScores,
    this.accent,
    this.themeMode,
    this.lang,
    this.extra,
  });

  final bool onboardingDone;
  final int startLevel;
  final int xp;
  final int streak;
  final DateTime? lastActive;
  final Map<String, int> bestScores;
  final String? accent;
  final String? themeMode;
  final String? lang;

  /// Statistik, flag CTF, antrean ulasan (opsional).
  final Map<String, dynamic>? extra;

  Map<String, Object?> toJson() => {
        'v': 1,
        'onb': onboardingDone,
        'start': startLevel,
        'xp': xp,
        'streak': streak,
        'last': lastActive?.toIso8601String(),
        'scores': bestScores,
        'accent': accent,
        'mode': themeMode,
        'lang': lang,
        if (extra != null) 'x': extra,
      };

  factory BackupData.fromJson(Map<String, dynamic> j) {
    final scores = (j['scores'] as Map? ?? const {}).map(
      (k, v) => MapEntry(k as String, (v as num).toInt().clamp(0, 100)),
    );
    final last = j['last'] as String?;
    return BackupData(
      onboardingDone: j['onb'] as bool? ?? true,
      startLevel: ((j['start'] as num?) ?? 0).toInt().clamp(0, 99),
      xp: ((j['xp'] as num?) ?? 0).toInt().clamp(0, 1 << 30),
      streak: ((j['streak'] as num?) ?? 0).toInt().clamp(0, 100000),
      lastActive: last == null ? null : DateTime.tryParse(last),
      bestScores: scores,
      accent: j['accent'] as String?,
      themeMode: j['mode'] as String?,
      lang: j['lang'] as String?,
      extra: j['x'] is Map ? Map<String, dynamic>.from(j['x'] as Map) : null,
    );
  }
}

const _prefix = 'CIPHER1';

/// FNV-1a 32-bit: cukup buat ngecek kode gak salah ketik / kepotong.
String fnv32(String s) => _checksum(s);

String _checksum(String s) {
  var h = 0x811c9dc5;
  for (final b in utf8.encode(s)) {
    h ^= b;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h.toRadixString(16).padLeft(8, '0');
}

String encodeBackup(BackupData data) {
  final body = base64Url.encode(utf8.encode(jsonEncode(data.toJson()))).replaceAll('=', '');
  return '$_prefix.$body.${_checksum(body)}';
}

/// Lempar [FormatException] kalau kodenya rusak, kepotong, atau bukan kode Cipher.
BackupData decodeBackup(String code) {
  final clean = code.replaceAll(RegExp(r'\s'), '');
  final parts = clean.split('.');
  if (parts.length != 3 || parts[0] != _prefix) {
    throw const FormatException('not-cipher');
  }
  final body = parts[1];
  if (_checksum(body) != parts[2].toLowerCase()) {
    throw const FormatException('checksum');
  }
  try {
    final padded = body.padRight((body.length + 3) ~/ 4 * 4, '=');
    final json = jsonDecode(utf8.decode(base64Url.decode(padded))) as Map<String, dynamic>;
    if (json['v'] != 1) throw const FormatException('version');
    return BackupData.fromJson(json);
  } on FormatException {
    rethrow;
  } catch (_) {
    throw const FormatException('corrupt');
  }
}
