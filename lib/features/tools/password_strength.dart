import 'dart:math' as math;

import '../../l10n/strings.dart';

enum StrengthLevel { kosong, sangatLemah, lemah, lumayan, kuat, sangatKuat }

extension StrengthLabel on StrengthLevel {
  String get label => switch (this) {
        StrengthLevel.kosong => '-',
        StrengthLevel.sangatLemah => tr('st_very_weak'),
        StrengthLevel.lemah => tr('st_weak'),
        StrengthLevel.lumayan => tr('st_fair'),
        StrengthLevel.kuat => tr('st_strong'),
        StrengthLevel.sangatKuat => tr('st_very_strong'),
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
    CheckItem(tr('ck_len'), pw.length >= 12),
    CheckItem(tr('ck_lower'), hasLower),
    CheckItem(tr('ck_upper'), hasUpper),
    CheckItem(tr('ck_digit'), hasDigit),
    CheckItem(tr('ck_symbol'), hasSymbol),
    CheckItem(tr('ck_common'), !common),
    CheckItem(tr('ck_pattern'), !repeat && !sequence),
  ];

  final tips = <String>[
    if (common) tr('tip_common'),
    if (pw.length < 12) tr('tip_len'),
    if (repeat || sequence) tr('tip_pattern'),
    if (!hasSymbol && pw.length < 16) tr('tip_symbol'),
    if (level.index >= StrengthLevel.kuat.index) tr('tip_good'),
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
  String n(num v) => '${v.round()}';
  if (seconds < 1) return tr('dur_lt1');
  if (seconds < 60) return tr('dur_sec', {'n': n(seconds)});
  final minutes = seconds / 60;
  if (minutes < 60) return tr('dur_min', {'n': n(minutes)});
  final hours = minutes / 60;
  if (hours < 24) return tr('dur_hour', {'n': n(hours)});
  final days = hours / 24;
  if (days < 30) return tr('dur_day', {'n': n(days)});
  if (days < 365) return tr('dur_month', {'n': n(days / 30)});
  final years = days / 365;
  if (years < 1000) return tr('dur_year', {'n': n(years)});
  if (years < 1e6) return tr('dur_ky', {'n': n(years / 1000)});
  if (years < 1e9) return tr('dur_my', {'n': n(years / 1e6)});
  return tr('dur_inf');
}
