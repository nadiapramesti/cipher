import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/theme.dart';
import '../../l10n/strings.dart';
import '../../widgets/common.dart';
import 'flags.dart';

/// Papan Mini CTF: daftar tantangan + kotak buat ngirim flag.
class CtfScreen extends StatefulWidget {
  const CtfScreen({super.key});

  @override
  State<CtfScreen> createState() => _CtfScreenState();
}

class _CtfScreenState extends State<CtfScreen> {
  final _input = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final s = AppScope.read(context);
    final hit = matchFlag(_input.text);
    if (hit == null) {
      setState(() => _error = tr('ctf_wrong'));
      return;
    }
    if (s.flags.contains(hit.id)) {
      setState(() => _error = tr('ctf_already'));
      return;
    }
    await s.captureFlag(hit.id);
    if (!mounted) return;
    _input.clear();
    setState(() => _error = null);
    showInfo(context, tr('ctf_ok', {'t': tr('ctf_${hit.id}')}));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final got = ctfChallenges.where((c) => s.flags.contains(c.id)).length;

    return Scaffold(
      appBar: AppBar(title: Text(tr('ctf_title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(tr('ctf_lead'), style: TextStyle(color: C.textSoft, height: 1.45)),
          const SizedBox(height: 12),
          ProgressLine(value: got / ctfChallenges.length, color: C.ok),
          const SizedBox(height: 6),
          Text(tr('ctf_progress', {'n': got, 't': ctfChallenges.length}), style: mono(size: 11)),
          const SizedBox(height: 16),
          for (final c in ctfChallenges)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Panel(
                color: s.flags.contains(c.id) ? C.okTint : C.surface,
                borderColor: s.flags.contains(c.id) ? C.okDeep : C.line,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(s.flags.contains(c.id) ? Icons.flag_rounded : Icons.outlined_flag_rounded,
                        color: s.flags.contains(c.id) ? C.ok : C.muted),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr('ctf_${c.id}'), style: TextStyle(fontWeight: FontWeight.w800, color: C.text)),
                          const SizedBox(height: 4),
                          if (c.id == 'base64') ...[
                            Text(tr('ctf_base64_d'), style: TextStyle(fontSize: 13, height: 1.4, color: C.muted)),
                            const SizedBox(height: 6),
                            SelectableText(Flags.base64Clue,
                                style: mono(size: 12, color: C.accent, weight: FontWeight.w700, spacing: 0)),
                          ] else
                            Text(tr('ctf_${c.id}_d'), style: TextStyle(fontSize: 13, height: 1.4, color: C.muted)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    MonoTag('+25 XP', color: s.flags.contains(c.id) ? C.ok : C.muted, filled: true),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _input,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.visiblePassword,
            onChanged: (_) => setState(() => _error = null),
            onSubmitted: (_) => _submit(),
            style: mono(size: 14, color: C.text, spacing: 0),
            decoration: InputDecoration(
              labelText: tr('ctf_field'),
              hintText: 'CIPHER{...}',
              errorText: _error,
              prefixIcon: Icon(Icons.flag_outlined, color: C.muted),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomActions(children: [
        ChunkyButton(
          onPressed: _input.text.trim().isEmpty ? null : _submit,
          child: Text(tr('ctf_submit')),
        ),
      ]),
    );
  }
}
