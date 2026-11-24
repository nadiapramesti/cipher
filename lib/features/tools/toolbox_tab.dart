import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/theme.dart';
import '../../widgets/common.dart';
import '../ctf/ctf_screen.dart';
import '../pro/paywall_screen.dart';
import '../sim/scam_sort_screen.dart';
import '../sim/terminal_screen.dart';
import 'network_info_screen.dart';
import 'password_checker_screen.dart';
import '../../l10n/strings.dart';

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

List<_Tool> get _tools => <_Tool>[
  _Tool(
    title: tr('tool_pw_title'),
    desc: tr('tool_pw_desc'),
    level: 0,
    icon: Icons.password_rounded,
    builder: (_) => const PasswordCheckerScreen(),
  ),
  _Tool(
    title: tr('ss_title'),
    desc: tr('ss_desc'),
    level: 0,
    icon: Icons.phishing,
    builder: (_) => const ScamSortScreen(),
  ),
  _Tool(
    title: tr('ctf_title'),
    desc: tr('ctf_desc'),
    level: 0,
    icon: Icons.emoji_flags_outlined,
    builder: (_) => const CtfScreen(),
  ),
  _Tool(
    title: tr('tm_title'),
    desc: tr('tm_desc'),
    level: 1,
    icon: Icons.terminal,
    builder: (_) => const TerminalScreen(),
  ),
  _Tool(
    title: tr('tool_net_title'),
    desc: tr('tool_net_desc'),
    level: 1,
    icon: Icons.lan_outlined,
    builder: (_) => const NetworkInfoScreen(),
  ),
  _Tool(
    title: tr('tool_url_title'),
    desc: tr('tool_url_desc'),
    level: 2,
    icon: Icons.link_rounded,
  ),
  _Tool(
    title: tr('tool_hash_title'),
    desc: tr('tool_hash_desc'),
    level: 3,
    icon: Icons.tag_rounded,
  ),
  _Tool(
    title: tr('tool_cipher_title'),
    desc: tr('tool_cipher_desc'),
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
        Text(tr('tb_title'),
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
        const SizedBox(height: 6),
        Text(
          tr('tb_sub'),
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
      borderColor: ready ? C.accent.withValues(alpha: 0.35) : C.line,
      onTap: () {
        if (AppState.isProLevel(tool.level) && !AppScope.read(context).isPro) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const PaywallScreen(reasonKey: 'pw_reason_tool'),
          ));
        } else if (!unlocked) {
          showInfo(context, tr('tb_locked', {'code': code}));
        } else if (tool.builder == null) {
          showInfo(context, tr('tb_soon', {'t': tool.title}));
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
              color: (ready ? C.accent : C.muted).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(tool.icon, color: ready ? C.accent : C.muted),
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
                    style: TextStyle(color: C.muted, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (!unlocked)
            MonoTag(code, filled: true)
          else if (tool.builder == null)
            const MonoTag('SOON', filled: true)
          else
            Icon(Icons.chevron_right_rounded, color: C.accent),
        ],
      ),
    );
  }
}
