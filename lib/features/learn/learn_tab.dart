import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_state.dart';
import '../../app/theme.dart';
import '../../core/models.dart';
import '../../widgets/common.dart';
import '../../widgets/scene3d.dart';
import '../ctf/flags.dart';
import '../pro/paywall_screen.dart';
import '../review/review_screen.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';
import 'level_screen.dart';
import 'module_screen.dart';
import '../../l10n/strings.dart';

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
            // rahasia kecil: tekan lama logo buat nemu flag CTF
            GestureDetector(
              onLongPress: () {
                HapticFeedback.mediumImpact();
                showModalBottomSheet<void>(
                  context: context,
                  backgroundColor: C.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                  ),
                  builder: (ctx) => SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(tr('logo_found'), style: display(size: 20)),
                          const SizedBox(height: 12),
                          const FlagBox(flag: Flags.logo),
                        ],
                      ),
                    ),
                  ),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('CIPHER',
                      style: mono(size: 18, color: C.text, weight: FontWeight.w800, spacing: 4)),
                  Text('_', style: mono(size: 18, color: C.accent, weight: FontWeight.w800)),
                ],
              ),
            ),
            const Spacer(),
            _HeaderButton(
              icon: Icons.search_rounded,
              label: tr('search_title'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              ),
            ),
            const SizedBox(width: 6),
            _HeaderButton(
              icon: Icons.tune_rounded,
              label: tr('settings'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _Stat(icon: Icons.bolt_rounded, value: '${state.xp}', label: tr('xp')),
            const SizedBox(width: 8),
            _Stat(
              icon: Icons.local_fire_department_rounded,
              value: '${state.streak}',
              label: tr('days'),
              color: state.streak > 0 ? C.orange : C.muted,
            ),
          ],
        ),
        const SizedBox(height: 14),
        MonoTag(tr('map_title')),
        SizedBox(
          height: 300,
          child: IsoMap(
            tiles: [
              for (final level in state.content.levels)
                IsoTile(
                  label: level.available && state.isLevelUnlocked(level)
                      ? '${level.code} · ${state.levelProgress(level)}/${level.moduleIds.length}'
                      : level.code,
                  state: _tileState(state, level),
                ),
            ],
            onTap: (i) => openLevel(context, state.content.levels[i]),
          ),
        ),
        const SizedBox(height: 4),
        if (state.dueReviews.isNotEmpty) ...[
          Panel(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReviewScreen()),
            ),
            color: C.okTint,
            borderColor: C.okDeep,
            child: Row(
              children: [
                Icon(Icons.replay_rounded, color: C.ok),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('rv_due', {'n': state.dueReviews.length}),
                          style: TextStyle(fontWeight: FontWeight.w800, color: C.text)),
                      const SizedBox(height: 2),
                      Text(tr('rv_hint'), style: TextStyle(fontSize: 12.5, color: C.muted)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: C.ok, borderRadius: BorderRadius.circular(10)),
                  child: Text(tr('rv_start'), style: TextStyle(fontWeight: FontWeight.w800, color: C.onAccent, fontSize: 13)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (next != null)
          Panel(
            borderColor: C.accent.withValues(alpha: 0.55),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: MonoTag(
                        tr('district', {'code': nextLevel?.code ?? '', 'title': nextLevel?.title ?? ''}),
                        color: C.accent,
                      ),
                    ),
                    MonoTag(tr('min', {'n': next.minutes})),
                  ],
                ),
                const SizedBox(height: 10),
                Text(next.title,
                    style: display(size: 21)),
                const SizedBox(height: 6),
                Text(next.summary,
                    style: TextStyle(color: C.muted, height: 1.45)),
                const SizedBox(height: 16),
                ChunkyButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ModuleScreen(module: next)),
                  ),
                  child: Text(tr('enter_module')),
                ),
              ],
            ),
          )
        else
          StateMessage(
            glyph: '[ok]',
            color: C.ok,
            title: tr('all_done_title'),
            body: tr('all_done_body'),
          ),
        const SizedBox(height: 28),
        MonoTag(tr('all_levels')),
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

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: C.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: C.lineStrong),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 34,
            child: Icon(icon, size: 19, color: C.accent, semanticLabel: label),
          ),
        ),
      ),
    );
  }
}

IsoTileState _tileState(AppState state, Level level) {
  if (!level.available) return IsoTileState.soon;
  if (!state.isLevelUnlocked(level)) return IsoTileState.locked;
  final total = level.moduleIds.length;
  if (total > 0 && state.levelProgress(level) == total) return IsoTileState.done;
  return IsoTileState.active;
}

void openLevel(BuildContext context, Level level) {
  final state = AppScope.read(context);
  if (AppState.isProLevel(level.index) && !state.hasPro) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const PaywallScreen(reasonKey: 'pw_reason_level'),
    ));
    return;
  }
  if (!level.available) {
    showInfo(context, tr('lvl_soon', {'code': level.code}));
  } else if (!state.isLevelUnlocked(level)) {
    final prev = state.content.levelAt(level.index - 1);
    showInfo(context, tr('lvl_locked', {'prev': prev?.code ?? tr('lvl_prev'), 'code': level.code}));
  } else {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LevelScreen(level: level)),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.value,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? C.accent;
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
    final accent = active ? C.accent : C.muted;

    return Panel(
      onTap: () => openLevel(context, level),
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
                Row(
                  children: [
                    Flexible(
                      child: Text(level.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: active ? C.text : C.muted,
                          )),
                    ),
                    const SizedBox(width: 8),
                    TierChip(index: level.index),
                  ],
                ),
                const SizedBox(height: 3),
                Text(level.tagline,
                    style: TextStyle(color: C.muted, fontSize: 13, height: 1.35)),
                if (level.available) ...[
                  const SizedBox(height: 10),
                  ProgressLine(
                    value: total == 0 ? 0 : done / total,
                    color: done == total ? C.ok : C.accent,
                  ),
                  const SizedBox(height: 6),
                  Text(tr('modules_progress', {'done': done, 'total': total}), style: mono(size: 11)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (AppState.isProLevel(level.index) && !state.hasPro)
            MonoTag('PRO', color: C.accent, filled: true)
          else if (!level.available)
            const MonoTag('SOON', filled: true)
          else if (!unlocked)
            Icon(Icons.lock_outline_rounded, color: C.muted)
          else
            Icon(Icons.chevron_right_rounded, color: C.accent),
        ],
      ),
    );
  }
}

/// Label tingkat kesulitan level: Pemula, Menengah, Lanjut, Hard.
class TierChip extends StatelessWidget {
  const TierChip({super.key, required this.index});
  final int index;

  static int tierOf(int index) => index <= 1 ? 0 : (index <= 5 ? 1 : (index <= 9 ? 2 : 3));

  @override
  Widget build(BuildContext context) {
    final t = tierOf(index);
    final color = [C.ok, C.accent, C.orange, C.red][t];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(tr('tier_$t'), style: mono(size: 9.5, color: color, weight: FontWeight.w800, spacing: 0.6)),
    );
  }
}
