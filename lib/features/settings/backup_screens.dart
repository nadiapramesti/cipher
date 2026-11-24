import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_state.dart';
import '../../app/theme.dart';
import '../../l10n/strings.dart';
import '../../widgets/common.dart';

/// Tampilkan kode backup progres + tombol salin.
class ExportBackupScreen extends StatefulWidget {
  const ExportBackupScreen({super.key});

  @override
  State<ExportBackupScreen> createState() => _ExportBackupScreenState();
}

class _ExportBackupScreenState extends State<ExportBackupScreen> {
  late final String _code = AppScope.read(context).exportBackup();
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _code));
    if (!mounted) return;
    setState(() => _copied = true);
    showInfo(context, tr('bk_copied'));
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final done = state.modulesPassed;

    return Scaffold(
      appBar: AppBar(title: Text(tr('bk_export_title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(tr('bk_export_lead'), style: TextStyle(color: C.textSoft, height: 1.5)),
          const SizedBox(height: 16),
          Row(
            children: [
              MonoTag(tr('bk_sum_xp', {'n': state.xp}), color: C.accent, filled: true),
              const SizedBox(width: 8),
              MonoTag(tr('bk_sum_mod', {'n': done}), color: C.ok, filled: true),
            ],
          ),
          const SizedBox(height: 14),
          Panel(
            color: C.surface2,
            child: SelectableText(
              _code,
              style: mono(size: 12, color: C.text, spacing: 0),
            ),
          ),
          const SizedBox(height: 16),
          Panel(
            color: C.accentTint,
            borderColor: C.accentDeep,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: C.accent),
                const SizedBox(width: 10),
                Expanded(child: Text(tr('bk_export_note'), style: TextStyle(height: 1.45, color: C.text))),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomActions(children: [
        ChunkyButton(
          onPressed: _copy,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_copied ? Icons.check_rounded : Icons.copy_rounded),
              const SizedBox(width: 8),
              Text(_copied ? tr('bk_copied_btn') : tr('bk_copy')),
            ],
          ),
        ),
      ]),
    );
  }
}

/// Tempel kode backup, cek, lalu pulihkan.
class ImportBackupScreen extends StatefulWidget {
  const ImportBackupScreen({super.key});

  @override
  State<ImportBackupScreen> createState() => _ImportBackupScreenState();
}

class _ImportBackupScreenState extends State<ImportBackupScreen> {
  final _controller = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (!mounted) return;
    if (text.isEmpty) {
      showInfo(context, tr('bk_clip_empty'));
      return;
    }
    setState(() {
      _controller.text = text;
      _error = null;
    });
  }

  Future<void> _restore() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.surface,
        title: Text(tr('bk_confirm_title'), style: display(size: 20)),
        content: Text(tr('bk_confirm_body'), style: TextStyle(color: C.textSoft, height: 1.45)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: C.textSoft,
              side: BorderSide(color: C.lineStrong),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: C.accent,
              foregroundColor: C.onAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(tr('bk_restore')),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AppScope.read(context).importBackup(_controller.text);
      if (!mounted) return;
      showInfo(context, tr('bk_restored'));
      Navigator.of(context).pop();
    } on FormatException catch (e) {
      setState(() {
        _busy = false;
        _error = switch (e.message) {
          'checksum' => tr('bk_err_checksum'),
          'not-cipher' => tr('bk_err_not_cipher'),
          _ => tr('bk_err_corrupt'),
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final empty = _controller.text.trim().isEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(tr('bk_import_title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(tr('bk_import_lead'), style: TextStyle(color: C.textSoft, height: 1.5)),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            onChanged: (_) => setState(() => _error = null),
            minLines: 4,
            maxLines: 7,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.visiblePassword,
            style: mono(size: 12.5, color: C.text, spacing: 0),
            decoration: InputDecoration(
              labelText: tr('bk_field_label'),
              hintText: 'CIPHER1.eyJ2IjoxLCJvbmIiOnRydWUs….3f9a12bc',
              alignLabelWithHint: true,
              errorText: _error,
              errorMaxLines: 3,
            ),
          ),
          const SizedBox(height: 12),
          ChunkyButton.outline(
            onPressed: _paste,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.content_paste_rounded),
                const SizedBox(width: 8),
                Text(tr('bk_paste')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, size: 18, color: C.orange),
              const SizedBox(width: 8),
              Expanded(child: Text(tr('bk_import_warn'), style: TextStyle(color: C.muted, height: 1.45, fontSize: 13))),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomActions(children: [
        ChunkyButton(
          onPressed: empty || _busy ? null : _restore,
          child: Text(tr('bk_restore_btn')),
        ),
      ]),
    );
  }
}
