import '../../core/backup.dart';

/// Satu tantangan mini CTF. Flag disimpan sebagai checksum, bukan teks asli.
class CtfChallenge {
  const CtfChallenge(this.id, this.level, this.hash);
  final String id;
  final int level;
  final String hash;
}

/// Nilai flag (dipakai di layar yang "menyembunyikan" flag-nya).
class Flags {
  static const terminal = 'CIPHER{h1dd3n_f1l3s}';
  static const scam = 'CIPHER{ph1sh_hunt3r}';
  static const passphrase = 'CIPHER{p4ssphr4s3_r0y4l}';
  static const logo = 'CIPHER{l0ng_pr3ss_l0g0}';

  /// Encode Base64 dari CIPHER{b4s364_bukan_enkripsi}
  static const base64Clue = 'Q0lQSEVSe2I0czM2NF9idWthbl9lbmtyaXBzaX0=';
}

String normalizeFlag(String input) => input.trim().replaceAll(RegExp(r'\s'), '');

/// Daftar tantangan. Hash = fnv32 dari flag yang benar.
final List<CtfChallenge> ctfChallenges = [
  CtfChallenge('terminal', 1, fnv32(Flags.terminal)),
  CtfChallenge('base64', 0, fnv32('CIPHER{b4s364_bukan_enkripsi}')),
  CtfChallenge('scam', 0, fnv32(Flags.scam)),
  CtfChallenge('passphrase', 0, fnv32(Flags.passphrase)),
  CtfChallenge('logo', 0, fnv32(Flags.logo)),
];

/// Cari tantangan yang cocok dengan flag yang diketik. null = salah.
CtfChallenge? matchFlag(String input) {
  final h = fnv32(normalizeFlag(input));
  for (final c in ctfChallenges) {
    if (c.hash == h) return c;
  }
  return null;
}
