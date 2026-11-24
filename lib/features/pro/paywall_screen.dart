import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/theme.dart';
import '../../l10n/strings.dart';
import '../../widgets/common.dart';
import 'pro_service.dart';

/// Layar Cipher Pro: bandingin Gratis vs Pro, beli, atau pulihkan pembelian.
class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key, this.reasonKey});

  /// Kunci teks alasan user nyampe sini (mis. level Pro diketuk).
  final String? reasonKey;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final pro = ProService.instance;

    return ListenableBuilder(
      listenable: pro,
      builder: (context, _) {
        final rows = <(String, String, String)>[
          (tr('pw_row_levels'), tr('pw_free_levels'), tr('pw_pro_levels')),
          (tr('pw_row_tools'), tr('pw_free_tools'), tr('pw_pro_tools')),
          (tr('pw_row_ctf'), tr('pw_free_ctf'), tr('pw_pro_ctf')),
          (tr('pw_row_cert'), '—', tr('pw_yes')),
          (tr('pw_row_ads'), tr('pw_none'), tr('pw_none')),
        ];

        Widget body;
        if (state.isPro) {
          body = StateMessage(glyph: 'PRO', color: C.ok, title: tr('pw_active_title'), body: tr('pw_active_body'));
        } else {
          body = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (reasonKey != null) ...[
                Panel(
                  color: C.accentTint,
                  borderColor: C.accentDeep,
                  child: Row(
                    children: [
                      Icon(Icons.lock_rounded, color: C.accent),
                      const SizedBox(width: 10),
                      Expanded(child: Text(tr(reasonKey!), style: TextStyle(height: 1.45, color: C.text))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: C.line),
                ),
                clipBehavior: Clip.antiAlias,
                child: Table(
                  columnWidths: const {0: FlexColumnWidth(1.3), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1.1)},
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: C.surface2),
                      children: [
                        _cell('', head: true),
                        _cell(tr('pw_free'), head: true),
                        _cell('PRO', head: true, accent: true),
                      ],
                    ),
                    for (final (label, free, paid) in rows)
                      TableRow(
                        decoration: BoxDecoration(border: Border(top: BorderSide(color: C.line))),
                        children: [_cell(label, muted: true), _cell(free), _cell(paid, accent: true)],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(tr('pw_note'), style: TextStyle(fontSize: 12.5, color: C.muted, height: 1.45)),
              if (pro.error != null) ...[
                const SizedBox(height: 12),
                StateMessage(glyph: '!!', color: C.red, title: tr('pw_err_title'), body: tr('pw_err_body')),
              ],
              if (!pro.loading && !pro.storeAvailable) ...[
                const SizedBox(height: 12),
                StateMessage(glyph: '[--]', title: tr('pw_store_off_title'), body: tr('pw_store_off_body')),
              ],
            ],
          );
        }

        final price = pro.product?.price;
        final canBuy = !state.isPro && !pro.loading && !pro.busy && pro.product != null;

        return Scaffold(
          appBar: AppBar(title: const Text('Cipher Pro')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: [
              Text(tr('pw_head'), style: display(size: 28)),
              const SizedBox(height: 8),
              Text(tr('pw_sub'), style: TextStyle(color: C.textSoft, height: 1.5)),
              const SizedBox(height: 18),
              body,
            ],
          ),
          bottomNavigationBar: state.isPro
              ? BottomActions(children: [
                  ChunkyButton(onPressed: () => Navigator.of(context).pop(), child: Text(tr('done'))),
                ])
              : BottomActions(children: [
                  ChunkyButton(
                    onPressed: canBuy ? pro.buy : null,
                    child: Text(pro.loading
                        ? tr('pw_loading')
                        : pro.busy
                            ? tr('pw_processing')
                            : price != null
                                ? tr('pw_buy', {'p': price})
                                : tr('pw_unavailable')),
                  ),
                  ChunkyButton.outline(
                    onPressed: pro.busy || !pro.storeAvailable ? null : pro.restore,
                    child: Text(tr('pw_restore')),
                  ),
                ]),
        );
      },
    );
  }

  Widget _cell(String text, {bool head = false, bool accent = false, bool muted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Text(
        text,
        style: head
            ? mono(size: 11.5, color: accent ? C.accent : C.muted, weight: FontWeight.w800)
            : TextStyle(
                fontSize: 13,
                height: 1.35,
                fontWeight: accent ? FontWeight.w700 : FontWeight.w500,
                color: accent ? C.text : (muted ? C.muted : C.textSoft),
              ),
      ),
    );
  }
}
