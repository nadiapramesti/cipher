import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/strings.dart';
import '../../widgets/common.dart';
import 'tool_bits.dart';
import 'url_inspect.dart';

class UrlInspectorScreen extends StatefulWidget {
  const UrlInspectorScreen({super.key});

  @override
  State<UrlInspectorScreen> createState() => _UrlInspectorScreenState();
}

class _UrlInspectorScreenState extends State<UrlInspectorScreen> {
  final _controller = TextEditingController();
  UrlReport _r = const UrlReport(valid: false);

  static const _examples = [
    'https://www.bca.co.id/id/individu',
    'http://bca-hadiah-resmi.xyz/klaim?hp=0812',
    'https://login.bca.co.id.verifikasi-akun.top/',
    'https://shopee-promo.click/undian.apk',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _run(String v) => setState(() => _r = analyzeUrl(v));

  void _fill(String v) {
    _controller.text = v;
    _run(v);
  }

  Color _riskColor(UrlRisk r) => switch (r) { UrlRisk.danger => C.red, UrlRisk.warn => C.orange, UrlRisk.info => C.muted };

  @override
  Widget build(BuildContext context) {
    final r = _r;
    final empty = _controller.text.trim().isEmpty;
    final verdictColor = [C.ok, C.orange, C.red][r.verdict];

    return Scaffold(
      appBar: AppBar(title: Text(tr('tool_url_title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          const OfflineNote(),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            onChanged: _run,
            keyboardType: TextInputType.url,
            autocorrect: false,
            enableSuggestions: false,
            maxLines: 3,
            minLines: 1,
            style: mono(size: 14, color: C.text, spacing: 0),
            decoration: InputDecoration(labelText: tr('ui_label'), hintText: 'https://contoh.com/login?id=12'),
          ),
          const SizedBox(height: 16),
          if (empty) ...[
            StateMessage(glyph: '://', title: tr('ui_empty_title'), body: tr('ui_empty_body')),
            const SizedBox(height: 12),
            MonoTag(tr('ui_try')),
            const SizedBox(height: 8),
            for (final e in _examples)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Panel(
                  onTap: () => _fill(e),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(child: Text(e, style: mono(size: 12, color: C.text, spacing: 0))),
                      Icon(Icons.north_west_rounded, size: 18, color: C.accent),
                    ],
                  ),
                ),
              ),
          ] else if (!r.valid)
            StateMessage(glyph: '?!', title: tr('ui_invalid_title'), body: tr('ui_invalid_body'), color: C.orange)
          else ...[
            Panel(
              borderColor: verdictColor.withValues(alpha: 0.6),
              color: verdictColor.withValues(alpha: 0.08),
              child: Row(
                children: [
                  Icon([Icons.verified_outlined, Icons.error_outline_rounded, Icons.gpp_bad_outlined][r.verdict],
                      color: verdictColor, size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('ui_v${r.verdict}'),
                            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: verdictColor)),
                        const SizedBox(height: 2),
                        Text(tr('ui_v${r.verdict}_d'), style: TextStyle(fontSize: 12.5, color: C.muted, height: 1.35)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MonoTag(tr('ui_parts')),
                  const SizedBox(height: 10),
                  _Part(tr('ui_p_scheme'), r.scheme.isEmpty ? '—' : r.scheme),
                  if (r.subdomain.isNotEmpty) _Part(tr('ui_p_sub'), r.subdomain),
                  _Part(tr('ui_p_domain'), r.domain, strong: true),
                  _Part(tr('ui_p_path'), r.path),
                  for (final (k, v) in r.params) _Part('?$k', v),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(tr('ui_domain_hint', {'d': r.domain}), style: TextStyle(fontSize: 12.5, color: C.muted, height: 1.4)),
            ),
            const SizedBox(height: 14),
            if (r.findings.isNotEmpty)
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MonoTag(tr('ui_findings')),
                    const SizedBox(height: 8),
                    for (final f in r.findings)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              f.risk == UrlRisk.info ? Icons.info_outline_rounded : Icons.warning_amber_rounded,
                              size: 18,
                              color: _riskColor(f.risk),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(tr(f.key, f.args), style: const TextStyle(height: 1.45))),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            Text(tr('ui_disclaimer'), style: mono(size: 10.5)),
          ],
        ],
      ),
      bottomNavigationBar: empty
          ? null
          : BottomActions(children: [
              ChunkyButton.outline(
                onPressed: () {
                  _controller.clear();
                  _run('');
                },
                child: Text(tr('clear')),
              ),
            ]),
    );
  }
}

class _Part extends StatelessWidget {
  const _Part(this.label, this.value, {this.strong = false});
  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 92, child: Text(label, style: mono(size: 11))),
          Expanded(
            child: Text(
              value,
              style: mono(size: strong ? 14 : 12.5, color: strong ? C.accent : C.text, weight: strong ? FontWeight.w800 : FontWeight.w500, spacing: 0),
            ),
          ),
        ],
      ),
    );
  }
}
