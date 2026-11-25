import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/theme.dart';
import '../../core/badges.dart';
import '../../core/models.dart';
import '../../l10n/strings.dart';
import '../../widgets/common.dart';
import '../learn/learn_tab.dart' show TierChip, openLevel;
import '../pro/certificate_screen.dart';
import '../pro/paywall_screen.dart';
import '../review/review_screen.dart';

/// Pangkat dari jumlah level yang udah tamat.
String rankKey(int levelsDone, int levelsTotal) {
  if (levelsTotal > 0 && levelsDone >= levelsTotal) return 'rank_5';
  if (levelsDone >= 10) return 'rank_4';
  if (levelsDone >= 6) return 'rank_3';
  if (levelsDone >= 3) return 'rank_2';
  if (levelsDone >= 1) return 'rank_1';
  return 'rank_0';
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final levels = s.content.levels.where((l) => l.available).toList();
    final levelsDone = levels.where(s.isLevelDone).length;
    final totalModules = s.content.modules.length;
    final passed = s.modulesPassed;
    final due = s.dueReviews.length;

    final earnedList = badges.where((b) => b.earned(s)).toList();
    final lockedList = badges.where((b) => !b.earned(s)).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        _AgentCard(
          name: s.certName.isEmpty ? tr('pf_agent') : s.certName,
          rank: tr(rankKey(levelsDone, levels.length)),
          progress: totalModules == 0 ? 0 : passed / totalModules,
          levelsDone: levelsDone,
          levelsTotal: levels.length,
          onEditName: () => _editName(context, s),
        ),
        const SizedBox(height: 12),
        Panel(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: IntrinsicHeight(
            child: Row(
              children: [
                _Stat(icon: Icons.bolt_rounded, color: C.accent, value: '${s.xp}', label: tr('xp')),
                const _Divider(),
                _Stat(
                  icon: Icons.local_fire_department_rounded,
                  color: C.orange,
                  value: '${s.streak}',
                  label: tr('pf_best', {'n': s.stat('maxStreak')}),
                ),
                const _Divider(),
                _Stat(icon: Icons.school_rounded, color: C.ok, value: '$passed', label: tr('pf_modules_short')),
                const _Divider(),
                _Stat(icon: Icons.flag_rounded, color: C.yellow, value: '${s.flags.length}/5', label: tr('pf_flags_short')),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ActionRow(
          icon: Icons.replay_rounded,
          color: due > 0 ? C.ok : C.muted,
          title: due > 0 ? tr('rv_due', {'n': due}) : tr('rv_none_due'),
          highlight: due > 0,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReviewScreen())),
        ),
        if (kStoreBuild) ...[
          const SizedBox(height: 10),
          _ActionRow(
            icon: s.isPro ? Icons.verified_rounded : Icons.workspace_premium_rounded,
            color: s.isPro ? C.ok : C.accent,
            title: s.isPro ? tr('pf_pro_on') : tr('pf_pro_off'),
            subtitle: s.isPro ? tr('pf_pro_on_d') : tr('pf_pro_off_d'),
            highlight: !s.isPro,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen())),
          ),
        ],

        // --- perjalanan -------------------------------------------------------
        const SizedBox(height: 26),
        _SectionHead(title: tr('pf_journey'), trailing: '$levelsDone/${levels.length}'),
        const SizedBox(height: 10),
        Panel(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Column(
            children: [
              for (final level in levels) _JourneyRow(level: level),
            ],
          ),
        ),

        // --- lencana ----------------------------------------------------------
        const SizedBox(height: 26),
        _SectionHead(title: tr('pf_badges'), trailing: '${earnedList.length}/${badges.length}'),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.78,
          children: [
            for (final b in earnedList) _BadgeTile(def: b, earned: true),
            for (final b in lockedList) _BadgeTile(def: b, earned: false),
          ],
        ),

        // --- sertifikat -------------------------------------------------------
        const SizedBox(height: 26),
        _SectionHead(
          title: tr('pf_certs'),
          trailing: '${levels.where((l) => s.isLevelDone(l) && s.isExamPassed(l.index)).length}/${levels.length}',
        ),
        const SizedBox(height: 4),
        Text(tr('pf_certs_d'), style: TextStyle(fontSize: 12.5, color: C.muted, height: 1.4)),
        const SizedBox(height: 10),
        for (final level in levels) _CertRow(level: level),
      ],
    );
  }

  Future<void> _editName(BuildContext context, AppState s) async {
    final ctrl = TextEditingController(text: s.certName);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: C.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(tr('pf_name_title'), style: display(size: 22)),
            const SizedBox(height: 6),
            Text(tr('pf_name_d'), style: TextStyle(color: C.muted, fontSize: 13, height: 1.4)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              keyboardType: TextInputType.name,
              maxLength: 40,
              decoration: InputDecoration(labelText: tr('pf_name_label'), hintText: 'Nadia Pramesti'),
              onSubmitted: (v) => Navigator.of(ctx).pop(v),
            ),
            const SizedBox(height: 8),
            ChunkyButton(onPressed: () => Navigator.of(ctx).pop(ctrl.text), child: Text(tr('save'))),
          ],
        ),
      ),
    );
    ctrl.dispose();
    if (result != null) await s.setCertName(result);
  }
}

// ---------------------------------------------------------------------------

class _AgentCard extends StatelessWidget {
  const _AgentCard({
    required this.name,
    required this.rank,
    required this.progress,
    required this.levelsDone,
    required this.levelsTotal,
    required this.onEditName,
  });

  final String name;
  final String rank;
  final double progress;
  final int levelsDone;
  final int levelsTotal;
  final VoidCallback onEditName;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).take(2).map((w) => w[0].toUpperCase()).join();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [C.accentDeep, C.surface, C.bgDeep],
          stops: const [0, 0.55, 1],
        ),
        border: Border.all(color: C.accent.withValues(alpha: 0.55)),
        boxShadow: [BoxShadow(color: C.accentDeep.withValues(alpha: 0.45), offset: const Offset(0, 8))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _CardGridPainter())),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    MonoTag(tr('pf_card_tag'), color: C.accentSoft),
                    const Spacer(),
                    Material(
                      color: C.bgDeep.withValues(alpha: 0.6),
                      shape: StadiumBorder(side: BorderSide(color: C.lineStrong)),
                      child: InkWell(
                        customBorder: const StadiumBorder(),
                        onTap: onEditName,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.edit_rounded, size: 14, color: C.accent),
                            const SizedBox(width: 6),
                            Text(tr('pf_edit_name'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: C.text)),
                          ]),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(
                      width: 92,
                      height: 92,
                      child: CustomPaint(
                        painter: _RingPainter(progress),
                        child: Center(
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: C.accent,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: C.accentDeep, offset: const Offset(0, 4))],
                            ),
                            alignment: Alignment.center,
                            child: Text(initials.isEmpty ? '?' : initials,
                                style: display(size: 26, color: C.onAccent)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: display(size: 22, height: 1.1)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: C.yellow.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: C.yellow.withValues(alpha: 0.6)),
                            ),
                            child: Text(rank.toUpperCase(),
                                style: mono(size: 10.5, color: C.yellow, weight: FontWeight.w800, spacing: 0.8)),
                          ),
                          const SizedBox(height: 10),
                          Text('${(progress * 100).round()}% · ${tr('pf_levels_done', {'d': levelsDone, 't': levelsTotal})}',
                              style: mono(size: 11.5, color: C.textSoft, spacing: 0)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 5;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(c, r, Paint()..color = C.bgDeep.withValues(alpha: 0.7)..style = PaintingStyle.stroke..strokeWidth = 7);
    if (progress > 0) {
      final sweep = math.max(0.04, progress.clamp(0.0, 1.0)) * math.pi * 2;
      canvas.drawArc(rect, -math.pi / 2, sweep, false, Paint()
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: math.pi * 1.5,
          colors: [C.accent, C.ok, C.yellow, C.accent],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

class _CardGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = C.accent.withValues(alpha: 0.07)..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 18) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (var y = 0.0; y < size.height; y += 18) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(_CardGridPainter old) => false;
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.color, required this.value, required this.label});
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value, maxLines: 1, style: mono(size: 17, color: C.text, weight: FontWeight.w800, spacing: 0)),
          const SizedBox(height: 2),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: C.muted)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Container(width: 1, margin: const EdgeInsets.symmetric(vertical: 4), color: C.line);
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.icon, required this.color, required this.title, required this.onTap, this.subtitle, this.highlight = false});
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final bool highlight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Panel(
      onTap: onTap,
      color: highlight ? color.withValues(alpha: 0.08) : C.surface,
      borderColor: highlight ? color.withValues(alpha: 0.6) : C.line,
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: C.text)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: TextStyle(fontSize: 12, color: C.muted, height: 1.35)),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: C.accent),
        ],
      ),
    );
  }
}

class _SectionHead extends StatelessWidget {
  const _SectionHead({required this.title, required this.trailing});
  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: display(size: 20))),
        MonoTag(trailing, color: C.accent, filled: true),
      ],
    );
  }
}

/// Satu baris perjalanan: kode level, nama, label tingkat, bar progres, status.
class _JourneyRow extends StatelessWidget {
  const _JourneyRow({required this.level});
  final Level level;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final total = level.moduleIds.length;
    final done = s.levelProgress(level);
    final unlocked = s.isLevelUnlocked(level);
    final finished = s.isLevelDone(level);
    final exam = s.isExamPassed(level.index);
    final color = finished ? C.ok : (unlocked ? C.accent : C.hint);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => openLevel(context, level),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            SizedBox(width: 48, child: Text(level.code, style: mono(size: 11.5, color: color, weight: FontWeight.w800, spacing: 0))),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(
                      child: Text(level.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: unlocked ? C.text : C.muted)),
                    ),
                    const SizedBox(width: 6),
                    TierChip(index: level.index),
                  ]),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: total == 0 ? 0 : done / total,
                      minHeight: 5,
                      color: color,
                      backgroundColor: C.line,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 38,
              child: Align(
                alignment: Alignment.centerRight,
                child: !unlocked
                    ? Icon(Icons.lock_rounded, size: 15, color: C.hint)
                    : exam
                        ? Icon(Icons.verified_rounded, size: 18, color: C.ok)
                        : Text('$done/$total', style: mono(size: 10.5, color: C.muted, spacing: 0)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.def, required this.earned});
  final BadgeDef def;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final name = tr('bd_${def.id}');
    final how = tr('bd_${def.id}_d');
    final special = def.id == 'tamat' || def.id == 'exam_all';
    final ring = special ? C.yellow : C.accent;

    return Semantics(
      label: '$name. $how',
      button: true,
      child: GestureDetector(
        onTap: () => showInfo(context, earned ? '$name: $how' : '${tr('bd_locked')} $how'),
        child: Container(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
          decoration: BoxDecoration(
            color: earned ? ring.withValues(alpha: 0.1) : C.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: earned ? ring.withValues(alpha: 0.7) : C.line),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: earned ? ring : C.bg,
                  border: Border.all(color: earned ? ring.withValues(alpha: 0.5) : C.line, width: 2),
                  boxShadow: earned ? [BoxShadow(color: ring.withValues(alpha: 0.45), blurRadius: 12)] : null,
                ),
                child: Icon(def.icon, color: earned ? C.onAccent : C.hint.withValues(alpha: 0.6), size: 21),
              ),
              const SizedBox(height: 7),
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, height: 1.2, color: earned ? C.text : C.hint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CertRow extends StatelessWidget {
  const _CertRow({required this.level});
  final Level level;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final modulesDone = s.isLevelDone(level);
    final exam = s.isExamPassed(level.index);
    final ready = modulesDone && exam;

    final (String label, Color color) = ready
        ? (s.hasPro ? tr('pf_cert_ready') : 'PRO', s.hasPro ? C.ok : C.accent)
        : modulesDone
            ? (tr('pf_cert_need_exam'), C.orange)
            : (tr('pf_cert_need_modules'), C.hint);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Panel(
        onTap: () {
          if (!ready) {
            showInfo(context, tr('pf_cert_locked', {'l': level.code}));
          } else if (!s.hasPro) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen(reasonKey: 'pw_reason_cert')));
          } else {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => CertificateScreen(level: level)));
          }
        },
        color: ready ? C.surface : C.bg,
        borderColor: ready ? C.ok.withValues(alpha: 0.6) : C.line,
        padding: const EdgeInsets.fromLTRB(14, 11, 12, 11),
        child: Row(
          children: [
            Icon(Icons.workspace_premium_rounded, size: 22, color: ready ? C.yellow : C.hint),
            const SizedBox(width: 12),
            Expanded(
              child: Text('${level.code} · ${level.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: ready ? C.text : C.muted)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withValues(alpha: 0.5)),
              ),
              child: Text(label, style: mono(size: 9.5, color: color, weight: FontWeight.w800, spacing: 0.4)),
            ),
          ],
        ),
      ),
    );
  }
}
