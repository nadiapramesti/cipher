import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/theme.dart';
import '../../core/models.dart';
import '../../widgets/common.dart';
import 'level_screen.dart';
import 'module_screen.dart';

class LearnTab extends StatelessWidget {
  const LearnTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final next = state.nextModule;
    final nextLevel = next == null ? null : state.content.levelAt(next.level);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Row(
          children: [
            Text('CIPHER',
                style: mono(size: 18, color: C.text, weight: FontWeight.w800, spacing: 4)),
            Text('_', style: mono(size: 18, color: C.amber, weight: FontWeight.w800)),
            const Spacer(),
            _Stat(icon: Icons.bolt_rounded, value: '${state.xp}', label: 'XP'),
            const SizedBox(width: 8),
            _Stat(
              icon: Icons.local_fire_department_rounded,
              value: '${state.streak}',
              label: 'hari',
              color: state.streak > 0 ? C.orange : C.muted,
            ),
          ],
        ),
        const SizedBox(height: 22),
        if (next != null)
          Panel(
            borderColor: C.amber.withValues(alpha: 0.55),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const MonoTag('// lanjutkan', color: C.amber),
                    const Spacer(),
                    MonoTag('${nextLevel?.code ?? ''} · ${next.minutes} mnt'),
                  ],
                ),
                const SizedBox(height: 10),
                Text(next.title,
                    style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, height: 1.2)),
                const SizedBox(height: 6),
                Text(next.summary,
                    style: const TextStyle(color: C.muted, height: 1.45)),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ModuleScreen(module: next)),
                  ),
                  child: const Text('Lanjut Belajar'),
                ),
              ],
            ),
          )
        else
          const StateMessage(
            glyph: '[ok]',
            color: C.teal,
            title: 'Semua modul yang ada udah kelar',
            body: 'Mantap! Materi level berikutnya lagi disiapin. Sambil nunggu, coba Toolbox atau baca Kamus.',
          ),
        const SizedBox(height: 28),
        const MonoTag('// jalur belajar'),
        const SizedBox(height: 12),
        for (final level in state.content.levels)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _LevelCard(level: level),
          ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.value,
    required this.label,
    this.color = C.amber,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: C.line),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(value, style: mono(size: 13, color: C.text, weight: FontWeight.w800)),
          const SizedBox(width: 3),
          Text(label, style: mono(size: 11)),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.level});

  final Level level;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final unlocked = state.isLevelUnlocked(level);
    final total = level.moduleIds.length;
    final done = state.levelProgress(level);
    final active = unlocked && level.available;
    final accent = active ? C.amber : C.muted;

    void onTap() {
      if (!level.available) {
        showInfo(context, 'Materi ${level.code} lagi disiapin. Segera hadir!');
      } else if (!unlocked) {
        final prev = state.content.levelAt(level.index - 1);
        showInfo(context, 'Selesaikan ${prev?.code ?? 'level sebelumnya'} dulu buat buka ${level.code}.');
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => LevelScreen(level: level)),
        );
      }
    }

    return Panel(
      onTap: onTap,
      color: active ? C.surface : C.bg,
      padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LV', style: mono(size: 10, color: accent)),
                Text(level.index.toString().padLeft(2, '0'),
                    style: mono(size: 30, color: accent, weight: FontWeight.w800, spacing: 0)),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(level.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: active ? C.text : C.muted,
                    )),
                const SizedBox(height: 3),
                Text(level.tagline,
                    style: const TextStyle(color: C.muted, fontSize: 13, height: 1.35)),
                if (level.available) ...[
                  const SizedBox(height: 10),
                  ProgressLine(
                    value: total == 0 ? 0 : done / total,
                    color: done == total ? C.teal : C.amber,
                  ),
                  const SizedBox(height: 6),
                  Text('$done/$total modul', style: mono(size: 11)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (!level.available)
            const MonoTag('SOON', filled: true)
          else if (!unlocked)
            const Icon(Icons.lock_outline_rounded, color: C.muted)
          else
            const Icon(Icons.chevron_right_rounded, color: C.amber),
        ],
      ),
    );
  }
}
