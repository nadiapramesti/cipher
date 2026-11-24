import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../l10n/strings.dart';
import '../../widgets/common.dart';

class CheatGroup {
  const CheatGroup(this.title, this.items);
  final String title;
  final List<(String cmd, String desc)> items;
}

Future<List<CheatGroup>> loadCheatsheet() async {
  final dir = L.lang == AppLang.en ? 'en' : 'id';
  final raw = jsonDecode(await rootBundle.loadString('assets/content/$dir/cheatsheet.json')) as List;
  return [
    for (final g in raw.cast<Map<String, dynamic>>())
      CheatGroup(g['group'] as String, [
        for (final i in (g['items'] as List).cast<Map<String, dynamic>>()) (i['cmd'] as String, i['desc'] as String),
      ]),
  ];
}

class CheatsheetScreen extends StatefulWidget {
  const CheatsheetScreen({super.key});

  @override
  State<CheatsheetScreen> createState() => _CheatsheetScreenState();
}

class _CheatsheetScreenState extends State<CheatsheetScreen> {
  late final Future<List<CheatGroup>> _data = loadCheatsheet();
  final _search = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('tool_cheat_title'))),
      body: FutureBuilder<List<CheatGroup>>(
        future: _data,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final q = _q.toLowerCase();
          final groups = [
            for (final g in snap.data!)
              CheatGroup(g.title, [
                for (final i in g.items)
                  if (q.isEmpty || i.$1.toLowerCase().contains(q) || i.$2.toLowerCase().contains(q)) i,
              ]),
          ].where((g) => g.items.isNotEmpty).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Panel(
                color: C.orange.withValues(alpha: 0.08),
                borderColor: C.orange.withValues(alpha: 0.5),
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  Icon(Icons.gavel_rounded, size: 18, color: C.orange),
                  const SizedBox(width: 10),
                  Expanded(child: Text(tr('cs_ethics'), style: const TextStyle(fontSize: 12.5, height: 1.4))),
                ]),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _search,
                onChanged: (v) => setState(() => _q = v.trim()),
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: tr('cs_search'),
                  hintText: 'nmap, base64, dns',
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 16),
              if (groups.isEmpty)
                StateMessage(glyph: r'$ ?', title: tr('cs_none'), body: tr('cs_none_d'))
              else
                for (final g in groups) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 4),
                    child: Row(children: [
                      Expanded(child: Text(g.title, style: display(size: 18))),
                      MonoTag('${g.items.length}', color: C.accent, filled: true),
                    ]),
                  ),
                  for (final (cmd, desc) in g.items) _CmdTile(cmd: cmd, desc: desc),
                  const SizedBox(height: 10),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _CmdTile extends StatelessWidget {
  const _CmdTile({required this.cmd, required this.desc});
  final String cmd;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Panel(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        onTap: () {
          Clipboard.setData(ClipboardData(text: cmd));
          HapticFeedback.selectionClick();
          showInfo(context, tr('copied'));
        },
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r'$ ' + cmd, style: mono(size: 13, color: C.text, weight: FontWeight.w700, spacing: 0)),
                  const SizedBox(height: 4),
                  Text(desc, style: TextStyle(fontSize: 12.5, color: C.muted, height: 1.35)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.copy_rounded, size: 18, color: C.accent),
          ],
        ),
      ),
    );
  }
}
