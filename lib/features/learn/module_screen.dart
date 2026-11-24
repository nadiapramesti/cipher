import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/models.dart';
import '../../widgets/common.dart';
import '../../widgets/scene3d.dart';
import '../quiz/quiz_screen.dart';

class ModuleScreen extends StatefulWidget {
  const ModuleScreen({super.key, required this.module});

  final LearnModule module;

  @override
  State<ModuleScreen> createState() => _ModuleScreenState();
}

class _ModuleScreenState extends State<ModuleScreen> {
  final _controller = PageController();
  int _page = 0;

  int get _count => widget.module.pages.length;
  bool get _isLast => _page >= _count - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int delta) {
    _controller.animateToPage(
      _page + delta,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _startQuiz() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => QuizScreen(module: widget.module)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = widget.module.pages;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.module.title, overflow: TextOverflow.ellipsis),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ProgressLine(value: _count == 0 ? 1 : (_page + 1) / _count),
          ),
        ),
      ),
      body: pages.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: StateMessage(
                glyph: '[ ]',
                title: 'Materinya kosong',
                body: 'Langsung ke kuis aja.',
              ),
            )
          : PageView.builder(
              controller: _controller,
              itemCount: pages.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => _LessonView(
                page: pages[i],
                label: '// bagian ${i + 1} dari ${pages.length}',
              ),
            ),
      bottomNavigationBar: BottomActions(children: [
        Row(
          children: [
            if (_page > 0) ...[
              Expanded(
                child: ChunkyButton.outline(
                  onPressed: () => _go(-1),
                  child: const Text('Balik'),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              flex: 2,
              child: ChunkyButton(
                onPressed: _isLast ? _startQuiz : () => _go(1),
                child: Text(_isLast ? 'Mulai Kuis' : 'Lanjut'),
              ),
            ),
          ],
        ),
      ]),
    );
  }
}

class _LessonView extends StatelessWidget {
  const _LessonView({required this.page, required this.label});

  final LessonPage page;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 32),
      children: [
        TiltDeck(
          height: 132,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MonoTag(label, color: C.accent),
              const Spacer(),
              Text(page.title, style: display(size: 26)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        RichBody(text: page.body),
        if (page.tip != null) ...[
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: C.okTint,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: C.okDeep),
              boxShadow: const [BoxShadow(color: Color(0xFF11170A), offset: Offset(0, 6))],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MonoTag('ANALOGI', color: C.ok),
                const SizedBox(height: 8),
                Text(page.tip!, style: const TextStyle(height: 1.5)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Render teks materi sederhana: paragraf dipisah baris kosong,
/// baris yang diawali "- " jadi poin.
class RichBody extends StatelessWidget {
  const RichBody({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 15.5, height: 1.6, color: C.text);
    final widgets = <Widget>[];
    for (final line in text.split('\n')) {
      final t = line.trimRight();
      if (t.isEmpty) {
        widgets.add(const SizedBox(height: 10));
      } else if (t.startsWith('- ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 3, right: 10),
                child: Text('>', style: mono(size: 13, color: C.accent, weight: FontWeight.w800)),
              ),
              Expanded(child: Text(t.substring(2), style: style)),
            ],
          ),
        ));
      } else {
        widgets.add(Text(t, style: style));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }
}
