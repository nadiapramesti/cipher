import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/theme.dart';
import '../../widgets/common.dart';
import 'password_checker_screen.dart';

class _Tool {
  const _Tool({
    required this.title,
    required this.desc,
    required this.level,
    required this.icon,
    this.builder,
  });

  final String title;
  final String desc;
  final int level;
  final IconData icon;
  final WidgetBuilder? builder;
}

final _tools = <_Tool>[
  _Tool(
    title: 'Cek Kekuatan Password',
    desc: 'Lihat seberapa lama password kamu bisa dibobol, plus saran biar makin kuat.',
    level: 0,
    icon: Icons.password_rounded,
    builder: (_) => const PasswordCheckerScreen(),
  ),
  const _Tool(
    title: 'Info Jaringan',
    desc: 'Intip IP, DNS, dan tipe koneksi HP kamu sendiri.',
    level: 1,
    icon: Icons.lan_outlined,
  ),
  const _Tool(
    title: 'Inspektor URL',
    desc: 'Bongkar struktur link dan deteksi domain tiruan (look-alike).',
    level: 2,
    icon: Icons.link_rounded,
  ),
  const _Tool(
    title: 'Hash & Encode',
    desc: 'SHA-256, MD5, Base64, Hex. Lihat bedanya encoding sama hashing.',
    level: 3,
    icon: Icons.tag_rounded,
  ),
  const _Tool(
    title: 'Cipher Klasik',
    desc: 'Main-main Caesar & Vigenère, nenek moyang enkripsi modern.',
    level: 3,
    icon: Icons.key_rounded,
  ),
];

class ToolboxTab extends StatelessWidget {
  const ToolboxTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        const Text('Toolbox',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
        const SizedBox(height: 6),
        const Text(
          'Alat praktek yang kebuka seiring level kamu naik. Semua jalan offline dan cuma ngolah input kamu sendiri.',
          style: TextStyle(color: C.muted, height: 1.45),
        ),
        const SizedBox(height: 20),
        for (final tool in _tools)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ToolCard(
              tool: tool,
              unlocked: state.isLevelIndexUnlocked(tool.level),
            ),
          ),
      ],
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.tool, required this.unlocked});

  final _Tool tool;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final ready = unlocked && tool.builder != null;
    final code = 'LV.${tool.level.toString().padLeft(2, '0')}';

    return Panel(
      color: ready ? C.surface : C.bg,
      borderColor: ready ? C.amber.withValues(alpha: 0.35) : C.line,
      onTap: () {
        if (!unlocked) {
          showInfo(context, 'Tool ini kebuka setelah kamu sampai $code.');
        } else if (tool.builder == null) {
          showInfo(context, '${tool.title} lagi dibikin. Segera hadir!');
        } else {
          Navigator.of(context).push(MaterialPageRoute(builder: tool.builder!));
        }
      },
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: (ready ? C.amber : C.muted).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(tool.icon, color: ready ? C.amber : C.muted),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tool.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: ready ? C.text : C.muted,
                    )),
                const SizedBox(height: 3),
                Text(tool.desc,
                    style: const TextStyle(color: C.muted, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (!unlocked)
            MonoTag(code, filled: true)
          else if (tool.builder == null)
            const MonoTag('SOON', filled: true)
          else
            const Icon(Icons.chevron_right_rounded, color: C.amber),
        ],
      ),
    );
  }
}
