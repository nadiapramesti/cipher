import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/theme.dart';
import '../../core/models.dart';
import '../../l10n/strings.dart';
import '../../widgets/common.dart';
import '../learn/module_screen.dart';

class _Hit {
  const _Hit({required this.title, required this.where, required this.snippet, required this.open});
  final String title;
  final String where;
  final String snippet;
  final void Function(BuildContext) open;
}

/// Cari istilah / topik di semua modul + kamus sekaligus.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _snippet(String text, String q) {
    final flat = text.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ');
    final i = flat.toLowerCase().indexOf(q);
    if (i < 0) return flat.length > 110 ? '${flat.substring(0, 110)}…' : flat;
    final start = (i - 40).clamp(0, flat.length);
    final end = (i + q.length + 70).clamp(0, flat.length);
    return '${start > 0 ? '…' : ''}${flat.substring(start, end)}${end < flat.length ? '…' : ''}';
  }

  List<_Hit> _search(AppState s, String q) {
    final hits = <_Hit>[];
    for (final level in s.content.levels) {
      for (final m in s.content.modulesOf(level)) {
        final unlocked = s.isModuleUnlocked(m);
        for (var p = 0; p < m.pages.length; p++) {
          final page = m.pages[p];
          final hay = '${page.title}\n${page.body}\n${page.tip ?? ''}'.toLowerCase();
          if (m.title.toLowerCase().contains(q) || hay.contains(q)) {
            hits.add(_Hit(
              title: page.title,
              where: '${level.code} · ${m.title}',
              snippet: _snippet('${page.body} ${page.tip ?? ''}', q),
              open: (ctx) {
                if (!unlocked) {
                  showInfo(ctx, tr('mod_locked'));
                  return;
                }
                Navigator.of(ctx).push(MaterialPageRoute(
                  builder: (_) => ModuleScreen(module: m, initialPage: p),
                ));
              },
            ));
          }
        }
      }
    }
    for (final t in s.content.glossary) {
      if ('${t.term} ${t.short} ${t.analogy}'.toLowerCase().contains(q)) {
        hits.add(_Hit(
          title: t.term,
          where: tr('nav_glossary'),
          snippet: t.short,
          open: (ctx) => _showTerm(ctx, t),
        ));
      }
    }
    return hits;
  }

  void _showTerm(BuildContext context, GlossaryTerm t) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: C.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.term, style: mono(size: 18, color: C.accent, weight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(t.short, style: TextStyle(height: 1.5, color: C.text)),
              const SizedBox(height: 12),
              Panel(
                color: C.okTint,
                borderColor: C.okDeep,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MonoTag(tr('analogy'), color: C.ok),
                    const SizedBox(height: 6),
                    Text(t.analogy, style: TextStyle(height: 1.5, color: C.text)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ChunkyButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(tr('done'))),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final q = _q.trim().toLowerCase();
    final hits = q.length < 2 ? const <_Hit>[] : _search(s, q);

    return Scaffold(
      appBar: AppBar(title: Text(tr('search_title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            onChanged: (v) => setState(() => _q = v),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: tr('search_hint'),
              prefixIcon: Icon(Icons.search_rounded, color: C.muted),
            ),
          ),
          const SizedBox(height: 16),
          if (q.length < 2)
            StateMessage(glyph: '/?', title: tr('search_idle_title'), body: tr('search_idle_body'))
          else if (hits.isEmpty)
            StateMessage(glyph: '?_', title: tr('gl_none_title', {'q': _q.trim()}), body: tr('search_none_body'))
          else ...[
            MonoTag(tr('search_count', {'n': hits.length})),
            const SizedBox(height: 10),
            for (final h in hits)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Panel(
                  onTap: () => h.open(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(h.where, style: mono(size: 10.5, color: C.accent)),
                      const SizedBox(height: 4),
                      Text(h.title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: C.text)),
                      const SizedBox(height: 4),
                      Text(h.snippet, style: TextStyle(fontSize: 13, height: 1.4, color: C.muted)),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
