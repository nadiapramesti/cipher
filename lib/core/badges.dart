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
  BadgeDef('lv2_done', Icons.language_rounded, (s) => _levelDone(s, 2)),
  BadgeDef('lv3_done', Icons.key_rounded, (s) => _levelDone(s, 3)),
  BadgeDef('lv4_done', Icons.gavel_rounded, (s) => _levelDone(s, 4)),
  BadgeDef('lv5_done', Icons.bug_report_rounded, (s) => _levelDone(s, 5)),
  BadgeDef('lv6_done', Icons.security_rounded, (s) => _levelDone(s, 6)),
  BadgeDef('lv7_done', Icons.cloud_done_rounded, (s) => _levelDone(s, 7)),
  BadgeDef('lv8_done', Icons.build_circle_rounded, (s) => _levelDone(s, 8)),
  BadgeDef('lv9_done', Icons.qr_code_scanner_rounded, (s) => _levelDone(s, 9)),
  BadgeDef('lv10_done', Icons.api_rounded, (s) => _levelDone(s, 10)),
  BadgeDef('lv11_done', Icons.memory_rounded, (s) => _levelDone(s, 11)),
  BadgeDef('lv12_done', Icons.radar_rounded, (s) => _levelDone(s, 12)),
  BadgeDef('lv13_done', Icons.emoji_events_rounded, (s) => _levelDone(s, 13)),
  BadgeDef('tamat', Icons.auto_awesome_rounded, (s) {
    final levels = s.content.levels.where((l) => l.available);
    return levels.isNotEmpty && levels.every(s.isLevelDone);
  }),
  BadgeDef('exam_first', Icons.verified_rounded, (s) => s.examsPassed >= 1),
  BadgeDef('exam_all', Icons.military_tech_rounded, (s) {
    final levels = s.content.levels.where((l) => l.available);
    return levels.isNotEmpty && levels.every((l) => s.isExamPassed(l.index));
  }),
  BadgeDef('streak3', Icons.local_fire_department_rounded, (s) => s.stat('maxStreak') >= 3),
  BadgeDef('streak7', Icons.whatshot_rounded, (s) => s.stat('maxStreak') >= 7),
  BadgeDef('scam_hunter', Icons.phishing, (s) => s.stat('scamBest') >= 100),
  BadgeDef('root', Icons.terminal, (s) => s.flags.contains('terminal')),
  BadgeDef('pass_master', Icons.password, (s) => s.flags.contains('passphrase')),
  BadgeDef('reviewer', Icons.replay_rounded, (s) => s.stat('reviews') > 0),
  BadgeDef('ctf_all', Icons.emoji_events_rounded, (s) => s.flags.length >= 5),
];
