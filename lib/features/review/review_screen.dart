import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/theme.dart';
import '../../core/models.dart';
import '../../l10n/strings.dart';
import '../../widgets/common.dart';

/// Sesi ulasan: soal yang dulu salah muncul lagi sampai nempel.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late final List<(String, QuizQuestion)> _items = () {
    final s = AppScope.read(context);
    return [
      for (final key in s.dueReviews.take(10))
        if (s.reviewQuestion(key) case final q?) (key, q),
    ];
  }();

  int _index = 0;
  int? _selected;
  bool _revealed = false;
  int _correct = 0;
  bool _finished = false;

  Future<void> _check() async {
    final (key, q) = _items[_index];
    final right = _selected == q.answer;
    setState(() {
      _revealed = true;
      if (right) _correct++;
    });
    await AppScope.read(context).answerReview(key, right);
  }

  Future<void> _next() async {
    if (_index + 1 < _items.length) {
      setState(() {
        _index++;
        _selected = null;
        _revealed = false;
      });
      return;
    }
    await AppScope.read(context).finishReviewSession(_items.length);
    if (!mounted) return;
    setState(() => _finished = true);
  }

  OptionState _stateFor(QuizQuestion q, int i) {
    if (!_revealed) return _selected == i ? OptionState.selected : OptionState.idle;
    if (i == q.answer) return OptionState.correct;
    if (i == _selected) return OptionState.wrong;
    return OptionState.dimmed;
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty || _finished) {
      final empty = _items.isEmpty;
      return Scaffold(
        appBar: AppBar(title: Text(tr('rv_title'))),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: StateMessage(
            glyph: empty ? '[ok]' : '+${_items.length * 3} XP',
            color: C.ok,
            title: empty ? tr('rv_empty_title') : tr('rv_done_title'),
            body: empty
                ? tr('rv_empty_body')
                : tr('rv_done_body', {'c': _correct, 't': _items.length}),
          ),
        ),
        bottomNavigationBar: BottomActions(children: [
          ChunkyButton(onPressed: () => Navigator.of(context).pop(), child: Text(tr('done'))),
        ]),
      );
    }

    final (_, q) = _items[_index];
    final right = _selected == q.answer;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('rv_title')),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(child: Text('${_index + 1}/${_items.length}', style: mono(color: C.accent))),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ProgressLine(value: (_index + (_revealed ? 1 : 0)) / _items.length, color: C.ok),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          MonoTag(tr('rv_tag'), color: C.ok),
          const SizedBox(height: 10),
          Text(q.prompt, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, height: 1.3)),
          const SizedBox(height: 20),
          for (var i = 0; i < q.options.length; i++)
            OptionTile(
              index: i,
              text: q.options[i],
              state: _stateFor(q, i),
              onTap: _revealed ? null : () => setState(() => _selected = i),
            ),
          if (_revealed && q.explanation.isNotEmpty)
            Panel(
              color: (right ? C.ok : C.red).withValues(alpha: 0.08),
              borderColor: (right ? C.ok : C.red).withValues(alpha: 0.45),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(right ? tr('correct') : tr('not_quite'),
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: right ? C.ok : C.red)),
                  const SizedBox(height: 6),
                  Text(q.explanation, style: const TextStyle(height: 1.5)),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomActions(children: [
        if (!_revealed)
          ChunkyButton(onPressed: _selected == null ? null : _check, child: Text(tr('check_answer')))
        else
          ChunkyButton(
            onPressed: _next,
            child: Text(_index + 1 < _items.length ? tr('next_question') : tr('see_result')),
          ),
      ]),
    );
  }
}
