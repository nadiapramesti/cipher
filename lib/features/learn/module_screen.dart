import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../core/models.dart';
import '../../widgets/common.dart';
import '../../widgets/lesson_scene.dart';
import '../../widgets/scene3d.dart';
import '../quiz/quiz_screen.dart';
import '../../l10n/strings.dart';

class ModuleScreen extends StatefulWidget {
  const ModuleScreen({super.key, required this.module, this.initialPage = 0});

  final LearnModule module;

  /// Halaman awal (dipakai hasil pencarian buat langsung lompat ke bagian itu).
  final int initialPage;

  @override
  State<ModuleScreen> createState() => _ModuleScreenState();
}

class _ModuleScreenState extends State<ModuleScreen> {
  late final _controller = PageController(initialPage: widget.initialPage.clamp(0, _maxPage));
  late int _page = widget.initialPage.clamp(0, _maxPage);

  int get _maxPage => widget.module.pages.isEmpty ? 0 : widget.module.pages.length - 1;

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
          ? Padding(
              padding: EdgeInsets.all(20),
              child: StateMessage(
                glyph: '[ ]',
                title: tr('mod_empty_title'),
                body: tr('mod_empty_body'),
              ),
            )
          : PageView.builder(
              controller: _controller,
              itemCount: pages.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => _LessonView(
                page: pages[i],
                label: tr('part', {'i': i + 1, 'n': pages.length}),
              ),
            ),
      bottomNavigationBar: BottomActions(children: [
        Row(
          children: [
            if (_page > 0) ...[
              Expanded(
                child: ChunkyButton.outline(
                  onPressed: () => _go(-1),
                  child: Text(tr('back')),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              flex: 2,
              child: ChunkyButton(
                onPressed: _isLast ? _startQuiz : () => _go(1),
                child: Text(_isLast ? tr('start_quiz') : tr('next')),
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
        if (page.visual != null) ...[
          const SizedBox(height: 14),
          LessonScene(spec: page.visual!),
        ],
        const SizedBox(height: 16),
        RichBody(text: page.body),
        if (page.tip != null) ...[
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: C.okTint,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: C.okDeep),
              boxShadow: [BoxShadow(color: C.okDeep.withValues(alpha: 0.5), offset: const Offset(0, 6))],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MonoTag(tr('analogy'), color: C.ok),
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
/// baris yang diawali "- " jadi poin, "$ " perintah terminal, "> " baris kode, "| " contoh output.
class RichBody extends StatelessWidget {
  const RichBody({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: 15.5, height: 1.6, color: C.text);
    final widgets = <Widget>[];
    // baris "> " (kode) dan "| " (output) yang berurutan digabung jadi satu blok
    String? blockKind;
    final block = <String>[];
    void flush() {
      if (blockKind == null) return;
      widgets.add(CodeLine(text: block.join('\n'), command: blockKind == '> ', prompt: false));
      block.clear();
      blockKind = null;
    }

    for (final line in text.split('\n')) {
      final t = line.trimRight();
      final kind = t.startsWith('> ') ? '> ' : (t.startsWith('| ') ? '| ' : null);
      if (kind != null) {
        if (blockKind != kind) flush();
        blockKind = kind;
        block.add(t.substring(2));
        continue;
      }
      flush();
      if (t.isEmpty) {
        widgets.add(const SizedBox(height: 10));
      } else if (t.startsWith(r'$ ')) {
        widgets.add(CodeLine(text: t.substring(2)));
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
    flush();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }
}

/// Satu baris perintah terminal (bisa disalin) atau contoh output.
class CodeLine extends StatelessWidget {
  const CodeLine({super.key, required this.text, this.command = true, this.prompt = true});

  final String text;
  final bool command;

  /// Tampilkan tanda `$` (perintah terminal). Kode program pakai false.
  final bool prompt;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
      decoration: BoxDecoration(
        color: C.bgDeep,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: command ? C.accent.withValues(alpha: 0.45) : C.line),
      ),
      child: Row(
        children: [
          if (command && prompt) Text(r'$ ', style: mono(size: 12.5, color: C.ok, weight: FontWeight.w800, spacing: 0)),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(text, style: mono(size: 12.5, color: command ? C.text : C.textSoft, spacing: 0)),
            ),
          ),
          if (command) Icon(Icons.copy_rounded, size: 16, color: C.accent),
        ],
      ),
    );
    if (!command) return box;
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: text));
        HapticFeedback.selectionClick();
        showInfo(context, tr('copied'));
      },
      child: box,
    );
  }
}
