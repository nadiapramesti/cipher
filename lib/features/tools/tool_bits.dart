import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../l10n/strings.dart';
import '../../widgets/common.dart';

/// Baris hasil dengan label + nilai monospace + tombol salin.
class CopyRow extends StatelessWidget {
  const CopyRow({super.key, required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Panel(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MonoTag(label, color: color ?? C.accent),
                  const SizedBox(height: 6),
                  SelectableText(value, style: mono(size: 13, color: C.text, spacing: 0)),
                ],
              ),
            ),
            IconButton(
              tooltip: tr('copy'),
              icon: Icon(Icons.copy_rounded, size: 20, color: C.accent),
              onPressed: value.isEmpty
                  ? null
                  : () {
                      Clipboard.setData(ClipboardData(text: value));
                      showInfo(context, tr('copied'));
                    },
            ),
          ],
        ),
      ),
    );
  }
}

/// Pilihan segmen yang tampil kayak tombol (seragam di semua alat).
class SegmentPicker<T> extends StatelessWidget {
  const SegmentPicker({super.key, required this.value, required this.items, required this.onChanged});

  final T value;
  final List<(T, String)> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: C.line),
      ),
      child: Row(
        children: [
          for (final (v, label) in items)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(v);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: v == value ? C.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: v == value ? C.onAccent : C.textSoft,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Catatan kecil "semua diproses di HP".
class OfflineNote extends StatelessWidget {
  const OfflineNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.shield_outlined, size: 16, color: C.ok),
        const SizedBox(width: 6),
        Expanded(child: Text(tr('tool_offline'), style: mono(size: 11, color: C.ok, spacing: 0.2))),
      ],
    );
  }
}
