import '../ctf/flags.dart';

/// Shell Linux mini buat latihan. Semua file palsu, hidup di memori aja.
class VirtualShell {
  VirtualShell({bool english = false}) : _en = english {
    _fs = {
      '/': ['home', 'etc', 'var'],
      '/etc': ['motd'],
      '/var': ['log'],
      '/var/log': ['auth.log'],
      '/home': ['kamu'],
      '/home/kamu': [_t('baca_aku.txt', 'read_me.txt'), _t('catatan', 'notes'), '.rahasia'],
      '/home/kamu/${_t('catatan', 'notes')}': [_t('tugas.txt', 'todo.txt'), _t('password_lama.txt', 'old_password.txt')],
      '/home/kamu/.rahasia': ['flag.txt'],
    };
    _files = {
      '/etc/motd': _t('Selamat datang di Cipher Linux (simulasi).', 'Welcome to Cipher Linux (simulated).'),
      '/home/kamu/${_t('baca_aku.txt', 'read_me.txt')}': _t(
        'Halo! Ini terminal latihan.\nCoba: ls, cd, pwd, cat, grep.\nPetunjuk: file tersembunyi namanya diawali titik. Pakai "ls -a".\nLatihan log: grep Failed /var/log/auth.log',
        'Hi! This is a practice terminal.\nTry: ls, cd, pwd, cat, grep.\nHint: hidden files start with a dot. Use "ls -a".\nLog practice: grep Failed /var/log/auth.log',
      ),
      '/home/kamu/${_t('catatan', 'notes')}/${_t('tugas.txt', 'todo.txt')}': _t(
        '1. Pelajari perintah dasar\n2. Cari folder yang disembunyikan\n3. Baca flag-nya',
        '1. Learn the basic commands\n2. Find the hidden folder\n3. Read the flag',
      ),
      '/home/kamu/${_t('catatan', 'notes')}/${_t('password_lama.txt', 'old_password.txt')}': _t(
        'bismillah123\n(Contoh BURUK: jangan pernah simpan password di file biasa!)',
        'bismillah123\n(BAD example: never keep passwords in a plain file!)',
      ),
      '/home/kamu/.rahasia/flag.txt': Flags.terminal,
      '/var/log/auth.log': [
        'Nov 24 08:01:12 sshd: Accepted password for kamu from 192.168.1.20',
        'Nov 24 21:03:01 sshd: Failed password for root from 203.0.113.7',
        'Nov 24 21:03:02 sshd: Failed password for root from 203.0.113.7',
        'Nov 24 21:03:03 sshd: Failed password for admin from 203.0.113.7',
        'Nov 24 21:03:04 sshd: Failed password for admin from 203.0.113.7',
        'Nov 24 21:03:05 sshd: Failed password for kamu from 203.0.113.7',
        'Nov 24 21:03:07 sshd: Accepted password for kamu from 203.0.113.7',
        'Nov 24 21:03:09 sudo: kamu : COMMAND=/bin/cat /home/kamu/.rahasia/flag.txt',
      ].join('\n'),
    };
  }

  final bool _en;
  late final Map<String, List<String>> _fs;
  late final Map<String, String> _files;
  String cwd = '/home/kamu';

  String _t(String id, String en) => _en ? en : id;

  String get prompt => 'kamu@cipher:${cwd.replaceFirst('/home/kamu', '~')}\$';

  String _resolve(String path) {
    if (path.isEmpty || path == '~') return '/home/kamu';
    var p = path.startsWith('~') ? '/home/kamu${path.substring(1)}' : path;
    if (!p.startsWith('/')) p = cwd == '/' ? '/$p' : '$cwd/$p';
    final parts = <String>[];
    for (final seg in p.split('/')) {
      if (seg.isEmpty || seg == '.') continue;
      if (seg == '..') {
        if (parts.isNotEmpty) parts.removeLast();
      } else {
        parts.add(seg);
      }
    }
    return '/${parts.join('/')}';
  }

  bool _isDir(String p) => _fs.containsKey(p);
  bool _isFile(String p) => _files.containsKey(p);

  /// Jalankan satu baris perintah, balikin teks output.
  /// Output `\x1b` khusus dipakai buat "clear".
  String run(String line) {
    final args = line.trim().split(RegExp(r'\s+')).where((a) => a.isNotEmpty).toList();
    if (args.isEmpty) return '';
    final cmd = args.first;
    final rest = args.skip(1).toList();

    switch (cmd) {
      case 'help':
        return _t(
          'Perintah: ls [-a] [folder], cd <folder>, pwd, cat <file>, grep <kata> <file>, whoami, echo <teks>, clear',
          'Commands: ls [-a] [dir], cd <dir>, pwd, cat <file>, grep <word> <file>, whoami, echo <text>, clear',
        );
      case 'pwd':
        return cwd;
      case 'whoami':
        return 'kamu';
      case 'echo':
        return rest.join(' ');
      case 'clear':
        return '\x1b';
      case 'ls':
        final all = rest.contains('-a') || rest.contains('-la') || rest.contains('-al');
        final target = rest.where((a) => !a.startsWith('-')).firstOrNull;
        final dir = _resolve(target ?? '.');
        if (_isFile(dir)) return target ?? dir;
        if (!_isDir(dir)) return _t('ls: tidak ada folder "$target"', 'ls: no such directory "$target"');
        final items = _fs[dir]!.where((n) => all || !n.startsWith('.')).toList();
        final shown = all ? ['.', '..', ...items] : items;
        return shown.map((n) => _isDir(dir == '/' ? '/$n' : '$dir/$n') ? '$n/' : n).join('  ');
      case 'cd':
        final dir = _resolve(rest.firstOrNull ?? '~');
        if (!_isDir(dir)) return _t('cd: tidak ada folder "${rest.first}"', 'cd: no such directory "${rest.first}"');
        cwd = dir;
        return '';
      case 'cat':
        if (rest.isEmpty) return _t('cat: sebutin nama file', 'cat: name a file');
        final f = _resolve(rest.first);
        if (_isDir(f)) return _t('cat: "${rest.first}" itu folder', 'cat: "${rest.first}" is a directory');
        return _files[f] ?? _t('cat: tidak ada file "${rest.first}"', 'cat: no such file "${rest.first}"');
      case 'grep':
        if (rest.length < 2) return _t('grep: pakai grep <kata> <file>', 'grep: use grep <word> <file>');
        final f = _resolve(rest[1]);
        final text = _files[f];
        if (text == null) return _t('grep: tidak ada file "${rest[1]}"', 'grep: no such file "${rest[1]}"');
        return text.split('\n').where((l) => l.toLowerCase().contains(rest[0].toLowerCase())).join('\n');
      case 'sudo':
      case 'rm':
        return _t('$cmd: gak diizinkan di simulasi ini', '$cmd: not allowed in this simulation');
      default:
        return _t('$cmd: perintah tidak dikenal. Ketik "help".', '$cmd: command not found. Type "help".');
    }
  }
}
