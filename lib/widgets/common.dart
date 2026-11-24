import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme.dart';

/// Tombol "tebal" ala tombol fisik: ada sisi bawah yang kelihatan,
/// dan pas ditekan mukanya turun + HP getar halus.
class ChunkyButton extends StatefulWidget {
  const ChunkyButton({super.key, required this.onPressed, required this.child})
      : outline = false;

  const ChunkyButton.outline({
    super.key,
    required this.onPressed,
    required this.child,
  }) : outline = true;

  final VoidCallback? onPressed;
  final Widget child;
  final bool outline;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  static const double _height = 54;
  static const double _depth = 5;
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final outline = widget.outline;
    final radius = BorderRadius.circular(14);

    final face = outline ? C.surface : (enabled ? C.accent : C.line);
    final edge = outline ? C.bgDeep : (enabled ? C.accentDeep : C.surface);
    final fg = outline ? C.accent : (enabled ? C.onAccent : C.muted);

    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapUp: enabled ? (_) => _set(false) : null,
        onTapCancel: () => _set(false),
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                widget.onPressed!();
              }
            : null,
        child: SizedBox(
          width: double.infinity,
          height: _height + _depth,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: _height,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: edge, borderRadius: radius),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 70),
                curve: Curves.easeOut,
                left: 0,
                right: 0,
                top: _down ? _depth - 1 : 0,
                height: _height,
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: face,
                    borderRadius: radius,
                    border: outline
                        ? Border.all(color: C.accent.withValues(alpha: 0.55), width: 1.2)
                        : null,
                  ),
                  child: DefaultTextStyle(
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                    child: IconTheme(
                      data: IconThemeData(color: fg, size: 20),
                      child: widget.child,
                    ),
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

/// Kartu dasar Cipher. Kalau [onTap] diisi, kartu bisa ditekan (ada ripple).
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    return Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: BoxDecoration(
          color: color ?? C.surface,
          borderRadius: radius,
          border: Border.all(color: borderColor ?? C.line),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Label kecil gaya terminal, contoh: `// modul 01`
class MonoTag extends StatelessWidget {
  const MonoTag(this.text, {super.key, this.color, this.filled = false});

  final String text;
  final Color? color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? C.muted;
    final label = Text(text, style: mono(size: 11, color: color));
    if (!filled) return label;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: label,
    );
  }
}

class ProgressLine extends StatelessWidget {
  const ProgressLine({super.key, required this.value, this.color});

  final double value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? C.accent;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1).toDouble(),
        minHeight: 6,
        backgroundColor: C.line,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}

/// Area tombol aksi utama, nempel di bawah layar.
class BottomActions extends StatelessWidget {
  const BottomActions({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: C.bg,
        border: Border(top: BorderSide(color: C.line)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// Latar grid tipis ala kertas milimeter / layar terminal.
class GridBackdrop extends StatelessWidget {
  const GridBackdrop({super.key, required this.child, this.cell = 22});

  final Widget child;
  final double cell;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GridPainter(cell), child: child);
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter(this.cell);
  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = C.line.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    for (double x = 0; x <= size.width; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => old.cell != cell;
}

enum OptionState { idle, selected, correct, wrong, dimmed }

/// Pilihan jawaban kuis.
class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.index,
    required this.text,
    required this.state,
    this.onTap,
  });

  final int index;
  final String text;
  final OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (Color border, Color fill, Color badge, IconData? icon) =
        switch (state) {
      OptionState.idle => (C.line, C.surface, C.muted, null),
      OptionState.selected => (
          C.accent,
          C.accent.withValues(alpha: 0.10),
          C.accent,
          null
        ),
      OptionState.correct => (
          C.ok,
          C.ok.withValues(alpha: 0.12),
          C.ok,
          Icons.check_rounded
        ),
      OptionState.wrong => (
          C.red,
          C.red.withValues(alpha: 0.12),
          C.red,
          Icons.close_rounded
        ),
      OptionState.dimmed => (C.line, C.bg, C.line, null),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Panel(
        onTap: onTap,
        color: fill,
        borderColor: border,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: badge),
              ),
              child: icon != null
                  ? Icon(icon, size: 18, color: badge)
                  : Text(
                      String.fromCharCode(65 + index),
                      style: mono(size: 13, color: badge, weight: FontWeight.w800),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.35,
                  color: state == OptionState.dimmed ? C.muted : C.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Status kosong / error yang konsisten.
class StateMessage extends StatelessWidget {
  const StateMessage({
    super.key,
    required this.glyph,
    required this.title,
    required this.body,
    this.color,
  });

  final String glyph;
  final String title;
  final String body;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? C.muted;
    return Panel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(glyph, style: mono(size: 22, color: color, weight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(body, style: TextStyle(color: C.muted, height: 1.45)),
        ],
      ),
    );
  }
}

void showInfo(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
