import 'package:cipher/features/tools/password_strength.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('analyzePassword', () {
    test('kosong balikin laporan kosong', () {
      final r = analyzePassword('');
      expect(r.level, StrengthLevel.kosong);
      expect(r.checks, isEmpty);
    });

    test('password pasaran dianggap sangat lemah', () {
      expect(analyzePassword('123456').level, StrengthLevel.sangatLemah);
      expect(analyzePassword('password').level, StrengthLevel.sangatLemah);
    });

    test('pasaran + angka di ujung tetap ketahuan', () {
      final r = analyzePassword('Sayang123');
      expect(r.level, StrengthLevel.sangatLemah);
      expect(r.checks.firstWhere((c) => c.label.contains('pasaran')).ok, isFalse);
    });

    test('karakter berulang kena penalti', () {
      final r = analyzePassword('aaaaaaaa');
      expect(r.level.index, lessThanOrEqualTo(StrengthLevel.lemah.index));
    });

    test('password pendek gak bisa lebih dari lemah', () {
      expect(
        analyzePassword('Xy!9').level.index,
        lessThanOrEqualTo(StrengthLevel.lemah.index),
      );
    });

    test('passphrase panjang dianggap sangat kuat', () {
      final r = analyzePassword('kucing-oren-makan-tahu-27');
      expect(r.level, StrengthLevel.sangatKuat);
      expect(r.checks.where((c) => !c.ok).map((c) => c.label),
          contains('Ada huruf besar'));
    });
  });

  group('formatDuration', () {
    test('satuan waktu', () {
      expect(formatDuration(0.5), 'kurang dari 1 detik');
      expect(formatDuration(30), '30 detik');
      expect(formatDuration(3600), '1 jam');
      expect(formatDuration(86400 * 3), '3 hari');
    });

    test('angka raksasa gak bikin crash', () {
      expect(formatDuration(double.infinity), 'miliaran tahun lebih');
    });
  });
}
