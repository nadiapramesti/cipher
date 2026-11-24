import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/theme.dart';
import '../../core/models.dart';
import '../../widgets/common.dart';
import '../../l10n/strings.dart';

class GlossaryTab extends StatefulWidget {
  const GlossaryTab({super.key});

  @override
  State<GlossaryTab> createState() => _GlossaryTabState();
}

class _GlossaryTabState extends State<GlossaryTab> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = AppScope.of(context).content.glossary;
    final q = _query.trim().toLowerCase();
    final items = q.isEmpty
        ? all
        : all
            .where((t) =>
                t.term.toLowerCase().contains(q) || t.short.toLowerCase().contains(q))
            .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(tr('gl_title'),
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
            ),
            MonoTag(tr('gl_count', {'n': all.length})),
          ],
        ),
        const SizedBox(height: 6),
        Text(tr('gl_sub'),
            style: TextStyle(color: C.muted)),
        const SizedBox(height: 16),
        TextField(
          controller: _search,
          onChanged: (v) => setState(() => _query = v),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: tr('gl_hint'),
            prefixIcon: Icon(Icons.search_rounded, color: C.muted),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: tr('gl_clear'),
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _search.clear();
                      setState(() => _query = '');
                    },
                  ),
          ),
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          StateMessage(
            glyph: '?_',
            title: tr('gl_none_title', {'q': _query.trim()}),
            body: tr('gl_none_body'),
          )
        else
          for (final t in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TermCard(term: t),
            ),
      ],
    );
  }
}

class _TermCard extends StatefulWidget {
  const _TermCard({required this.term});

  final GlossaryTerm term;

  @override
  State<_TermCard> createState() => _TermCardState();
}

class _TermCardState extends State<_TermCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.term;
    return Panel(
      onTap: () => setState(() => _open = !_open),
      borderColor: _open ? C.accent.withValues(alpha: 0.45) : C.line,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(t.term,
                    style: mono(size: 15, color: C.accent, weight: FontWeight.w800, spacing: 0.3)),
              ),
              AnimatedRotation(
                turns: _open ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(Icons.expand_more_rounded, color: C.muted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(t.short, style: const TextStyle(height: 1.5)),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: !_open
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: C.ok.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: C.ok.withValues(alpha: 0.35)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MonoTag(tr('analogy'), color: C.ok),
                          const SizedBox(height: 6),
                          Text(t.analogy, style: const TextStyle(height: 1.5)),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
