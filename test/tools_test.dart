import 'package:cipher/features/tools/crypto_tools.dart';
import 'package:cipher/features/tools/url_inspect.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cipher klasik', () {
    test('caesar bolak-balik', () {
      expect(caesar('Halo, Dunia!', 3), 'Kdor, Gxqld!');
      expect(caesar('Kdor, Gxqld!', 3, decrypt: true), 'Halo, Dunia!');
      expect(caesar('XYZ', 3), 'ABC');
    });
    test('vigenere contoh klasik', () {
      expect(vigenere('ATTACKATDAWN', 'LEMON'), 'LXFOPVEFRNHR');
      expect(vigenere('LXFOPVEFRNHR', 'LEMON', decrypt: true), 'ATTACKATDAWN');
      expect(vigenere('attack at dawn', 'lemon'), 'lxfopv ef rnhr');
      expect(vigenere('abc', ''), 'abc');
    });
    test('brute force memuat geseran yang benar', () {
      final all = caesarBruteForce(caesar('rahasia', 7));
      expect(all.length, 25);
      expect(all.firstWhere((e) => e.$1 == 7).$2, 'rahasia');
    });
    test('frekuensi huruf', () {
      final f = letterFrequency('aaab');
      expect(f.first.$1, 'A');
      expect(f.first.$2, closeTo(75, 0.01));
    });
  });

  group('hash & encode', () {
    test('vektor uji standar', () {
      expect(sha256Hex('abc'), 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
      expect(md5Hex('abc'), '900150983cd24fb0d6963f7d28e17f72');
      expect(sha1Hex('abc'), 'a9993e364706816aba3e25717850c26c9cd0d89d');
    });
    test('base64 & hex bolak-balik', () {
      expect(toBase64('CIPHER'), 'Q0lQSEVS');
      expect(fromBase64('Q0lQSEVS'), 'CIPHER');
      expect(fromBase64('Q0lQSEVS '), 'CIPHER');
      expect(toHex('Hi'), '4869');
      expect(fromHex('48 69'), 'Hi');
      expect(fromHex('zz'), isNull);
      expect(fromBase64('!!!'), isNull);
    });
  });

  group('inspektor URL', () {
    test('domain resmi .co.id gak dicurigai', () {
      final r = analyzeUrl('https://www.bca.co.id/id/individu');
      expect(r.domain, 'bca.co.id');
      expect(r.subdomain, 'www');
      expect(r.verdict, 0);
    });
    test('merek di subdomain ketahuan', () {
      final r = analyzeUrl('https://login.bca.co.id.verifikasi-akun.top/');
      expect(r.domain, 'verifikasi-akun.top');
      expect(r.findings.map((f) => f.key), contains('ui_brand_sub'));
      expect(r.verdict, 2);
    });
    test('merek ditempel kata lain + tld murah', () {
      final r = analyzeUrl('http://bca-hadiah-resmi.xyz/klaim?hp=0812');
      final keys = r.findings.map((f) => f.key);
      expect(keys, containsAll(['ui_http', 'ui_brand_extra', 'ui_tld']));
      expect(r.params, [('hp', '0812')]);
    });
    test('domain tiruan pakai angka', () {
      final r = analyzeUrl('https://g00gle.com/login');
      expect(r.findings.map((f) => f.key), contains('ui_lookalike'));
    });
    test('trik @ dan alamat IP', () {
      final r = analyzeUrl('https://bca.co.id@203.0.113.7/login');
      final keys = r.findings.map((f) => f.key);
      expect(keys, containsAll(['ui_at', 'ui_ip']));
    });
    test('bank lain yang namanya mirip gak salah tuduh', () {
      expect(analyzeUrl('https://www.danamon.co.id').verdict, 0);
    });
    test('input ngaco', () {
      expect(analyzeUrl('').valid, isFalse);
      expect(analyzeUrl('halo').valid, isFalse);
    });
  });
}
