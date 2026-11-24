import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/strings.dart';
import '../../widgets/common.dart';
import 'crypto_tools.dart';
import 'tool_bits.dart';

enum _Mode { encode, decode }

class HashScreen extends StatefulWidget {
  const HashScreen({super.key});

  @override
  State<HashScreen> createState() => _HashScreenState();
}

class _HashScreenState extends State<HashScreen> {
  final _controller = TextEditingController();
  _Mode _mode = _Mode.encode;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = _controller.text;
    final empty = text.isEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(tr('tool_hash_title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          const OfflineNote(),
          const SizedBox(height: 14),
          SegmentPicker<_Mode>(
            value: _mode,
            items: [(_Mode.encode, tr('hs_mode_enc')), (_Mode.decode, tr('hs_mode_dec'))],
            onChanged: (m) => setState(() => _mode = m),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            onChanged: (_) => setState(() {}),
            autocorrect: false,
            enableSuggestions: false,
            minLines: 2,
            maxLines: 5,
            style: mono(size: 14, color: C.text, spacing: 0),
            decoration: InputDecoration(
              labelText: tr(_mode == _Mode.encode ? 'hs_label_enc' : 'hs_label_dec'),
              hintText: _mode == _Mode.encode ? 'halo cipher' : 'Q0lQSEVSe2I0czM2NF9idWthbl9lbmtyaXBzaX0=',
            ),
          ),
          const SizedBox(height: 16),
          if (empty)
            StateMessage(
              glyph: '#',
              title: tr(_mode == _Mode.encode ? 'hs_empty_enc' : 'hs_empty_dec'),
              body: tr(_mode == _Mode.encode ? 'hs_empty_enc_d' : 'hs_empty_dec_d'),
            )
          else if (_mode == _Mode.encode) ...[
            MonoTag(tr('hs_hashes')),
            const SizedBox(height: 8),
            CopyRow(label: 'SHA-256', value: sha256Hex(text)),
            CopyRow(label: 'SHA-1', value: sha1Hex(text), color: C.orange),
            CopyRow(label: 'MD5', value: md5Hex(text), color: C.red),
            const SizedBox(height: 4),
            MonoTag(tr('hs_encodings')),
            const SizedBox(height: 8),
            CopyRow(label: 'Base64', value: toBase64(text), color: C.ok),
            CopyRow(label: 'Hex', value: toHex(text), color: C.ok),
            const SizedBox(height: 6),
            _Explain(tr('hs_explain')),
          ] else ...[
            _decoded('Base64', fromBase64(text)),
            _decoded('Hex', fromHex(text)),
            const SizedBox(height: 6),
            _Explain(tr('hs_explain_dec')),
          ],
        ],
      ),
      bottomNavigationBar: empty
          ? null
          : BottomActions(children: [
              ChunkyButton.outline(
                onPressed: () => setState(_controller.clear),
                child: Text(tr('clear')),
              ),
            ]),
    );
  }

  Widget _decoded(String label, String? value) => value == null
      ? Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Panel(
            color: C.bg,
            child: Row(children: [
              MonoTag(label),
              const SizedBox(width: 10),
              Expanded(child: Text(tr('hs_not_valid', {'f': label}), style: TextStyle(color: C.muted, fontSize: 13))),
            ]),
          ),
        )
      : CopyRow(label: label, value: value, color: C.ok);
}

class _Explain extends StatelessWidget {
  const _Explain(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Panel(
      color: C.accent.withValues(alpha: 0.06),
      borderColor: C.accent.withValues(alpha: 0.35),
      child: Text(text, style: const TextStyle(height: 1.5, fontSize: 13.5)),
    );
  }
}
