import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Scene 3D onboarding: brankas kubus muter, inti kubus solid,
/// cincin orbit, lantai grid berperspektif, dan paket data melayang.
/// Semua digambar pakai CustomPainter, tanpa package 3D.
class VaultScene extends StatefulWidget {
  const VaultScene({super.key, this.accent = C.accent, this.ring = C.ok});

  final Color accent;
  final Color ring;

  @override
  State<VaultScene> createState() => _VaultSceneState();
}

class _VaultSceneState extends State<VaultScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  );

  @override
  void initState() {
    super.initState();
    _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) _c.stop();
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          painter: _VaultPainter(
            t: _c.value,
            accent: widget.accent,
            ring: widget.ring,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _V3 {
  const _V3(this.x, this.y, this.z);
  final double x, y, z;
}

/// Kubus satuan (setengah sisi = 1).
const _faces = <List<int>>[
  [4, 5, 7, 6], // depan  z+
  [1, 0, 2, 3], // belakang z-
  [5, 1, 3, 7], // kanan x+
  [0, 4, 6, 2], // kiri x-
  [0, 1, 5, 4], // atas y-
  [6, 7, 3, 2], // bawah y+
];

_V3 _corner(int i) =>
    _V3(i & 1 == 1 ? 1 : -1, i & 2 == 2 ? 1 : -1, i & 4 == 4 ? 1 : -1);

_V3 _rotate(_V3 p, double ry, double rx) {
  final cy = math.cos(ry), sy = math.sin(ry);
  final x1 = p.x * cy + p.z * sy;
  final z1 = -p.x * sy + p.z * cy;
  final cx = math.cos(rx), sx = math.sin(rx);
  final y2 = p.y * cx - z1 * sx;
  final z2 = p.y * sx + z1 * cx;
  return _V3(x1, y2, z2);
}

class _Projected {
  _Projected(this.points, this.depth, this.facing, this.index);
  final List<Offset> points;
  final double depth;
  final double facing;
  final int index;
}

List<_Projected> _projectCube({
  required Offset center,
  required double half,
  required double ry,
  required double rx,
}) {
  const d = 7.0; // jarak kamera dalam satuan kubus
  final verts = List.generate(8, (i) => _rotate(_corner(i), ry, rx));
  Offset proj(_V3 v) {
    final s = d / (d - v.z);
    return center + Offset(v.x * s * half, v.y * s * half);
  }

  final out = <_Projected>[];
  for (var f = 0; f < _faces.length; f++) {
    final idx = _faces[f];
    final vs = idx.map((i) => verts[i]).toList();
    final depth = vs.map((v) => v.z).reduce((a, b) => a + b) / 4;
    // normal muka = rata-rata titik (kubus berpusat di 0)
    out.add(_Projected(vs.map(proj).toList(), depth, depth, f));
  }
  out.sort((a, b) => a.depth.compareTo(b.depth));
  return out;
}

Path _poly(List<Offset> pts) => Path()..addPolygon(pts, true);

/// Titik di permukaan muka (u,v dalam -1..1) -> layar, pakai bilinear.
Offset _onFace(List<Offset> q, double u, double v) {
  final a = Offset.lerp(q[0], q[1], (u + 1) / 2)!;
  final b = Offset.lerp(q[3], q[2], (u + 1) / 2)!;
  return Offset.lerp(a, b, (v + 1) / 2)!;
}

const _shield = <Offset>[
  Offset(0, -0.58),
  Offset(0.46, -0.38),
  Offset(0.46, 0.02),
  Offset(0.32, 0.36),
  Offset(0, 0.58),
  Offset(-0.32, 0.36),
  Offset(-0.46, 0.02),
  Offset(-0.46, -0.38),
];

class _VaultPainter extends CustomPainter {
  _VaultPainter({required this.t, required this.accent, required this.ring});

  final double t;
  final Color accent;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.46);
    final unit = math.min(size.width, size.height);

    _floor(canvas, size);

    // cincin belakang (setengah atas ellipse) digambar dulu
    _ring(canvas, center, unit * 0.36, 0.26, t * 2 * math.pi, ring, back: true);
    _ring(canvas, center, unit * 0.28, 0.42, -t * 2 * math.pi * 0.7,
        accent.withValues(alpha: 0.5), back: true, dashed: false);

    // brankas transparan
    final ry = t * 2 * math.pi;
    const rx = -0.38;
    final half = unit * 0.15;
    final faces = _projectCube(center: center, half: half, ry: ry, rx: rx);
    final fill = Paint()..color = accent.withValues(alpha: 0.07);
    final stroke = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round;

    // inti solid muter berlawanan arah
    final core = _projectCube(
      center: center,
      half: half * 0.36,
      ry: -ry * 2.3,
      rx: 0.55,
    );

    for (final f in faces) {
      if (f.depth >= 0) continue; // muka belakang dulu
      canvas.drawPath(_poly(f.points), fill);
      canvas.drawPath(_poly(f.points), stroke..color = accent.withValues(alpha: 0.45));
    }
    for (final f in core) {
      if (f.facing < 0) continue;
      final shade = (0.55 + f.facing * 0.45).clamp(0.0, 1.0);
      canvas.drawPath(
        _poly(f.points),
        Paint()..color = Color.lerp(C.accentDeep, accent, shade)!,
      );
      canvas.drawPath(
        _poly(f.points),
        Paint()
          ..color = C.accentSoft.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
    for (final f in faces) {
      if (f.depth < 0) continue;
      canvas.drawPath(_poly(f.points), fill);
      canvas.drawPath(_poly(f.points), stroke..color = accent);
      if (f.index == 0 || f.index == 1) {
        final icon = _shield.map((p) => _onFace(f.points, p.dx, p.dy)).toList();
        canvas.drawPath(
          _poly(icon),
          Paint()
            ..color = accent.withValues(alpha: 0.9)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8
            ..strokeJoin = StrokeJoin.round,
        );
      }
    }

    // cincin depan
    _ring(canvas, center, unit * 0.36, 0.26, t * 2 * math.pi, ring, back: false);
    _ring(canvas, center, unit * 0.28, 0.42, -t * 2 * math.pi * 0.7,
        accent.withValues(alpha: 0.5), back: false, dashed: false);

    // paket data melayang
    final packets = <(double, double, Color, double, bool)>[
      (0.16, 0.30, ring, 13.0, false),
      (0.82, 0.36, accent, 12.0, false),
      (0.78, 0.72, C.orange, 9.0, false),
      (0.20, 0.70, accent, 9.0, true),
    ];
    for (var i = 0; i < packets.length; i++) {
      final (px, py, color, s, hollow) = packets[i];
      final phase = t * 2 * math.pi * 4 + i * 1.6;
      final dy = math.sin(phase) * 8;
      canvas.save();
      canvas.translate(size.width * px, size.height * py + dy);
      canvas.rotate(math.sin(phase) * 0.8);
      final r = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: s, height: s),
        const Radius.circular(3),
      );
      canvas.drawRRect(
        r,
        Paint()
          ..color = color
          ..style = hollow ? PaintingStyle.stroke : PaintingStyle.fill
          ..strokeWidth = 1.5,
      );
      canvas.restore();
    }
  }

  void _floor(Canvas canvas, Size size) {
    final horizon = size.height * 0.52;
    final bottom = size.height;
    final vx = size.width / 2;
    final scroll = (t * 8) % 1;
    for (var i = -12; i <= 12; i++) {
      final xb = vx + i * size.width * 0.16;
      final p = Paint()
        ..color = C.accentTint.withValues(alpha: 0.9)
        ..strokeWidth = 1;
      canvas.drawLine(Offset(vx + i * 6, horizon), Offset(xb, bottom), p);
    }
    for (var j = 0; j < 9; j++) {
      final k = (j + scroll) / 9;
      final y = horizon + (bottom - horizon) * k * k;
      final a = (k * 1.4).clamp(0.0, 1.0);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = C.accentTint.withValues(alpha: a)
          ..strokeWidth = 1,
      );
    }
    // kabut di garis cakrawala
    final fade = Rect.fromLTWH(0, horizon - 2, size.width, (bottom - horizon) * 0.45);
    canvas.drawRect(
      fade,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [C.bg, Color(0x000F0B19)],
        ).createShader(fade),
    );
  }

  void _ring(
    Canvas canvas,
    Offset c,
    double r,
    double flat,
    double phase,
    Color color, {
    required bool back,
    bool dashed = true,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    const steps = 72;
    for (var i = 0; i < steps; i++) {
      if (dashed && i.isOdd) continue;
      final a0 = phase + i / steps * 2 * math.pi;
      final a1 = phase + (i + (dashed ? 0.7 : 1)) / steps * 2 * math.pi;
      final isBack = math.sin(a0) < 0;
      if (isBack != back) continue;
      final p0 = c + Offset(math.cos(a0) * r, math.sin(a0) * r * flat);
      final p1 = c + Offset(math.cos(a1) * r, math.sin(a1) * r * flat);
      canvas.drawLine(p0, p1, paint..color = back ? color.withValues(alpha: 0.45) : color);
    }
  }

  @override
  bool shouldRepaint(covariant _VaultPainter old) =>
      old.t != t || old.accent != accent || old.ring != ring;
}

// ---------------------------------------------------------------------------
// Peta level isometrik
// ---------------------------------------------------------------------------

enum IsoTileState { done, active, locked, soon }

class IsoTile {
  const IsoTile({required this.label, required this.state});
  final String label;
  final IsoTileState state;
}

/// Hitung posisi platform di layar. Dipakai painter & tombol chip.
class IsoLayout {
  /// Ukuran peta dihitung supaya muat di LEBAR dan TINGGI kotaknya,
  /// jadi gak pernah nutupin header atau kartu di bawahnya.
  IsoLayout(this.size, this.count) {
    final n = math.max(count, 1);
    _scale(1);
    var b = _bounds(n, Offset.zero);
    final fit = math.min(
      (size.width - 16 - chipSpace) / b.width,
      (size.height - 24) / b.height,
    );
    _scale(math.min(fit, maxTile));
    b = _bounds(n, Offset.zero);
    final usedW = b.width + chipSpace;
    origin = Offset(
      (size.width - usedW) / 2 + chipSpace - b.left,
      12 + (size.height - 24 - b.height) / 2 - b.top,
    );
  }

  /// Lebar chip label yang ditaruh di kiri tiap platform (+ jarak).
  static const double chipW = 100;
  static const double chipSpace = chipW + 8;

  /// Batas ukuran platform biar di tablet gak raksasa.
  static const double maxTile = 84;

  final Size size;
  final int count;
  double tile = 1, step = 1, rise = 0, thick = 0;
  Offset origin = Offset.zero;

  static const _k = 0.70710678;

  void _scale(double t) {
    tile = t;
    step = t / 0.72;
    rise = t * 0.32;
    thick = t * 0.16;
  }

  Rect _bounds(int n, Offset o) {
    final pts = <Offset>[
      for (var i = 0; i < n; i++) ...[..._quad(i, 0, o), ..._quad(i, -thick, o)],
    ];
    var r = Rect.fromLTRB(pts.first.dx, pts.first.dy, pts.first.dx, pts.first.dy);
    for (final p in pts) {
      r = r.expandToInclude(Rect.fromLTWH(p.dx, p.dy, 0, 0));
    }
    return r;
  }

  Offset _iso(double px, double py, double pz, Offset o) =>
      o + Offset((px + py) * _k, (py - px) * _k * 0.5 - pz * 0.866);

  List<Offset> _quad(int i, double dz, Offset o) {
    final x0 = i * step;
    final z = i * rise + dz;
    return [
      _iso(x0, 0, z, o),
      _iso(x0 + tile, 0, z, o),
      _iso(x0 + tile, tile, z, o),
      _iso(x0, tile, z, o),
    ];
  }

  List<Offset> top(int i) => _quad(i, 0, origin);

  List<Offset> bottom(int i) => _quad(i, -thick, origin);

  Offset center(int i) {
    final q = top(i);
    return (q[0] + q[2]) / 2;
  }

  /// Sudut kiri diamond platform ke-i.
  Offset leftCorner(int i) => top(i)[0];
}

class IsoMap extends StatefulWidget {
  const IsoMap({super.key, required this.tiles, required this.onTap});

  final List<IsoTile> tiles;
  final ValueChanged<int> onTap;

  @override
  State<IsoMap> createState() => _IsoMapState();
}

class _IsoMapState extends State<IsoMap> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final size = Size(box.maxWidth, box.maxHeight);
        final layout = IsoLayout(size, widget.tiles.length);
        return ClipRect(
          child: Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) => CustomPaint(
                    painter: _IsoPainter(layout, widget.tiles, _c.value),
                  ),
                ),
              ),
            ),
            for (var i = 0; i < widget.tiles.length; i++)
              _chip(layout, i),
          ],
          ),
        );
      },
    );
  }

  Widget _chip(IsoLayout layout, int i) {
    final tile = widget.tiles[i];
    final c = layout.center(i);
    final active = tile.state == IsoTileState.active;
    final done = tile.state == IsoTileState.done;
    final bg = active ? C.accent : (done ? C.okTint : C.surface);
    final fg = active ? C.onAccent : (done ? C.ok : C.muted);
    final border = active ? C.accentSoft : (done ? C.okDeep : C.lineStrong);
    final corner = layout.leftCorner(i);
    return Positioned(
      left: corner.dx - IsoLayout.chipSpace,
      top: c.dy - 22,
      width: IsoLayout.chipW,
      height: 44,
      child: Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
            side: BorderSide(color: border),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(9),
            onTap: () => widget.onTap(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text(
                tile.label,
                maxLines: 1,
                style: mono(size: 10.5, color: fg, weight: FontWeight.w800, spacing: 0),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IsoPainter extends CustomPainter {
  _IsoPainter(this.layout, this.tiles, this.t);

  final IsoLayout layout;
  final List<IsoTile> tiles;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    // titik jalur antar platform
    for (var i = 0; i < tiles.length - 1; i++) {
      final a = layout.center(i);
      final b = layout.center(i + 1);
      for (var k = 1; k <= 3; k++) {
        final p = Offset.lerp(a, b, k / 4)!;
        canvas.drawCircle(p + const Offset(0, 6), 2.2, Paint()..color = C.lineStrong);
      }
    }

    // gambar dari belakang (index besar) ke depan
    for (var i = tiles.length - 1; i >= 0; i--) {
      final tile = tiles[i];
      final top = layout.top(i);
      final bot = layout.bottom(i);
      final (Color face, Color side, Color edge) = switch (tile.state) {
        IsoTileState.active => (C.accent, C.accentDeep, C.accentSoft),
        IsoTileState.done => (C.ok, C.okDeep, C.mint),
        _ => (C.surface2, C.bgDeep, C.lineStrong),
      };

      if (tile.state == IsoTileState.active) {
        final glow = Paint()
          ..color = C.accent.withValues(alpha: 0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
        canvas.drawPath(Path()..addPolygon(top, true), glow);
      }

      // sisi kiri-depan (x = x0) dan kanan-depan (y = tile)
      final left = [top[0], top[3], bot[3], bot[0]];
      final right = [top[3], top[2], bot[2], bot[3]];
      canvas.drawPath(Path()..addPolygon(left, true), Paint()..color = side);
      canvas.drawPath(
        Path()..addPolygon(right, true),
        Paint()..color = Color.lerp(side, Colors.black, 0.25)!,
      );
      canvas.drawPath(Path()..addPolygon(top, true), Paint()..color = face);
      canvas.drawPath(
        Path()..addPolygon(top, true),
        Paint()
          ..color = edge
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );

      final c = layout.center(i);
      final s = layout.tile * 0.16;
      final iconPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      switch (tile.state) {
        case IsoTileState.active:
          // denyut "kamu di sini": rhombus mengembang di permukaan
          final k = 0.35 + t * 0.55;
          final q = top.map((p) => c + (p - c) * k).toList();
          canvas.drawPath(
            Path()..addPolygon(q, true),
            iconPaint
              ..color = C.onAccent.withValues(alpha: (1 - t).clamp(0.0, 1.0))
              ..strokeWidth = 2.4,
          );
          canvas.drawCircle(c, s * 0.45, Paint()..color = C.onAccent);
        case IsoTileState.done:
          canvas.drawPath(
            Path()
              ..moveTo(c.dx - s, c.dy)
              ..lineTo(c.dx - s * 0.2, c.dy + s * 0.7)
              ..lineTo(c.dx + s * 1.1, c.dy - s * 0.6),
            iconPaint..color = C.onAccent,
          );
        case IsoTileState.locked:
        case IsoTileState.soon:
          final body = RRect.fromRectAndRadius(
            Rect.fromCenter(center: c + Offset(0, s * 0.35), width: s * 1.6, height: s * 1.2),
            Radius.circular(s * 0.25),
          );
          iconPaint
            ..color = tile.state == IsoTileState.soon ? C.line : C.muted.withValues(alpha: 0.7)
            ..strokeWidth = 1.8;
          canvas.drawRRect(body, iconPaint);
          canvas.drawArc(
            Rect.fromCenter(center: c - Offset(0, s * 0.25), width: s, height: s * 1.1),
            math.pi,
            math.pi,
            false,
            iconPaint,
          );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _IsoPainter old) =>
      old.t != t || old.tiles != tiles || old.layout.size != layout.size;
}

// ---------------------------------------------------------------------------
// Tumpukan kartu 3D buat header materi
// ---------------------------------------------------------------------------

class TiltDeck extends StatefulWidget {
  const TiltDeck({super.key, required this.child, this.height = 200});

  final Widget child;
  final double height;

  @override
  State<TiltDeck> createState() => _TiltDeckState();
}

class _TiltDeckState extends State<TiltDeck> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return SizedBox(
      height: widget.height + 34,
      child: AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (context, child) {
          final v = reduce ? 0.5 : Curves.easeInOut.transform(_c.value);
          // miring tipis aja: kerasa ada kedalaman, tapi teks tetap lurus & gak kepotong
          final m = Matrix4.identity()
            ..setEntry(3, 2, 0.0008)
            ..rotateX(0.07 - v * 0.03)
            ..rotateY(-0.025 + v * 0.05);
          return Transform(
            alignment: Alignment.center,
            transform: m,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 34, 6, 0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _back(-30, 0.88, const Color(0xFF120E1F), C.line),
                  _back(-15, 0.94, const Color(0xFF171126), C.lineStrong),
                  Container(
                    height: widget.height,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D1631),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: C.accentDeep),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xCC000000),
                          blurRadius: 30,
                          offset: Offset(0, 18),
                          spreadRadius: -12,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(18),
                    child: child,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _back(double dy, double scale, Color color, Color border) {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      height: widget.height,
      child: Transform.translate(
        offset: Offset(0, dy),
        child: Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: border),
            ),
          ),
        ),
      ),
    );
  }
}
