import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/strings.dart';
import '../../widgets/common.dart';
import 'crypto_tools.dart';
import 'tool_bits.dart';

enum _Algo { caesar, vigenere }

class CipherScreen extends StatefulWidget {
  const CipherScreen({super.key});

  @override
  State<CipherScreen> createState() => _CipherScreenState();
}

class _CipherScreenState extends State<CipherScreen> {
  final _text = TextEditingController();
  final _key = TextEditingController(text: 'KUNCI');
  _Algo _algo = _Algo.caesar;
  bool _decrypt = false;
  int _shift = 3;
  bool _showBrute = false;

  @override
  void dispose() {
    _text.dispose();
    _key.dispose();
    super.dispose();
  }

  String get _output => switch (_algo) {
        _Algo.caesar => caesar(_text.text, _shift, decrypt: _decrypt),
        _Algo.vigenere => vigenere(_text.text, _key.text, decrypt: _decrypt),
      };

  @override
  Widget build(BuildContext context) {
    final empty = _text.text.isEmpty;
    final out = _output;
    final freq = letterFrequency(_decrypt ? _text.text : out);

    return Scaffold(
      appBar: AppBar(title: Text(tr('tool_cipher_title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          SegmentPicker<_Algo>(
            value: _algo,
            items: [(_Algo.caesar, 'Caesar'), (_Algo.vigenere, 'Vigenère')],
            onChanged: (a) => setState(() {
              _algo = a;
              _showBrute = false;
            }),
          ),
          const SizedBox(height: 10),
          SegmentPicker<bool>(
            value: _decrypt,
            items: [(false, tr('cp_encrypt')), (true, tr('cp_decrypt'))],
            onChanged: (d) => setState(() => _decrypt = d),
          ),
          const SizedBox(height: 16),
          if (_algo == _Algo.caesar)
            Panel(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: MonoTag(tr('cp_shift'))),
                    MonoTag('A → ${caesar('A', _shift)}', color: C.accent, filled: true),
                    const SizedBox(width: 8),
                  ]),
                  Slider(
                    value: _shift.toDouble(),
                    min: 1,
                    max: 25,
                    divisions: 24,
                    label: '$_shift',
                    onChanged: (v) => setState(() => _shift = v.round()),
                  ),
                ],
              ),
            )
          else
            TextField(
              controller: _key,
              onChanged: (_) => setState(() {}),
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.characters,
              keyboardType: TextInputType.text,
              style: mono(size: 15, color: C.text, spacing: 1),
              decoration: InputDecoration(labelText: tr('cp_key'), hintText: 'RAHASIA'),
            ),
          const SizedBox(height: 14),
          TextField(
            controller: _text,
            onChanged: (_) => setState(() {}),
            autocorrect: false,
            enableSuggestions: false,
            minLines: 2,
            maxLines: 5,
            style: mono(size: 14, color: C.text, spacing: 0),
            decoration: InputDecoration(
              labelText: tr(_decrypt ? 'cp_in_cipher' : 'cp_in_plain'),
              hintText: _decrypt ? 'KDOR GXQLD' : 'HALO DUNIA',
            ),
          ),
          const SizedBox(height: 16),
          if (empty)
            StateMessage(glyph: 'A→D', title: tr('cp_empty_title'), body: tr('cp_empty_body'))
          else ...[
            CopyRow(label: tr(_decrypt ? 'cp_out_plain' : 'cp_out_cipher'), value: out),
            if (freq.isNotEmpty) ...[
              const SizedBox(height: 4),
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MonoTag(tr('cp_freq')),
                    const SizedBox(height: 10),
                    for (final (l, pct) in freq)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(children: [
                          SizedBox(width: 22, child: Text(l, style: mono(size: 13, color: C.text, weight: FontWeight.w800))),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (pct / 100 * 2.5).clamp(0, 1).toDouble(),
                                minHeight: 8,
                                color: C.accent,
                                backgroundColor: C.line,
                              ),
                            ),
                          ),
                          SizedBox(width: 48, child: Text('${pct.toStringAsFixed(0)}%', textAlign: TextAlign.right, style: mono(size: 11))),
                        ]),
                      ),
                    const SizedBox(height: 8),
                    Text(tr('cp_freq_d'), style: TextStyle(fontSize: 12.5, color: C.muted, height: 1.4)),
                  ],
                ),
              ),
            ],
            if (_algo == _Algo.caesar && _showBrute) ...[
              const SizedBox(height: 14),
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MonoTag(tr('cp_brute_head')),
                    const SizedBox(height: 8),
                    for (final (s, t) in caesarBruteForce(_decrypt ? _text.text : out))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          SizedBox(width: 34, child: Text('-$s', style: mono(size: 11, color: s == _shift ? C.ok : C.muted))),
                          Expanded(
                            child: Text(t,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: mono(size: 12, color: s == _shift ? C.ok : C.text, spacing: 0)),
                          ),
                        ]),
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
              ChunkyButton.outline(
                onPressed: () => setState(() {
                  _text.clear();
                  _showBrute = false;
                }),
                child: Text(tr('clear')),
              ),
              if (_algo == _Algo.caesar)
                ChunkyButton(
                  onPressed: () => setState(() => _showBrute = !_showBrute),
                  child: Text(tr(_showBrute ? 'cp_brute_hide' : 'cp_brute')),
                ),
            ]),
    );
  }
}
