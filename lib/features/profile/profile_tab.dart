import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/theme.dart';
import '../../core/badges.dart';
import '../../l10n/strings.dart';
import '../../widgets/common.dart';
import '../pro/certificate_screen.dart';
import '../pro/paywall_screen.dart';
import '../review/review_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final passed = s.bestScores.values.where((v) => v >= 70).length;
    final totalModules = s.content.modules.length;
    final earned = badges.where((b) => b.earned(s)).length;
    final due = s.dueReviews.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        MonoTag(tr('pf_tag'), color: C.accent),
        const SizedBox(height: 6),
        Text(tr('pf_title'), style: display(size: 30)),
        const SizedBox(height: 18),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.1,
          children: [
            _StatBox(icon: Icons.bolt_rounded, color: C.accent, value: '${s.xp}', label: tr('xp')),
            _StatBox(
              icon: Icons.local_fire_department_rounded,
              color: C.orange,
              value: '${s.streak}',
              label: tr('pf_streak', {'n': s.stat('maxStreak')}),
            ),
            _StatBox(icon: Icons.school_rounded, color: C.ok, value: '$passed/$totalModules', label: tr('pf_modules')),
            _StatBox(icon: Icons.flag_rounded, color: C.yellow, value: '${s.flags.length}', label: tr('pf_flags')),
          ],
        ),
        const SizedBox(height: 14),
        Panel(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReviewScreen())),
          borderColor: due > 0 ? C.ok : C.line,
          child: Row(
            children: [
              Icon(Icons.replay_rounded, color: due > 0 ? C.ok : C.muted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  due > 0 ? tr('rv_due', {'n': due}) : tr('rv_none_due'),
                  style: TextStyle(fontWeight: FontWeight.w700, color: C.text),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: C.accent),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Panel(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen())),
          color: s.isPro ? C.okTint : C.accentTint,
          borderColor: s.isPro ? C.okDeep : C.accent,
          child: Row(
            children: [
              Icon(s.isPro ? Icons.verified_rounded : Icons.workspace_premium_rounded,
                  color: s.isPro ? C.ok : C.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.isPro ? tr('pf_pro_on') : tr('pf_pro_off'),
                        style: TextStyle(fontWeight: FontWeight.w800, color: C.text)),
                    const SizedBox(height: 2),
                    Text(s.isPro ? tr('pf_pro_on_d') : tr('pf_pro_off_d'),
                        style: TextStyle(fontSize: 12.5, color: C.muted, height: 1.35)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: C.accent),
            ],
          ),
        ),
        const SizedBox(height: 26),
        Row(
          children: [
            Expanded(child: Text(tr('pf_badges'), style: display(size: 20))),
            MonoTag('$earned/${badges.length}', color: C.accent, filled: true),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.82,
          children: [
            for (final b in badges) _BadgeTile(def: b, earned: b.earned(s)),
          ],
        ),
        const SizedBox(height: 26),
        Text(tr('pf_certs'), style: display(size: 20)),
        const SizedBox(height: 4),
        Text(tr('pf_certs_d'), style: TextStyle(fontSize: 13, color: C.muted, height: 1.4)),
        const SizedBox(height: 12),
        for (final level in s.content.levels.where((l) => l.available))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Builder(builder: (context) {
              final done = level.moduleIds.every(s.isModuleDone);
              return Panel(
                onTap: () {
                  if (!done) {
                    showInfo(context, tr('pf_cert_locked', {'l': level.code}));
                  } else if (!s.isPro) {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const PaywallScreen(reasonKey: 'pw_reason_cert'),
                    ));
                  } else {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => CertificateScreen(level: level),
                    ));
                  }
                },
                color: done ? C.surface : C.bg,
                child: Row(
                  children: [
                    Icon(Icons.workspace_premium_outlined, color: done ? C.accent : C.muted),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('${level.code} · ${level.title}',
                          style: TextStyle(fontWeight: FontWeight.w700, color: done ? C.text : C.muted)),
                    ),
                    if (!done)
                      Icon(Icons.lock_outline_rounded, color: C.muted, size: 20)
                    else if (!s.isPro)
                      MonoTag('PRO', color: C.accent, filled: true)
                    else
                      Icon(Icons.chevron_right_rounded, color: C.accent),
                  ],
                ),
              );
            }),
          ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.icon, required this.color, required this.value, required this.label});
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, maxLines: 1, style: mono(size: 18, color: C.text, weight: FontWeight.w800, spacing: 0)),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: C.muted)),
              ],
            ),
          ),
        ],
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
    return Semantics(
      label: '$name. $how',
      child: Panel(
        onTap: () => showInfo(context, earned ? '$name: $how' : '${tr('bd_locked')} $how'),
        color: earned ? C.accentTint : C.surface,
        borderColor: earned ? C.accent : C.line,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: earned ? C.accent : C.surface2,
                border: Border.all(color: earned ? C.accentSoft : C.line, width: 2),
              ),
              child: Icon(earned ? def.icon : Icons.lock_outline_rounded,
                  color: earned ? C.onAccent : C.muted, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, height: 1.2, color: earned ? C.text : C.muted),
            ),
          ],
        ),
      ),
    );
  }
}
