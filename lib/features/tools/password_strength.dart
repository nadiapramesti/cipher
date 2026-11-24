import 'dart:math' as math;

enum StrengthLevel { kosong, sangatLemah, lemah, lumayan, kuat, sangatKuat }

extension StrengthLabel on StrengthLevel {
  String get label => switch (this) {
        StrengthLevel.kosong => '-',
        StrengthLevel.sangatLemah => 'Sangat lemah',
        StrengthLevel.lemah => 'Lemah',
        StrengthLevel.lumayan => 'Lumayan',
        StrengthLevel.kuat => 'Kuat',
        StrengthLevel.sangatKuat => 'Sangat kuat',
      };

  /// 0..5, dipakai buat ngisi bar meter.
  int get bars => index;
}

class CheckItem {
  const CheckItem(this.label, this.ok);
  final String label;
  final bool ok;
}

class PasswordReport {
  const PasswordReport({
    required this.level,
    required this.entropyBits,
    required this.crackTime,
    required this.checks,
    required this.tips,
  });

  const PasswordReport.empty()
      : level = StrengthLevel.kosong,
        entropyBits = 0,
        crackTime = '-',
        checks = const [],
        tips = const [];

  final StrengthLevel level;
  final double entropyBits;
  final String crackTime;
  final List<CheckItem> checks;
  final List<String> tips;
}

/// Asumsi penyerang offline: 10 miliar tebakan per detik.
const double guessesPerSecond = 1e10;

const Set<String> _common = {
  '123456', '1234567', '12345678', '123456789', '1234567890', '12345',
  '1234', '111111', '000000', '123123', '112233', '654321', '666666',
  '121212', '7777777', 'password', 'passw0rd', 'qwerty', 'qwertyuiop',
  'asdfgh', 'zxcvbnm', 'abc123', 'admin', 'letmein', 'welcome', 'iloveyou',
  'dragon', 'monkey', 'football', 'sunshine', 'princess', 'master',
  'superman', 'batman', 'starwars', 'shadow', 'freedom', 'login', 'secret',
  'bismillah', 'sayang', 'sayangku', 'indonesia', 'rahasia', 'cinta',
  'cintaku', 'doraemon', 'naruto', 'garuda', 'jakarta', 'anjing', 'kucing',
};

bool _isCommon(String lower) {
  if (_common.contains(lower)) return true;
  // "sayang123", "admin!!" -> buang angka/simbol di ujung lalu cek lagi
  final stripped = lower.replaceAll(RegExp(r'[0-9!@#$%^&*._\-]+$'), '');
  return stripped.isNotEmpty && _common.contains(stripped);
}

bool _hasSequence(String lower) {
  const seqs = [
    'abcdefghijklmnopqrstuvwxyz',
    '01234567890',
    'qwertyuiop',
    'asdfghjkl',
    'zxcvbnm',
  ];
  for (final seq in seqs) {
    for (var i = 0; i + 4 <= seq.length; i++) {
      if (lower.contains(seq.substring(i, i + 4))) return true;
    }
  }
  return false;
}

PasswordReport analyzePassword(String pw) {
  if (pw.isEmpty) return const PasswordReport.empty();

  final hasLower = RegExp(r'[a-z]').hasMatch(pw);
  final hasUpper = RegExp(r'[A-Z]').hasMatch(pw);
  final hasDigit = RegExp(r'[0-9]').hasMatch(pw);
  final hasSymbol = RegExp(r'[^A-Za-z0-9]').hasMatch(pw);

  var pool = 0;
  if (hasLower) pool += 26;
  if (hasUpper) pool += 26;
  if (hasDigit) pool += 10;
  if (hasSymbol) pool += 33;

  final lower = pw.toLowerCase();
  final common = _isCommon(lower);
  final repeat = RegExp(r'(.)\1\1').hasMatch(pw);
  final sequence = _hasSequence(lower);

  var bits = pw.length * (math.log(pool) / math.ln2);
  if (common) bits = math.min(bits, 10);
  if (repeat) bits *= 0.8;
  if (sequence) bits *= 0.8;

  var level = switch (bits) {
    < 28.0 => StrengthLevel.sangatLemah,
    < 36.0 => StrengthLevel.lemah,
    < 60.0 => StrengthLevel.lumayan,
    < 80.0 => StrengthLevel.kuat,
    _ => StrengthLevel.sangatKuat,
  };
  if (pw.length < 8 && level.index > StrengthLevel.lemah.index) {
    level = StrengthLevel.lemah;
  }

  final seconds = math.pow(2, bits) / 2 / guessesPerSecond;

  final checks = [
    CheckItem('Minimal 12 karakter', pw.length >= 12),
    CheckItem('Ada huruf kecil', hasLower),
    CheckItem('Ada huruf besar', hasUpper),
    CheckItem('Ada angka', hasDigit),
    CheckItem('Ada simbol atau spasi', hasSymbol),
    CheckItem('Bukan password pasaran', !common),
    CheckItem('Gak ada pola berulang / urutan', !repeat && !sequence),
  ];

  final tips = <String>[
    if (common)
      'Ini termasuk password pasaran. Penyerang biasanya nyoba daftar kayak gini duluan.',
    if (pw.length < 12)
      'Panjangin. Gabungan 4 kata acak (contoh: kucing-oren-makan-tahu) lebih kuat dan gampang diinget.',
    if (repeat || sequence)
      'Hindari pola kayak "aaa", "1234", atau "qwerty", karena gampang ditebak.',
    if (!hasSymbol && pw.length < 16)
      'Tambahin simbol atau pemisah kayak "-" di antara kata.',
    if (level.index >= StrengthLevel.kuat.index)
      'Udah mantap. Pastiin password ini cuma dipakai di satu akun aja ya.',
  ];

  return PasswordReport(
    level: level,
    entropyBits: bits,
    crackTime: formatDuration(seconds.toDouble()),
    checks: checks,
    tips: tips,
  );
}

String formatDuration(double seconds) {
  if (seconds.isNaN) return '-';
  if (seconds < 1) return 'kurang dari 1 detik';
  if (seconds < 60) return '${seconds.round()} detik';
  final minutes = seconds / 60;
  if (minutes < 60) return '${minutes.round()} menit';
  final hours = minutes / 60;
  if (hours < 24) return '${hours.round()} jam';
  final days = hours / 24;
  if (days < 30) return '${days.round()} hari';
  if (days < 365) return '${(days / 30).round()} bulan';
  final years = days / 365;
  if (years < 1000) return '${years.round()} tahun';
  if (years < 1e6) return '${(years / 1000).round()} ribu tahun';
  if (years < 1e9) return '${(years / 1e6).round()} juta tahun';
  return 'miliaran tahun lebih';
}
