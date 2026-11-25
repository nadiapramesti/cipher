import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme.dart';
import 'scene3d.dart' show IsoTileState;

/// Satu distrik di peta kota.
class CityNode {
  const CityNode({required this.code, required this.state, required this.tier, this.progress});
  final String code; // "LV.07"
  final IsoTileState state;
  final int tier; // 0 pemula .. 3 hard
  final String? progress; // "3/5"
}

/// Peta kota 3D yang digeser ke samping: tiap level satu gedung isometrik,
/// makin tinggi tingkatnya makin tinggi gedungnya. Label di bawah gedung jadi gak tabrakan.
class CityMap extends StatefulWidget {
  const CityMap({super.key, required this.nodes, required this.current, required this.onTap, this.height = 250});

  final List<CityNode> nodes;
  final int current;
  final ValueChanged<int> onTap;
  final double height;

  static const spacing = 92.0;
  static const pad = 56.0;

  /// Titik dasar gedung ke-i (dipakai juga oleh test).
  static Offset baseOf(int i, double height) {
    final mid = height * 0.58;
    return Offset(pad + i * spacing, mid + math.sin(i * 0.95) * height * 0.13);
  }

  @override
  State<CityMap> createState() => _CityMapState();
}

class _CityMapState extends State<CityMap> with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  late final AnimationController _bob =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerOn(widget.current, animate: false));
  }

  @override
  void didUpdateWidget(CityMap old) {
    super.didUpdateWidget(old);
    if (old.current != widget.current) _centerOn(widget.current);
  }

  void _centerOn(int i, {bool animate = true}) {
    if (!_scroll.hasClients) return;
    final view = _scroll.position.viewportDimension;
    final target = (CityMap.baseOf(i, widget.height).dx - view / 2)
        .clamp(0.0, _scroll.position.maxScrollExtent)
        .toDouble();
    if (animate) {
      _scroll.animateTo(target, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
    } else {
      _scroll.jumpTo(target);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.nodes.length;
    final width = CityMap.pad * 2 + (n - 1) * CityMap.spacing;
    final h = widget.height;

    return SizedBox(
      height: h,
      child: ShaderMask(
        // ujung kiri-kanan memudar biar kelihatan bisa digeser
        shaderCallback: (r) => const LinearGradient(
          colors: [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
          stops: [0, 0.06, 0.94, 1],
        ).createShader(r),
        blendMode: BlendMode.dstIn,
        child: SingleChildScrollView(
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: SizedBox(
            width: width,
            height: h,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _RoadPainter(nodes: widget.nodes, current: widget.current, height: h)),
                ),
                for (var i = 0; i < n; i++) _building(i),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _building(int i) {
    final node = widget.nodes[i];
    final base = CityMap.baseOf(i, widget.height);
    const w = 86.0, boxH = 150.0;
    final isCurrent = i == widget.current;

    return Positioned(
      left: base.dx - w / 2,
      top: base.dy - boxH + 46,
      width: w,
      height: boxH,
      child: Semantics(
        button: true,
        label: '${node.code} ${node.progress ?? ''}',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onTap(i);
          },
          child: AnimatedBuilder(
            animation: _bob,
            builder: (_, __) => CustomPaint(
              painter: _TowerPainter(node: node, current: isCurrent, bob: isCurrent ? _bob.value : 0, dark: C.isDark),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      node.code,
                      style: mono(
                        size: 11.5,
                        weight: FontWeight.w800,
                        spacing: 0.3,
                        color: switch (node.state) {
                          IsoTileState.done => C.ok,
                          IsoTileState.active => isCurrent ? C.text : C.textSoft,
                          _ => C.hint,
                        },
                      ),
                    ),
                    const SizedBox(height: 1),
                    SizedBox(
                      height: 14,
                      child: node.state == IsoTileState.locked || node.state == IsoTileState.soon
                          ? Icon(Icons.lock_rounded, size: 11, color: C.hint)
                          : Text(node.progress ?? '', style: mono(size: 10, color: C.muted, spacing: 0)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Color _tierColor(int tier) => [C.ok, C.accent, C.orange, C.red][tier.clamp(0, 3)];

class _RoadPainter extends CustomPainter {
  _RoadPainter({required this.nodes, required this.current, required this.height});
  final List<CityNode> nodes;
  final int current;
  final double height;

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.isEmpty) return;
    final pts = [for (var i = 0; i < nodes.length; i++) CityMap.baseOf(i, height)];

    Path road(int from, int to) {
      final p = Path()..moveTo(pts[from].dx, pts[from].dy);
      for (var i = from + 1; i <= to; i++) {
        final a = pts[i - 1], b = pts[i];
        final mx = (a.dx + b.dx) / 2;
        p.cubicTo(mx, a.dy, mx, b.dy, b.dx, b.dy);
      }
      return p;
    }

    final full = road(0, nodes.length - 1);
    // badan jalan
    canvas.drawPath(full, Paint()..color = C.line..style = PaintingStyle.stroke..strokeWidth = 16..strokeCap = StrokeCap.round);
    canvas.drawPath(full, Paint()..color = C.bgDeep..style = PaintingStyle.stroke..strokeWidth = 11..strokeCap = StrokeCap.round);

    // marka putus-putus di sepanjang jalan
    final dash = Paint()..color = C.lineStrong..strokeWidth = 2..strokeCap = StrokeCap.round;
    for (final m in full.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 14) {
        final a = m.getTangentForOffset(d)?.position;
        final b = m.getTangentForOffset(math.min(d + 6, m.length))?.position;
        if (a != null && b != null) canvas.drawLine(a, b, dash);
      }
    }

    // jalan yang udah dilewati menyala
    if (current > 0) {
      final done = road(0, math.min(current, nodes.length - 1));
      canvas.drawPath(done, Paint()
        ..color = C.accent.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      canvas.drawPath(done, Paint()..color = C.accent..style = PaintingStyle.stroke..strokeWidth = 3.5..strokeCap = StrokeCap.round);
    }

    // pita tingkat di bawah jalan: warna berubah tiap ganti tingkat
    for (var i = 0; i < nodes.length; i++) {
      if (i > 0 && nodes[i].tier == nodes[i - 1].tier) continue;
      final c = _tierColor(nodes[i].tier);
      canvas.drawCircle(pts[i] + const Offset(0, 40), 3, Paint()..color = c);
    }
  }

  @override
  bool shouldRepaint(_RoadPainter old) => old.current != current || old.nodes.length != nodes.length;
}

/// Satu gedung isometrik. Titik dasar = tengah bawah kanvas dikurangi 46 px (ruang label).
class _TowerPainter extends CustomPainter {
  _TowerPainter({required this.node, required this.current, required this.bob, required this.dark});
  final CityNode node;
  final bool current;
  final double bob;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final base = Offset(size.width / 2, size.height - 46);
    const hw = 22.0, hh = 11.0; // setengah lebar/tinggi belah ketupat
    final locked = node.state == IsoTileState.locked || node.state == IsoTileState.soon;
    final tierC = _tierColor(node.tier);
    final towerH = 18.0 + node.tier * 11 + (current ? 6 : 0);

    final Color body = switch (node.state) {
      IsoTileState.done => C.ok,
      IsoTileState.active => current ? C.accent : C.surface2,
      _ => C.surface,
    };

    // pelat tanah berwarna tingkat
    final plate = Path()
      ..moveTo(base.dx, base.dy - hh - 5)
      ..lineTo(base.dx + hw + 10, base.dy)
      ..lineTo(base.dx, base.dy + hh + 5)
      ..lineTo(base.dx - hw - 10, base.dy)
      ..close();
    canvas.drawPath(plate, Paint()..color = tierC.withValues(alpha: locked ? 0.08 : 0.2));
    canvas.drawPath(plate, Paint()
      ..color = tierC.withValues(alpha: locked ? 0.2 : 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2);

    if (current) {
      canvas.drawCircle(base + Offset(0, -towerH / 2), 34, Paint()
        ..color = C.accent.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18));
    }

    final top = base.dy - towerH;
    final left = Path()
      ..moveTo(base.dx - hw, base.dy - hh)
      ..lineTo(base.dx, base.dy)
      ..lineTo(base.dx, top + hh)
      ..lineTo(base.dx - hw, top)
      ..close();
    final right = Path()
      ..moveTo(base.dx, base.dy)
      ..lineTo(base.dx + hw, base.dy - hh)
      ..lineTo(base.dx + hw, top)
      ..lineTo(base.dx, top + hh)
      ..close();
    final roof = Path()
      ..moveTo(base.dx, top - hh)
      ..lineTo(base.dx + hw, top)
      ..lineTo(base.dx, top + hh)
      ..lineTo(base.dx - hw, top)
      ..close();

    final dim = locked ? 0.55 : 1.0;
    canvas.drawPath(left, Paint()..color = Color.lerp(Colors.black, body, 0.72 * dim)!);
    canvas.drawPath(right, Paint()..color = Color.lerp(Colors.black, body, 0.52 * dim)!);
    canvas.drawPath(roof, Paint()..color = Color.lerp(Colors.black, body, dim)!);
    final edge = Paint()
      ..color = locked ? C.line : (current ? C.accentSoft : tierC.withValues(alpha: 0.8))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeJoin = StrokeJoin.round;
    for (final p in [left, right, roof]) {
      canvas.drawPath(p, edge);
    }

    // jendela menyala di gedung yang udah kebuka
    if (!locked) {
      final win = Paint()..color = (node.state == IsoTileState.done ? C.bgDeep : C.yellow).withValues(alpha: 0.75);
      for (var y = top + hh + 7; y < base.dy - 6; y += 9) {
        for (final fx in [0.35, 0.7]) {
          final rx = base.dx + hw * fx;
          final ry = y - hh * fx;
          canvas.drawLine(Offset(rx - 2.5, ry + 1.2), Offset(rx + 2.5, ry - 1.2), win..strokeWidth = 2);
        }
      }
    }

    // ikon di atap
    final icon = switch (node.state) {
      IsoTileState.done => Icons.check_rounded,
      IsoTileState.locked || IsoTileState.soon => Icons.lock_rounded,
      _ => null,
    };
    if (icon != null) {
      final tp = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            fontSize: 13,
            color: node.state == IsoTileState.done ? C.bgDeep : C.hint,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(base.dx - tp.width / 2, top - tp.height / 2));
    }

    // penanda "kamu di sini" yang naik-turun
    if (current) {
      final y = top - hh - 18 - bob * 6;
      final pin = Path()
        ..moveTo(base.dx - 6, y + 8)
        ..lineTo(base.dx + 6, y + 8)
        ..lineTo(base.dx, y + 15)
        ..close();
      canvas.drawPath(pin, Paint()..color = C.yellow);
      canvas.drawCircle(Offset(base.dx, y), 9, Paint()..color = C.yellow);
      canvas.drawCircle(Offset(base.dx, y), 3.5, Paint()..color = C.bgDeep);
    }
  }

  @override
  bool shouldRepaint(_TowerPainter old) => old.bob != bob || old.node.state != node.state || old.current != current;
}
