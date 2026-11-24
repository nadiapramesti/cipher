import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/strings.dart';
import 'shell.dart';

/// Terminal Linux simulasi: latihan ls, cd, cat, grep sampai nemu flag.
class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  late final VirtualShell _shell = VirtualShell(english: L.isEn);
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  final List<(String, bool)> _lines = []; // (teks, isPerintah)

  @override
  void initState() {
    super.initState();
    _lines.add((tr('tm_welcome'), false));
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _run([String? preset]) {
    final cmd = (preset ?? _input.text).trim();
    if (cmd.isEmpty) return;
    final prompt = _shell.prompt;
    final out = _shell.run(cmd);
    setState(() {
      if (out == '\x1b') {
        _lines.clear();
      } else {
        _lines.add(('$prompt $cmd', true));
        if (out.isNotEmpty) _lines.add((out, false));
      }
      _input.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 180), curve: Curves.easeOut);
      }
    });
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final termBg = C.isDark ? C.bgDeep : const Color(0xFF14101F);
    const termText = Color(0xFFE6E0F5);

    return Scaffold(
      appBar: AppBar(title: Text(tr('tm_title'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Text(tr('tm_lead'), style: TextStyle(color: C.textSoft, height: 1.45)),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: termBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: C.lineStrong),
              ),
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(14),
                itemCount: _lines.length,
                itemBuilder: (_, i) {
                  final (text, isCmd) = _lines[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: SelectableText(
                      text,
                      style: mono(
                        size: 12.5,
                        color: isCmd ? C.ok : termText,
                        weight: isCmd ? FontWeight.w700 : FontWeight.w500,
                        spacing: 0,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              children: [
                for (final c in ['help', 'ls', 'ls -a', 'pwd', 'cd ..', 'clear'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(c, style: mono(size: 11.5, color: C.accent, weight: FontWeight.w700)),
                      backgroundColor: C.surface,
                      side: BorderSide(color: C.accentDeep),
                      onPressed: () => _run(c),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + MediaQuery.viewInsetsOf(context).bottom),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  focusNode: _focus,
                  autocorrect: false,
                  enableSuggestions: false,
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _run(),
                  style: mono(size: 14, color: C.text, spacing: 0),
                  decoration: InputDecoration(
                    hintText: tr('tm_hint'),
                    prefixText: '\$ ',
                    prefixStyle: mono(size: 14, color: C.ok, weight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 56,
                height: 56,
                child: Material(
                  color: C.accent,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _run,
                    child: Icon(Icons.keyboard_return_rounded, color: C.onAccent, semanticLabel: tr('tm_run')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
