import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/theme.dart';
import '../../core/models.dart';
import '../../widgets/common.dart';
import '../learn/module_screen.dart';
import 'quiz_logic.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.module});

  final LearnModule module;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _index = 0;
  int? _selected;
  bool _revealed = false;
  int _correct = 0;
  bool _saving = false;

  List<QuizQuestion> get _qs => widget.module.quiz;

  void _check() {
    if (_selected == null) return;
    setState(() {
      _revealed = true;
      if (_selected == _qs[_index].answer) _correct++;
    });
  }

  Future<void> _next() async {
    if (_index + 1 < _qs.length) {
      setState(() {
        _index++;
        _selected = null;
        _revealed = false;
      });
      return;
    }
    setState(() => _saving = true);
    final percent = scorePercent(_correct, _qs.length);
    final gained = await AppScope.read(context).recordQuiz(widget.module.id, percent);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => QuizResultScreen(
          module: widget.module,
          percent: percent,
          correct: _correct,
          total: _qs.length,
          xpGained: gained,
        ),
      ),
    );
  }

  OptionState _stateFor(int i) {
    final q = _qs[_index];
    if (!_revealed) return _selected == i ? OptionState.selected : OptionState.idle;
    if (i == q.answer) return OptionState.correct;
    if (i == _selected) return OptionState.wrong;
    return OptionState.dimmed;
  }

  @override
  Widget build(BuildContext context) {
    if (_qs.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kuis')),
        body: const Padding(
          padding: EdgeInsets.all(20),
          child: StateMessage(
            glyph: '[ ]',
            title: 'Kuis belum tersedia',
            body: 'Modul ini belum punya soal.',
          ),
        ),
      );
    }

    final q = _qs[_index];
    final right = _selected == q.answer;
    final last = _index == _qs.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kuis'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: Text(
                '${_index + 1}/${_qs.length}',
                style: mono(color: C.amber),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ProgressLine(value: (_index + (_revealed ? 1 : 0)) / _qs.length),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          MonoTag('// ${widget.module.title.toLowerCase()}'),
          const SizedBox(height: 10),
          Text(q.prompt,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, height: 1.3)),
          const SizedBox(height: 20),
          for (var i = 0; i < q.options.length; i++)
            OptionTile(
              index: i,
              text: q.options[i],
              state: _stateFor(i),
              onTap: _revealed ? null : () => setState(() => _selected = i),
            ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: !_revealed
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Panel(
                      color: (right ? C.teal : C.red).withValues(alpha: 0.07),
                      borderColor: (right ? C.teal : C.red).withValues(alpha: 0.45),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(right ? 'Benar!' : 'Belum tepat',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: right ? C.teal : C.red,
                              )),
                          if (q.explanation.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(q.explanation, style: const TextStyle(height: 1.5)),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomActions(children: [
        if (!_revealed)
          FilledButton(
            onPressed: _selected == null ? null : _check,
            child: const Text('Cek Jawaban'),
          )
        else
          FilledButton(
            onPressed: _saving ? null : _next,
            child: Text(last ? 'Lihat Hasil' : 'Soal Berikutnya'),
          ),
      ]),
    );
  }
}

class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({
    super.key,
    required this.module,
    required this.percent,
    required this.correct,
    required this.total,
    required this.xpGained,
  });

  final LearnModule module;
  final int percent;
  final int correct;
  final int total;
  final int xpGained;

  @override
  Widget build(BuildContext context) {
    final passed = isPassed(percent);
    final color = passed ? C.teal : C.orange;
    final streak = AppScope.of(context).streak;

    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Kuis')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Panel(
            padding: const EdgeInsets.all(24),
            borderColor: color.withValues(alpha: 0.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MonoTag(passed ? 'LULUS' : 'BELUM LULUS', color: color, filled: true),
                const SizedBox(height: 16),
                Text('$percent%',
                    style: mono(size: 64, color: color, weight: FontWeight.w800, spacing: -1)),
                Text('$correct dari $total jawaban benar',
                    style: const TextStyle(color: C.muted)),
                const SizedBox(height: 16),
                Text(
                  passed
                      ? 'Modul "${module.title}" kelar. Modul berikutnya udah kebuka.'
                      : 'Butuh minimal $passThreshold% buat lulus. Baca ulang materinya bentar, terus coba lagi.',
                  style: const TextStyle(height: 1.5, fontSize: 15),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Reward(icon: Icons.bolt_rounded, value: '+$xpGained', label: 'XP', color: C.amber),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Reward(
                  icon: Icons.local_fire_department_rounded,
                  value: '$streak',
                  label: 'hari beruntun',
                  color: C.orange,
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomActions(children: [
        if (passed)
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kembali ke Daftar Modul'),
          )
        else ...[
          FilledButton(
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => QuizScreen(module: module)),
            ),
            child: const Text('Coba Kuis Lagi'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => ModuleScreen(module: module)),
            ),
            child: const Text('Baca Ulang Materi'),
          ),
        ],
      ]),
    );
  }
}

class _Reward extends StatelessWidget {
  const _Reward({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: mono(size: 20, color: C.text, weight: FontWeight.w800)),
              Text(label, style: mono(size: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
