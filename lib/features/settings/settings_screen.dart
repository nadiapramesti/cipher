import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/theme.dart';
import '../../l10n/strings.dart';
import '../../widgets/common.dart';
import '../../services/reminder_service.dart';
import 'backup_screens.dart';

/// Pengaturan tampilan & bahasa. Semua pilihan langsung kepakai dan tersimpan.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(tr('settings'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          MonoTag(tr('set_tag'), color: C.accent),
          const SizedBox(height: 18),
          _SectionTitle(tr('set_language')),
          Row(
            children: [
              Expanded(
                child: _Choice(
                  selected: state.lang == AppLang.id,
                  badge: 'ID',
                  label: 'Bahasa Indonesia',
                  onTap: () => state.setLang(AppLang.id),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Choice(
                  selected: state.lang == AppLang.en,
                  badge: 'EN',
                  label: 'English',
                  onTap: () => state.setLang(AppLang.en),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          _SectionTitle(tr('set_mode')),
          Row(
            children: [
              for (final (mode, icon, key) in const [
                (AppThemeMode.dark, Icons.dark_mode_rounded, 'mode_dark'),
                (AppThemeMode.light, Icons.light_mode_rounded, 'mode_light'),
                (AppThemeMode.system, Icons.phone_android_rounded, 'mode_system'),
              ]) ...[
                if (mode != AppThemeMode.dark) const SizedBox(width: 10),
                Expanded(
                  child: _Choice(
                    selected: state.themeMode == mode,
                    icon: icon,
                    label: tr(key),
                    vertical: true,
                    onTap: () => state.setThemeMode(mode),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 26),
          _SectionTitle(tr('set_theme')),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.92,
            children: [
              for (final accent in ThemeAccent.values)
                _ThemeCard(
                  accent: accent,
                  selected: state.accent == accent,
                  onTap: () => state.setAccent(accent),
                ),
            ],
          ),
          const SizedBox(height: 26),
          _SectionTitle(tr('rm_title')),
          Row(
            children: [
              Expanded(
                child: _Choice(
                  selected: !state.reminderOn,
                  icon: Icons.notifications_off_outlined,
                  label: tr('rm_off'),
                  onTap: () => _setReminder(context, on: false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Choice(
                  selected: state.reminderOn,
                  icon: Icons.notifications_active_outlined,
                  label: tr('rm_on'),
                  onTap: () => _setReminder(context, on: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ActionRow(
            icon: Icons.schedule_rounded,
            title: tr('rm_time', {
              't': '${state.reminderHour.toString().padLeft(2, '0')}:${state.reminderMinute.toString().padLeft(2, '0')}'
            }),
            desc: tr('rm_time_desc'),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: state.reminderHour, minute: state.reminderMinute),
              );
              if (picked == null || !context.mounted) return;
              await _setReminder(context, on: true, time: picked);
            },
          ),
          const SizedBox(height: 26),
          _SectionTitle(tr('set_progress')),
          _ActionRow(
            icon: Icons.upload_rounded,
            title: tr('bk_export_title'),
            desc: tr('bk_export_desc'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ExportBackupScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _ActionRow(
            icon: Icons.download_rounded,
            title: tr('bk_import_title'),
            desc: tr('bk_import_desc'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ImportBackupScreen()),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.cloud_done_outlined, size: 16, color: C.ok),
              const SizedBox(width: 6),
              Expanded(child: Text(tr('set_auto_backup'), style: TextStyle(fontSize: 12.5, height: 1.45, color: C.muted))),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, size: 16, color: C.ok),
              const SizedBox(width: 6),
              Expanded(child: Text(tr('set_saved'), style: mono(size: 11, color: C.muted))),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomActions(children: [
        ChunkyButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(tr('done')),
        ),
      ]),
    );
  }
}

/// Nyalain / matiin / ubah jam pengingat, sekalian jadwalin notifikasinya.
Future<void> _setReminder(BuildContext context, {required bool on, TimeOfDay? time}) async {
  final state = AppScope.read(context);
  final svc = ReminderService.instance;
  if (!on) {
    await svc.cancel();
    await state.setReminder(on: false);
    return;
  }
  final allowed = await svc.requestPermission();
  if (!allowed) {
    if (context.mounted) showInfo(context, tr('rm_denied'));
    await state.setReminder(on: false);
    return;
  }
  await state.setReminder(on: true, hour: time?.hour, minute: time?.minute);
  await svc.scheduleDaily(
    hour: state.reminderHour,
    minute: state.reminderMinute,
    title: tr('rm_notif_title'),
    body: tr('rm_notif_body'),
    channelName: tr('rm_channel'),
  );
  if (context.mounted) {
    showInfo(context, tr('rm_set', {
      't': '${state.reminderHour.toString().padLeft(2, '0')}:${state.reminderMinute.toString().padLeft(2, '0')}'
    }));
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.icon, required this.title, required this.desc, required this.onTap});

  final IconData icon;
  final String title;
  final String desc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Panel(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: C.accentTint, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: C.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: C.text)),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(fontSize: 12.5, color: C.muted, height: 1.35)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: C.accent),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text, style: display(size: 18)),
      );
}

/// Pilihan berbentuk kartu tombol; yang aktif diberi garis aksen + centang.
class _Choice extends StatelessWidget {
  const _Choice({
    required this.selected,
    required this.label,
    required this.onTap,
    this.badge,
    this.icon,
    this.vertical = false,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;
  final String? badge;
  final IconData? icon;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? C.accent : C.textSoft;
    final lead = badge != null
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: selected ? C.accent : C.surface2,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badge!,
              style: mono(size: 11, color: selected ? C.onAccent : C.muted, weight: FontWeight.w800),
            ),
          )
        : Icon(icon, color: fg, size: 22);

    final text = Text(
      label,
      textAlign: vertical ? TextAlign.center : TextAlign.start,
      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: selected ? C.text : C.textSoft),
    );

    return Semantics(
      selected: selected,
      button: true,
      child: Panel(
        onTap: onTap,
        color: selected ? C.accentTint : C.surface,
        borderColor: selected ? C.accent : C.line,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: vertical
            ? Column(children: [lead, const SizedBox(height: 8), text])
            : Row(children: [lead, const SizedBox(width: 10), Expanded(child: text)]),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({required this.accent, required this.selected, required this.onTap});

  final ThemeAccent accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = paletteFor(accent, dark: C.isDark);
    final name = tr('th_${accent.name}');
    final desc = tr('th_${accent.name}_d');

    return Semantics(
      selected: selected,
      button: true,
      label: name,
      child: Panel(
        onTap: onTap,
        color: selected ? C.accentTint : C.surface,
        borderColor: selected ? C.accent : C.line,
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // pratinjau mini: latar, kartu, tombol aksen, status "benar"
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: p.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: p.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 8,
                      width: 46,
                      decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(3)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 6,
                      width: 70,
                      decoration: BoxDecoration(color: p.muted.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(3)),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 18,
                            decoration: BoxDecoration(
                              color: p.accent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border(bottom: BorderSide(color: p.accentDeep, width: 3)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          height: 18,
                          width: 18,
                          decoration: BoxDecoration(color: p.ok, borderRadius: BorderRadius.circular(5)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: C.text),
                  ),
                ),
                if (selected) Icon(Icons.check_circle_rounded, size: 18, color: C.accent),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, height: 1.3, color: C.muted),
            ),
          ],
        ),
      ),
    );
  }
}
