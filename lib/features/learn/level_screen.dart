import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/theme.dart';
import '../../core/models.dart';
import '../../widgets/common.dart';
import 'module_screen.dart';

class LevelScreen extends StatelessWidget {
  const LevelScreen({super.key, required this.level});

  final Level level;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final modules = state.content.modulesOf(level);

    return Scaffold(
      appBar: AppBar(title: Text('${level.code}  ${level.title}')),
      body: modules.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: StateMessage(
                glyph: '[..]',
                title: 'Materi lagi disiapin',
                body: 'Level ini belum ada modulnya. Cek lagi nanti ya.',
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              itemCount: modules.length + 1,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(level.tagline,
                        style: const TextStyle(color: C.muted, height: 1.45)),
                  );
                }
                final m = modules[i - 1];
                return _ModuleTile(number: i, module: m);
              },
            ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({required this.number, required this.module});

  final int number;
  final LearnModule module;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final done = state.isModuleDone(module.id);
    final unlocked = state.isModuleUnlocked(module);
    final best = state.bestScores[module.id];

    final (IconData icon, Color color) = done
        ? (Icons.check_circle_rounded, C.ok)
        : unlocked
            ? (Icons.play_circle_fill_rounded, C.accent)
            : (Icons.lock_outline_rounded, C.muted);

    return Panel(
      onTap: () {
        if (!unlocked) {
          showInfo(context, 'Lulusin modul sebelumnya dulu ya.');
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ModuleScreen(module: module)),
        );
      },
      color: unlocked ? C.surface : C.bg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(number.toString().padLeft(2, '0'),
              style: mono(size: 20, color: unlocked ? C.accent : C.muted, weight: FontWeight.w800)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(module.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15.5,
                      color: unlocked ? C.text : C.muted,
                    )),
                const SizedBox(height: 4),
                Text(module.summary,
                    style: const TextStyle(color: C.muted, fontSize: 13, height: 1.4)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    MonoTag('${module.minutes} mnt'),
                    const SizedBox(width: 10),
                    MonoTag('${module.quiz.length} soal'),
                    if (best != null) ...[
                      const SizedBox(width: 10),
                      MonoTag('skor $best%', color: done ? C.ok : C.orange),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, color: color),
        ],
      ),
    );
  }
}
