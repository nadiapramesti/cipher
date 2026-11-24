import 'dart:convert';

import 'package:cipher/features/ctf/flags.dart';
import 'package:cipher/features/sim/shell.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('terminal simulasi', () {
    test('file tersembunyi cuma muncul pakai ls -a', () {
      final sh = VirtualShell();
      expect(sh.run('ls'), isNot(contains('.rahasia')));
      expect(sh.run('ls -a'), contains('.rahasia/'));
    });

    test('bisa nemu flag lewat cd + cat', () {
      final sh = VirtualShell();
      expect(sh.run('cd .rahasia'), '');
      expect(sh.run('pwd'), '/home/kamu/.rahasia');
      expect(sh.run('cat flag.txt'), Flags.terminal);
      sh.run('cd ..');
      expect(sh.run('pwd'), '/home/kamu');
    });

    test('path absolut, ~, dan perintah gak dikenal', () {
      final sh = VirtualShell(english: true);
      expect(sh.run('cat /etc/motd'), contains('Cipher Linux'));
      sh.run('cd /');
      sh.run('cd ~');
      expect(sh.run('pwd'), '/home/kamu');
      expect(sh.run('hack'), contains('command not found'));
      expect(sh.run('grep password notes/old_password.txt'), contains('password'));
    });
  });

  group('mini CTF', () {
    test('semua flag yang disebar di app dikenali', () {
      expect(matchFlag(Flags.terminal)?.id, 'terminal');
      expect(matchFlag(Flags.scam)?.id, 'scam');
      expect(matchFlag(Flags.passphrase)?.id, 'passphrase');
      expect(matchFlag(Flags.logo)?.id, 'logo');
    });

    test('petunjuk base64 bener-bener isinya flag', () {
      final decoded = utf8.decode(base64.decode(Flags.base64Clue));
      expect(matchFlag(decoded)?.id, 'base64');
    });

    test('flag salah ditolak, spasi diabaikan', () {
      expect(matchFlag('CIPHER{asal}'), isNull);
      expect(matchFlag('  ${Flags.logo} ')?.id, 'logo');
    });
  });
}
