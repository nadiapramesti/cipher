import 'package:flutter/material.dart';

import '../app/app_state.dart';

/// Satu lencana. [earned] dihitung dari progres, jadi gak perlu disimpan terpisah.
class BadgeDef {
  const BadgeDef(this.id, this.icon, this.earned);
  final String id;
  final IconData icon;
  final bool Function(AppState s) earned;
}

bool _levelDone(AppState s, int index) {
  final level = s.content.levelAt(index);
  if (level == null || level.moduleIds.isEmpty) return false;
  return level.moduleIds.every(s.isModuleDone);
}

final List<BadgeDef> badges = [
  BadgeDef('first_step', Icons.flag_rounded, (s) => s.bestScores.values.any((v) => v >= 70)),
  BadgeDef('perfect', Icons.star_rounded, (s) => s.stat('perfect') > 0),
  BadgeDef('lv0_done', Icons.shield_rounded, (s) => _levelDone(s, 0)),
  BadgeDef('lv1_done', Icons.lan, (s) => _levelDone(s, 1)),
  BadgeDef('streak3', Icons.local_fire_department_rounded, (s) => s.stat('maxStreak') >= 3),
  BadgeDef('streak7', Icons.whatshot_rounded, (s) => s.stat('maxStreak') >= 7),
  BadgeDef('scam_hunter', Icons.phishing, (s) => s.stat('scamBest') >= 100),
  BadgeDef('root', Icons.terminal, (s) => s.flags.contains('terminal')),
  BadgeDef('pass_master', Icons.password, (s) => s.flags.contains('passphrase')),
  BadgeDef('reviewer', Icons.replay_rounded, (s) => s.stat('reviews') > 0),
  BadgeDef('ctf_all', Icons.emoji_events_rounded, (s) => s.flags.length >= 5),
];
