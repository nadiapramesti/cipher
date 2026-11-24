import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/theme.dart';
import '../../widgets/common.dart';
import '../home/home_screen.dart';
import '../quiz/quiz_logic.dart';

class PlacementScreen extends StatefulWidget {
  const PlacementScreen({super.key});

  @override
  State<PlacementScreen> createState() => _PlacementScreenState();
}

class _PlacementScreenState extends State<PlacementScreen> {
  int _index = 0;
  int? _selected;
  final List<int?> _answers = [];

  void _commit(int? answer) {
    final questions = AppScope.read(context).content.placement;
    _answers.add(answer);
    if (_index + 1 >= questions.length) {
      final level = recommendLevel(questions, _answers);
      final correct = [
        for (var i = 0; i < questions.length; i++)
          if (_answers[i] == questions[i].answer) i,
      ].length;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PlacementResultScreen(
            recommended: level,
            correct: correct,
            total: questions.length,
          ),
        ),
      );
      return;
    }
    setState(() {
      _index++;
      _selected = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final questions = AppScope.of(context).content.placement;
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tes Penempatan')),
        body: const Padding(
          padding: EdgeInsets.all(20),
          child: StateMessage(
            glyph: '[ ]',
            title: 'Soal belum tersedia',
            body: 'Kamu bisa langsung mulai dari LV.00.',
          ),
        ),
      );
    }
    final q = questions[_index];
    final last = _index == questions.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tes Penempatan'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: Text(
                '${(_index + 1).toString().padLeft(2, '0')}/${questions.length.toString().padLeft(2, '0')}',
                style: mono(color: C.amber),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ProgressLine(value: (_index + 1) / questions.length),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          const MonoTag('// jawab sejujurnya, gak ada nilai merah'),
          const SizedBox(height: 10),
          Text(
            q.prompt,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < q.options.length; i++)
            OptionTile(
              index: i,
              text: q.options[i],
              state: _selected == i ? OptionState.selected : OptionState.idle,
              onTap: () => setState(() => _selected = i),
            ),
        ],
      ),
      bottomNavigationBar: BottomActions(children: [
        FilledButton(
          onPressed: _selected == null ? null : () => _commit(_selected),
          child: Text(last ? 'Lihat Hasil' : 'Berikutnya'),
        ),
        OutlinedButton(
          onPressed: () => _commit(null),
          child: const Text('Belum tau, lewati soal'),
        ),
      ]),
    );
  }
}

class PlacementResultScreen extends StatefulWidget {
  const PlacementResultScreen({
    super.key,
    required this.recommended,
    required this.correct,
    required this.total,
  });

  final int recommended;
  final int correct;
  final int total;

  @override
  State<PlacementResultScreen> createState() => _PlacementResultScreenState();
}

class _PlacementResultScreenState extends State<PlacementResultScreen> {
  late int _chosen = widget.recommended;
  bool _saving = false;

  Future<void> _start() async {
    setState(() => _saving = true);
    await AppScope.read(context).completeOnboarding(_chosen);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = AppScope.of(context).content;
    final rec = content.levelAt(widget.recommended);
    final chosen = content.levelAt(_chosen);

    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Tes')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Panel(
            borderColor: C.amber.withValues(alpha: 0.5),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MonoTag('${widget.correct}/${widget.total} benar', color: C.amber, filled: true),
                const SizedBox(height: 14),
                const Text('Saran kami, mulai dari',
                    style: TextStyle(color: C.muted)),
                const SizedBox(height: 4),
                Text(
                  '${rec?.code ?? 'LV.00'}  ${rec?.title ?? ''}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Level di bawahnya tetap kebuka, jadi kamu bisa balik kapan aja buat ngulang dasar.',
                  style: TextStyle(color: C.muted, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const MonoTag('// atau pilih sendiri'),
          const SizedBox(height: 10),
          for (final level in content.levels)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Panel(
                onTap: () => setState(() => _chosen = level.index),
                borderColor: _chosen == level.index ? C.amber : C.line,
                color: _chosen == level.index
                    ? C.amber.withValues(alpha: 0.08)
                    : C.surface,
                child: Row(
                  children: [
                    Text(level.code,
                        style: mono(
                            size: 13,
                            color: _chosen == level.index ? C.amber : C.muted,
                            weight: FontWeight.w800)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(level.title,
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          if (!level.available)
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Text('Materi segera hadir',
                                  style: TextStyle(color: C.muted, fontSize: 12.5)),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      _chosen == level.index
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: _chosen == level.index ? C.amber : C.muted,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomActions(children: [
        FilledButton(
          onPressed: _saving ? null : _start,
          child: Text('Mulai di ${chosen?.code ?? 'LV.00'}'),
        ),
      ]),
    );
  }
}
