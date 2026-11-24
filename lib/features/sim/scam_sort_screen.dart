import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/theme.dart';
import '../../core/models.dart';
import '../../l10n/strings.dart';
import '../../widgets/common.dart';
import '../ctf/flags.dart';

/// Simulasi "Tebak Penipuan": baca pesan, tentukan asli atau penipuan.
class ScamSortScreen extends StatefulWidget {
  const ScamSortScreen({super.key});

  @override
  State<ScamSortScreen> createState() => _ScamSortScreenState();
}

class _ScamSortScreenState extends State<ScamSortScreen> {
  late final List<ScamItem> _items = AppScope.read(context).content.scams;
  int _index = 0;
  bool? _answer; // true = dibilang penipuan
  int _correct = 0;
  bool _done = false;

  void _choose(bool saysScam) {
    if (_answer != null) return;
    setState(() {
      _answer = saysScam;
      if (saysScam == _items[_index].scam) _correct++;
    });
  }

  Future<void> _next() async {
    if (_index + 1 < _items.length) {
      setState(() {
        _index++;
        _answer = null;
      });
      return;
    }
    final percent = (_correct * 100 / _items.length).round();
    await AppScope.read(context).bumpMax('scamBest', percent);
    if (!mounted) return;
    setState(() => _done = true);
  }

  IconData _channelIcon(String ch) => switch (ch.toLowerCase()) {
        'sms' => Icons.sms_outlined,
        'email' => Icons.mail_outline_rounded,
        _ => Icons.chat_bubble_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(tr('ss_title'))),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: StateMessage(glyph: '[ ]', title: tr('ss_title'), body: tr('quiz_empty_body')),
        ),
      );
    }

    if (_done) {
      final percent = (_correct * 100 / _items.length).round();
      final perfect = _correct == _items.length;
      return Scaffold(
        appBar: AppBar(title: Text(tr('ss_title'))),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Panel(
              padding: const EdgeInsets.all(22),
              borderColor: (perfect ? C.ok : C.accent).withValues(alpha: 0.6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$percent%', style: mono(size: 56, color: perfect ? C.ok : C.accent, weight: FontWeight.w800, spacing: -1)),
                  Text(tr('ss_score', {'c': _correct, 't': _items.length}), style: TextStyle(color: C.muted)),
                  const SizedBox(height: 14),
                  Text(perfect ? tr('ss_perfect') : tr('ss_try_again'), style: TextStyle(height: 1.5, color: C.text)),
                ],
              ),
            ),
            if (perfect) ...[
              const SizedBox(height: 12),
              _FlagReveal(flag: Flags.scam),
            ],
          ],
        ),
        bottomNavigationBar: BottomActions(children: [
          ChunkyButton(onPressed: () => Navigator.of(context).pop(), child: Text(tr('done'))),
          ChunkyButton.outline(
            onPressed: () => setState(() {
              _index = 0;
              _answer = null;
              _correct = 0;
              _done = false;
            }),
            child: Text(tr('ss_replay')),
          ),
        ]),
      );
    }

    final item = _items[_index];
    final answered = _answer != null;
    final right = answered && _answer == item.scam;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('ss_title')),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(child: Text('${_index + 1}/${_items.length}', style: mono(color: C.accent))),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(tr('ss_question'), style: TextStyle(color: C.textSoft, height: 1.4)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: C.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: C.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_channelIcon(item.channel), size: 16, color: C.muted),
                    const SizedBox(width: 6),
                    Text(item.channel, style: mono(size: 11)),
                    const Spacer(),
                    Flexible(
                      child: Text(item.sender,
                          overflow: TextOverflow.ellipsis, style: mono(size: 11, color: C.textSoft)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: C.surface2,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                      topLeft: Radius.circular(4),
                    ),
                  ),
                  child: Text(item.text, style: TextStyle(fontSize: 15, height: 1.5, color: C.text)),
                ),
              ],
            ),
          ),
          if (answered) ...[
            const SizedBox(height: 14),
            Panel(
              color: (right ? C.ok : C.red).withValues(alpha: 0.08),
              borderColor: (right ? C.ok : C.red).withValues(alpha: 0.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${right ? tr('correct') : tr('not_quite')} ${item.scam ? tr('ss_is_scam') : tr('ss_is_real')}',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: right ? C.ok : C.red),
                  ),
                  const SizedBox(height: 6),
                  Text(item.why, style: TextStyle(height: 1.5, color: C.text)),
                ],
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: BottomActions(children: [
        if (!answered)
          Row(
            children: [
              Expanded(
                child: ChunkyButton.outline(
                  onPressed: () => _choose(false),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.verified_outlined),
                    const SizedBox(width: 6),
                    Text(tr('ss_real')),
                  ]),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChunkyButton(
                  onPressed: () => _choose(true),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.report_outlined),
                    const SizedBox(width: 6),
                    Text(tr('ss_scam')),
                  ]),
                ),
              ),
            ],
          )
        else
          ChunkyButton(
            onPressed: _next,
            child: Text(_index + 1 < _items.length ? tr('pl_next') : tr('see_result')),
          ),
      ]),
    );
  }
}

/// Kotak "flag terbuka" yang bisa diketuk buat disalin.
class _FlagReveal extends StatelessWidget {
  const _FlagReveal({required this.flag});
  final String flag;

  @override
  Widget build(BuildContext context) => FlagBox(flag: flag);
}
