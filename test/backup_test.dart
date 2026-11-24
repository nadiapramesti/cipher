import 'package:cipher/core/backup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sample = BackupData(
    onboardingDone: true,
    startLevel: 1,
    xp: 260,
    streak: 4,
    lastActive: DateTime.utc(2026, 11, 24, 10),
    bestScores: const {'lv0-password': 100, 'lv0-2fa': 80},
    accent: 'sakura',
    themeMode: 'light',
    lang: 'en',
  );

  test('kode backup bisa dibaca balik utuh', () {
    final code = encodeBackup(sample);
    expect(code, startsWith('CIPHER1.'));
    final back = decodeBackup(code);
    expect(back.xp, 260);
    expect(back.streak, 4);
    expect(back.startLevel, 1);
    expect(back.bestScores, sample.bestScores);
    expect(back.lastActive, sample.lastActive);
    expect(back.accent, 'sakura');
    expect(back.lang, 'en');
  });

  test('spasi & enter dari hasil tempel diabaikan', () {
    final code = encodeBackup(sample);
    final messy = '  ${code.substring(0, 20)}\n${code.substring(20)}  ';
    expect(decodeBackup(messy).xp, 260);
  });

  test('kode yang diubah ketahuan lewat checksum', () {
    final code = encodeBackup(sample);
    final parts = code.split('.');
    final body = parts[1];
    final swap = body[10] == 'A' ? 'B' : 'A';
    final tampered = '${parts[0]}.${body.substring(0, 10)}$swap${body.substring(11)}.${parts[2]}';
    expect(() => decodeBackup(tampered), throwsA(isA<FormatException>()));
  });

  test('teks sembarang ditolak', () {
    expect(() => decodeBackup('halo apa kabar'), throwsA(isA<FormatException>()));
    expect(() => decodeBackup('CIPHER1.abc'), throwsA(isA<FormatException>()));
  });
}
