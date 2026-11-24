import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../widgets/common.dart';
import 'password_strength.dart';
import '../../l10n/strings.dart';

class PasswordCheckerScreen extends StatefulWidget {
  const PasswordCheckerScreen({super.key});

  @override
  State<PasswordCheckerScreen> createState() => _PasswordCheckerScreenState();
}

class _PasswordCheckerScreenState extends State<PasswordCheckerScreen> {
  final _controller = TextEditingController();
  bool _hidden = true;
  PasswordReport _report = const PasswordReport.empty();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) => setState(() => _report = analyzePassword(value));

  void _clear() {
    _controller.clear();
    _onChanged('');
  }

  Color _colorFor(StrengthLevel l) => switch (l) {
        StrengthLevel.kosong => C.line,
        StrengthLevel.sangatLemah => C.red,
        StrengthLevel.lemah => C.orange,
        StrengthLevel.lumayan => C.yellow,
        StrengthLevel.kuat => C.ok,
        StrengthLevel.sangatKuat => C.mint,
      };

  @override
  Widget build(BuildContext context) {
    final r = _report;
    final color = _colorFor(r.level);
    final empty = r.level == StrengthLevel.kosong;

    return Scaffold(
      appBar: AppBar(title: Text(tr('pw_title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, size: 16, color: C.ok),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  tr('pw_private'),
                  style: mono(size: 11, color: C.ok, spacing: 0.2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            onChanged: _onChanged,
            obscureText: _hidden,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.visiblePassword,
            style: const TextStyle(
              fontFamily: kMono,
              fontSize: 15,
              fontVariations: [FontVariation('wght', 500)],
            ),
            decoration: InputDecoration(
              labelText: tr('pw_label'),
              hintText: tr('pw_hint'),
              suffixIcon: IconButton(
                tooltip: _hidden ? tr('show') : tr('hide'),
                onPressed: () => setState(() => _hidden = !_hidden),
                icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (empty)
            StateMessage(
              glyph: '> _',
              title: tr('pw_empty_title'),
              body: tr('pw_empty_body'),
            )
          else ...[
            Panel(
              borderColor: color.withValues(alpha: 0.5),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      for (var i = 1; i <= 5; i++) ...[
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            height: 8,
                            decoration: BoxDecoration(
                              color: i <= r.level.bars ? color : C.line,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        if (i < 5) const SizedBox(width: 6),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(r.level.label,
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
                      ),
                      MonoTag('~${r.entropyBits.round()} bit', color: color, filled: true),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(tr('pw_crack'),
                      style: TextStyle(color: C.muted, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(r.crackTime,
                      style: mono(size: 20, color: C.text, weight: FontWeight.w800, spacing: 0)),
                  const SizedBox(height: 2),
                  Text(tr('pw_assume'), style: mono(size: 10)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MonoTag(tr('checklist')),
                  const SizedBox(height: 10),
                  for (final c in r.checks)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Icon(
                            c.ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            size: 18,
                            color: c.ok ? C.ok : C.muted,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(c.label,
                                style: TextStyle(color: c.ok ? C.text : C.muted)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (r.tips.isNotEmpty) ...[
              const SizedBox(height: 14),
              Panel(
                color: C.accent.withValues(alpha: 0.06),
                borderColor: C.accent.withValues(alpha: 0.35),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MonoTag(tr('tips'), color: C.accent),
                    const SizedBox(height: 8),
                    for (final t in r.tips)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text('· $t', style: const TextStyle(height: 1.5)),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
      bottomNavigationBar: empty
          ? null
          : BottomActions(children: [
              ChunkyButton.outline(onPressed: _clear, child: Text(tr('clear'))),
            ]),
    );
  }
}
