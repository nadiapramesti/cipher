import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../widgets/common.dart';
import 'password_strength.dart';

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
        StrengthLevel.lumayan => C.amber,
        StrengthLevel.kuat => C.teal,
        StrengthLevel.sangatKuat => C.mint,
      };

  @override
  Widget build(BuildContext context) {
    final r = _report;
    final color = _colorFor(r.level);
    final empty = r.level == StrengthLevel.kosong;

    return Scaffold(
      appBar: AppBar(title: const Text('Cek Kekuatan Password')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, size: 16, color: C.teal),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Dicek langsung di HP kamu. Gak disimpan, gak dikirim ke mana-mana.',
                  style: mono(size: 11, color: C.teal, spacing: 0.2),
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
            style: const TextStyle(fontFamily: kMono, fontSize: 16, letterSpacing: 0.5),
            decoration: InputDecoration(
              labelText: 'Password yang mau dicek',
              hintText: 'contoh: kucing-oren-makan-tahu-27',
              suffixIcon: IconButton(
                tooltip: _hidden ? 'Tampilkan' : 'Sembunyikan',
                onPressed: () => setState(() => _hidden = !_hidden),
                icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (empty)
            const StateMessage(
              glyph: '> _',
              title: 'Ketik password buat dicek',
              body: 'Pakai contoh di atas atau password karanganmu sendiri. Saran: jangan ketik password asli yang lagi kamu pakai, cukup yang mirip polanya.',
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
                  const Text('Perkiraan waktu dibobol komputer kencang',
                      style: TextStyle(color: C.muted, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(r.crackTime,
                      style: mono(size: 20, color: C.text, weight: FontWeight.w800, spacing: 0)),
                  const SizedBox(height: 2),
                  Text('asumsi 10 miliar tebakan per detik', style: mono(size: 10)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const MonoTag('// checklist'),
                  const SizedBox(height: 10),
                  for (final c in r.checks)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Icon(
                            c.ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            size: 18,
                            color: c.ok ? C.teal : C.muted,
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
                color: C.amber.withValues(alpha: 0.06),
                borderColor: C.amber.withValues(alpha: 0.35),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const MonoTag('SARAN', color: C.amber),
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
              OutlinedButton(onPressed: _clear, child: const Text('Kosongkan')),
            ]),
    );
  }
}
