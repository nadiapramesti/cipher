import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme.dart';
import '../core/models.dart';
import '../l10n/strings.dart';

/// Adegan 3D interaktif: muter pelan sendiri, bisa digeser pakai jari.
class LessonScene extends StatefulWidget {
  const LessonScene({super.key, required this.spec, this.height = 230});

  final SceneSpec spec;
  final double height;

  @override
  State<LessonScene> createState() => _LessonSceneState();
}

class _LessonSceneState extends State<LessonScene> with SingleTickerProviderStateMixin {
  late final AnimationController _clock =
      AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
  double _yaw = -0.62;
  double _pitch = 0.52;
  bool _dragging = false;

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: C.bgDeep,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: C.lineStrong),
        boxShadow: [BoxShadow(color: C.accentDeep.withValues(alpha: 0.35), offset: const Offset(0, 6))],
      ),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        onPanStart: (_) {
          _dragging = true;
          HapticFeedback.selectionClick();
        },
        onPanUpdate: (d) => setState(() {
          _yaw += d.delta.dx * 0.012;
          _pitch = (_pitch + d.delta.dy * 0.008).clamp(0.12, 1.15);
        }),
        onPanEnd: (_) => _dragging = false,
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _clock,
                builder: (_, __) {
                  if (!_dragging) _yaw += 0.0016;
                  return CustomPaint(
                    painter: _ScenePainter(
                      spec: widget.spec,
                      t: _clock.value,
                      yaw: _yaw,
                      pitch: _pitch,
                      dark: C.isDark,
                    ),
                  );
                },
              ),
            ),
            Positioned(
              right: 10,
              bottom: 8,
              child: Row(children: [
                Icon(Icons.threed_rotation_rounded, size: 14, color: C.hint),
                const SizedBox(width: 4),
                Text(tr('scene_drag'), style: mono(size: 9.5, color: C.hint)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mesin 3D mini: kamera yaw/pitch + perspektif, kotak bershading, painter's algorithm.

class V3 {
  const V3(this.x, this.y, this.z);
  final double x, y, z;
  V3 operator +(V3 o) => V3(x + o.x, y + o.y, z + o.z);
  V3 operator *(double s) => V3(x * s, y * s, z * s);
  static V3 lerp(V3 a, V3 b, double t) => V3(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t, a.z + (b.z - a.z) * t);
}

class _Cam {
  _Cam(this.size, this.yaw, this.pitch)
      : center = Offset(size.width / 2, size.height * 0.56),
        unit = math.min(size.width, size.height * 1.5) / 9.5;
  final Size size;
  final double yaw, pitch;
  final Offset center;
  final double unit;

  /// Ruang kamera: x kanan, y atas, z ke arah penonton.
  V3 view(V3 p) {
    final cy = math.cos(yaw), sy = math.sin(yaw);
    final x1 = p.x * cy - p.z * sy;
    final z1 = p.x * sy + p.z * cy;
    final cp = math.cos(pitch), sp = math.sin(pitch);
    final y2 = p.y * cp - z1 * sp;
    final z2 = p.y * sp + z1 * cp;
    return V3(x1, y2, z2);
  }

  Offset project(V3 v) {
    const d = 16.0;
    final s = d / (d - v.z);
    return center + Offset(v.x * s * unit, -v.y * s * unit);
  }

  Offset at(V3 p) => project(view(p));
}

class _Poly {
  _Poly(this.pts, this.depth, this.fill, this.stroke, {this.glow = false});
  final List<Offset> pts;
  final double depth;
  final Color fill;
  final Color? stroke;
  final bool glow;
}

class _Text {
  _Text(this.pos, this.text, this.color, this.depth, {this.size = 10.5, this.chip = false});
  final Offset pos;
  final String text;
  final Color color;
  final double depth;
  final double size;
  final bool chip;
}

const _boxFaces = <(List<int>, V3)>[
  ([4, 5, 7, 6], V3(0, 0, 1)),
  ([1, 0, 2, 3], V3(0, 0, -1)),
  ([5, 1, 3, 7], V3(1, 0, 0)),
  ([0, 4, 6, 2], V3(-1, 0, 0)),
  ([2, 3, 7, 6], V3(0, 1, 0)),
  ([0, 1, 5, 4], V3(0, -1, 0)),
];

class _ScenePainter extends CustomPainter {
  _ScenePainter({required this.spec, required this.t, required this.yaw, required this.pitch, required this.dark});

  final SceneSpec spec;
  final double t; // 0..1 berulang
  final double yaw, pitch;
  final bool dark;

  late _Cam cam;
  final _polys = <_Poly>[];
  final _texts = <_Text>[];
  final _lines = <(Offset, Offset, Color, double, double)>[]; // a, b, warna, tebal, depth

  static const _light = V3(-0.45, 0.8, 0.55);

  Color _shade(Color c, V3 nView) {
    final l = math.sqrt(_light.x * _light.x + _light.y * _light.y + _light.z * _light.z);
    final dot = (nView.x * _light.x + nView.y * _light.y + nView.z * _light.z) / l;
    final k = 0.52 + 0.48 * dot.clamp(0.0, 1.0);
    return Color.lerp(Colors.black, c, k)!;
  }

  void box(V3 c, V3 h, Color color, {Color? edge, bool glow = false}) {
    final corners = List.generate(8, (i) {
      return cam.view(V3(
        c.x + (i & 1 == 1 ? h.x : -h.x),
        c.y + (i & 2 == 2 ? h.y : -h.y),
        c.z + (i & 4 == 4 ? h.z : -h.z),
      ));
    });
    for (final (idx, n) in _boxFaces) {
      final nv = cam.view(n);
      if (nv.z <= 0.001) continue;
      final vs = idx.map((i) => corners[i]).toList();
      final depth = vs.fold(0.0, (s, v) => s + v.z) / 4;
      _polys.add(_Poly(vs.map(cam.project).toList(), depth, _shade(color, nv), edge, glow: glow));
    }
  }

  void label(V3 p, String text, {Color? color, double size = 10.5, bool chip = true}) {
    final v = cam.view(p);
    _texts.add(_Text(cam.project(v), text, color ?? C.text, v.z, size: size, chip: chip));
  }

  void line(V3 a, V3 b, Color color, {double w = 1.4, bool back = false}) {
    final va = cam.view(a), vb = cam.view(b);
    _lines.add((cam.project(va), cam.project(vb), color, w, back ? -100 : (va.z + vb.z) / 2 - 0.05));
  }

  void floor(double half, {double y = 0}) {
    final c = C.line.withValues(alpha: dark ? 0.9 : 0.7);
    for (var i = -half; i <= half + 0.001; i += 1) {
      line(V3(i, y, -half), V3(i, y, half), c, w: 1, back: true);
      line(V3(-half, y, i), V3(half, y, i), c, w: 1, back: true);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    cam = _Cam(size, yaw, pitch);
    switch (spec.kind) {
      case 'packets':
        _packets();
      case 'layers':
        _layers();
      case 'vault':
        _vault();
      case 'wheel':
        _wheel();
      case 'hash':
        _hash();
      case 'subnet':
        _subnet();
      case 'firewall':
        _firewall();
      case 'tree':
        _tree();
      case 'scan':
        _scan();
      case 'keys':
        _keys();
      case 'botnet':
        _botnet();
    }

    // garis lantai digambar duluan (selalu di belakang objek)
    for (final (a, b, c, w, _) in _lines.where((l) => l.$5 < -50)) {
      canvas.drawLine(a, b, Paint()..color = c..strokeWidth = w);
    }
    final items = <(double, void Function())>[
      for (final p in _polys)
        (p.depth, () {
          final path = Path()..addPolygon(p.pts, true);
          if (p.glow) {
            canvas.drawPath(path, Paint()..color = p.fill.withValues(alpha: 0.55)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
          }
          canvas.drawPath(path, Paint()..color = p.fill);
          if (p.stroke != null) {
            canvas.drawPath(path, Paint()..color = p.stroke!..style = PaintingStyle.stroke..strokeWidth = 1.2..strokeJoin = StrokeJoin.round);
          }
        }),
      for (final (a, b, c, w, d) in _lines.where((l) => l.$5 >= -50))
        (d, () => canvas.drawLine(a, b, Paint()..color = c..strokeWidth = w..strokeCap = StrokeCap.round)),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    for (final (_, draw) in items) {
      draw();
    }
    _texts.sort((a, b) => a.depth.compareTo(b.depth));
    for (final tx in _texts) {
      _drawText(canvas, tx);
    }
  }

  void _drawText(Canvas canvas, _Text tx) {
    final tp = TextPainter(
      text: TextSpan(text: tx.text, style: mono(size: tx.size, color: tx.color, weight: FontWeight.w700, spacing: 0)),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: 140);
    final pos = tx.pos - Offset(tp.width / 2, tp.height / 2);
    if (tx.chip) {
      final r = RRect.fromRectAndRadius(Rect.fromLTWH(pos.dx - 6, pos.dy - 3, tp.width + 12, tp.height + 6), const Radius.circular(7));
      canvas.drawRRect(r, Paint()..color = C.surface.withValues(alpha: 0.92));
      canvas.drawRRect(r, Paint()..color = C.lineStrong..style = PaintingStyle.stroke..strokeWidth = 1);
    }
    tp.paint(canvas, pos);
  }

  // --- adegan -----------------------------------------------------------------

  double _wave(double phase) => (math.sin((t + phase) * math.pi * 2) + 1) / 2;

  /// Paket data lewat beberapa titik: client -> router -> ISP -> server.
  void _packets() {
    floor(4);
    final nodes = [const V3(-3.2, 0.5, 1.2), const V3(-1, 0.5, -0.6), const V3(1.2, 0.5, 0.8), const V3(3.2, 0.9, -1)];
    final sizes = [const V3(0.5, 0.5, 0.5), const V3(0.45, 0.3, 0.45), const V3(0.45, 0.3, 0.45), const V3(0.6, 0.9, 0.6)];
    final names = [spec.label(0, 'HP'), spec.label(1, 'Router'), spec.label(2, 'ISP'), spec.label(3, 'Server')];
    for (var i = 0; i < nodes.length; i++) {
      box(nodes[i], sizes[i], i == 0 ? C.accent : (i == 3 ? C.ok : C.surface2), edge: C.lineStrong);
      label(nodes[i] + V3(0, sizes[i].y + 0.55, 0), names[i]);
      if (i > 0) line(nodes[i - 1], nodes[i], C.accent.withValues(alpha: 0.45), w: 2);
    }
    for (var k = 0; k < 5; k++) {
      final u = (t * 1.6 + k / 5) % 1.0;
      final seg = (u * 3).floor().clamp(0, 2);
      final p = V3.lerp(nodes[seg], nodes[seg + 1], u * 3 - seg) + const V3(0, 0.55, 0);
      box(p, const V3(0.13, 0.13, 0.13), k.isEven ? C.yellow : C.mint, glow: true);
    }
  }

  /// Lapisan bertumpuk (pertahanan berlapis / OSI / dll.).
  void _layers() {
    final n = spec.labels.isEmpty ? 4 : spec.labels.length.clamp(2, 6);
    final spread = 0.15 + 0.25 * _wave(0);
    final colors = [C.accent, C.ok, C.yellow, C.orange, C.mint, C.red];
    for (var i = 0; i < n; i++) {
      final y = i * (0.42 + spread);
      final w = 2.4 - i * 0.22;
      box(V3(0, y, 0), V3(w, 0.16, w * 0.8), colors[i % colors.length], edge: C.bgDeep);
      label(V3(w + 1.1, y + 0.1, 0), spec.label(i, 'L$i'), size: 10);
    }
    final top = (n - 1) * (0.42 + spread) + 0.6;
    box(V3(0, top + 0.25 * math.sin(t * math.pi * 4), 0), const V3(0.22, 0.22, 0.22), C.red, glow: true);
  }

  /// Brankas dengan kunci yang muter (enkripsi).
  void _vault() {
    floor(3);
    box(const V3(0, 1.1, 0), const V3(1.1, 1.1, 1.1), C.surface2, edge: C.accent);
    box(const V3(0, 1.1, 1.12), const V3(0.5, 0.5, 0.04), C.accent);
    box(const V3(0, 1.1, 1.18), const V3(0.12, 0.12, 0.06), C.yellow, glow: true);
    final a = t * math.pi * 2;
    final k = V3(math.cos(a) * 2.3, 1.6 + 0.3 * math.sin(a * 2), math.sin(a) * 2.3);
    box(k, const V3(0.32, 0.09, 0.09), C.yellow, glow: true);
    box(k + const V3(-0.38, 0, 0), const V3(0.12, 0.2, 0.12), C.yellow);
    label(const V3(0, 2.75, 0), spec.label(0, 'DATA'), color: C.accent);
    label(k + const V3(0, 0.5, 0), spec.label(1, 'KEY'), size: 9.5);
  }

  /// Roda Caesar: cincin luar diam, cincin dalam bergeser.
  void _wheel() {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final shift = int.tryParse(spec.label(0, '3')) ?? 3;
    final rot = (shift / 26) * math.pi * 2 * (0.5 + 0.5 * _wave(0.25));
    for (var i = 0; i < 26; i++) {
      final a = i / 26 * math.pi * 2;
      final outer = V3(math.cos(a) * 3.2, 0, math.sin(a) * 3.2);
      final inner = V3(math.cos(a - rot) * 2.2, 0.35, math.sin(a - rot) * 2.2);
      box(outer, const V3(0.22, 0.08, 0.22), i == 0 ? C.accent : C.surface2);
      box(inner, const V3(0.2, 0.08, 0.2), i == 0 ? C.ok : C.surface);
      label(outer + const V3(0, 0.35, 0), letters[i], chip: false, size: 10, color: i == 0 ? C.accent : C.textSoft);
      label(inner + const V3(0, 0.4, 0), letters[(i + shift) % 26], chip: false, size: 9.5, color: i == 0 ? C.ok : C.muted);
    }
    box(const V3(0, 0.2, 0), const V3(0.5, 0.2, 0.5), C.accentDeep);
    label(const V3(0, 1.0, 0), '+$shift', color: C.accent);
  }

  /// Hash: blok data masuk mesin, keluar sidik jari ukuran tetap.
  void _hash() {
    floor(4);
    final u = t * 2 % 1.0;
    final sizes = [0.25, 0.55, 0.38];
    for (var k = 0; k < 3; k++) {
      final p = ((u + k / 3) % 1.0);
      if (p < 0.5) {
        box(V3(-3.4 + p * 2 * 2.6, 0.5, (k - 1) * 0.9), V3(sizes[k], sizes[k], sizes[k]), [C.accent, C.orange, C.mint][k]);
      } else {
        box(V3(1.0 + (p - 0.5) * 2 * 2.4, 0.3, (k - 1) * 0.9), const V3(0.42, 0.06, 0.18), C.ok, glow: true);
      }
    }
    box(const V3(0, 0.8, 0), const V3(0.75, 0.8, 1.6), C.surface2, edge: C.accent);
    label(const V3(0, 2.1, 0), spec.label(0, 'SHA-256'), color: C.accent);
    label(const V3(-3, 1.5, 0), spec.label(1, 'input'));
    label(const V3(3, 1.2, 0), spec.label(2, 'hash'));
  }

  /// Blok perumahan = subnet, gedung = host.
  void _subnet() {
    floor(4);
    final groups = [(const V3(-2, 0, -1.6), C.accent), (const V3(2, 0, -1.6), C.ok), (const V3(0, 0, 2), C.orange)];
    for (var g = 0; g < groups.length; g++) {
      final (c, col) = groups[g];
      box(c + const V3(0, 0.05, 0), const V3(1.6, 0.05, 1.2), col.withValues(alpha: 0.35));
      for (var i = 0; i < 4; i++) {
        final h = 0.3 + ((i * 7 + g * 3) % 5) * 0.12;
        box(c + V3((i % 2) * 1.4 - 0.7, h + 0.1, (i ~/ 2) * 1.0 - 0.5), V3(0.32, h, 0.32), col);
      }
      label(c + const V3(0, 1.9, 0), spec.label(g, ['192.168.1.0/24', '192.168.2.0/24', '10.0.0.0/24'][g]), size: 9.5);
    }
    box(V3(0, 0.6 + 0.1 * math.sin(t * math.pi * 2), 0), const V3(0.4, 0.4, 0.4), C.yellow, glow: true);
    label(const V3(0, 1.4, 0.0), spec.label(3, 'router'), size: 9.5);
  }

  /// Tembok api: paket hijau lewat, paket merah mantul.
  void _firewall() {
    floor(4);
    for (var i = -3; i <= 3; i++) {
      for (var j = 0; j < 3; j++) {
        box(V3(0, 0.3 + j * 0.6, i * 0.6 + (j.isOdd ? 0.3 : 0)), const V3(0.25, 0.28, 0.28), j == 2 ? C.orange : C.red, edge: C.bgDeep);
      }
    }
    for (var k = 0; k < 6; k++) {
      final p = (t * 1.4 + k / 6) % 1.0;
      final good = k % 3 != 0;
      final z = (k - 2.5) * 0.7;
      final double x;
      if (good) {
        x = -3.5 + p * 7;
      } else {
        x = p < 0.5 ? -3.5 + p * 6.4 : -0.3 - (p - 0.5) * 6.4;
      }
      final y = good ? 2.3 : 0.9;
      if (good) line(V3(x, y, z), V3(x - 0.6, y, z), C.ok.withValues(alpha: 0.5));
      box(V3(x, y, z), const V3(0.16, 0.16, 0.16), good ? C.ok : C.red, glow: true);
    }
    label(const V3(0, 2.6, 2.6), spec.label(0, 'FIREWALL'), color: C.orange);
    label(const V3(-3.2, 1.6, -2.6), spec.label(1, 'internet'), size: 9.5);
    label(const V3(3.2, 1.6, -2.6), spec.label(2, 'LAN'), size: 9.5);
  }

  /// Pohon (DNS / hierarki).
  void _tree() {
    floor(4);
    const root = V3(0, 2.6, 0);
    final mid = [const V3(-2.2, 1.4, -0.8), const V3(2.2, 1.4, 0.8)];
    final leaves = [const V3(-3, 0.3, -1.6), const V3(-1.4, 0.3, 0.2), const V3(1.6, 0.3, 1.8), const V3(3, 0.3, -0.2)];
    for (var i = 0; i < 2; i++) {
      line(root, mid[i], C.accent.withValues(alpha: 0.6), w: 2);
      for (var j = 0; j < 2; j++) {
        line(mid[i], leaves[i * 2 + j], C.accent.withValues(alpha: 0.6), w: 2);
      }
    }
    final pulse = 0.04 * math.sin(t * math.pi * 8);
    box(root, V3(0.4 + pulse, 0.25, 0.4 + pulse), C.accent, glow: true);
    label(root + const V3(0, 0.75, 0), spec.label(0, '.'));
    for (var i = 0; i < 2; i++) {
      box(mid[i], const V3(0.35, 0.22, 0.35), C.ok);
      label(mid[i] + const V3(0, 0.7, 0), spec.label(1 + i, ['.id', '.com'][i]), size: 9.5);
    }
    for (var i = 0; i < 4; i++) {
      box(leaves[i], const V3(0.3, 0.3, 0.3), C.surface2, edge: C.lineStrong);
      label(leaves[i] + const V3(0, 0.75, 0), spec.label(3 + i, ['co.id', 'go.id', 'google', 'github'][i]), size: 9);
    }
    // kueri DNS yang jalan turun
    final p = t * 2 % 1.0;
    final path = [root, mid[0], leaves[0]];
    final s = (p * 2).floor().clamp(0, 1);
    box(V3.lerp(path[s], path[s + 1], p * 2 - s) + const V3(0, 0.35, 0), const V3(0.12, 0.12, 0.12), C.yellow, glow: true);
  }

  /// Pindai file: satu yang merah ketahuan.
  void _scan() {
    floor(4);
    final sweep = -3 + (t * 1.5 % 1.0) * 6;
    for (var i = 0; i < 4; i++) {
      for (var j = 0; j < 3; j++) {
        final x = -2.4 + i * 1.6;
        final bad = i == 2 && j == 1;
        final hit = (x - sweep).abs() < 0.5;
        box(V3(x, 0.4, (j - 1) * 1.4), const V3(0.42, 0.4, 0.3),
            bad && sweep > x ? C.red : (hit ? C.yellow : C.surface2),
            edge: C.lineStrong, glow: bad && sweep > x);
      }
    }
    box(V3(sweep, 1.6, 0), const V3(0.05, 0.6, 2.4), C.mint.withValues(alpha: 0.8), glow: true);
    label(const V3(0.8, 1.6, -1.4), spec.label(0, '!'), color: C.red);
    label(V3(sweep, 2.6, 0), spec.label(1, 'scan'), size: 9.5);
  }

  /// Kunci publik (gembok) & kunci privat (anak kunci).
  void _keys() {
    floor(3.5);
    const pub = V3(-1.8, 0.9, 0);
    const priv = V3(1.8, 0.9, 0);
    box(pub, const V3(0.8, 0.6, 0.35), C.accent, edge: C.bgDeep);
    box(pub + const V3(0, 0.85, 0), const V3(0.45, 0.25, 0.12), C.accent);
    box(priv, const V3(0.7, 0.18, 0.18), C.yellow, glow: true);
    box(priv + const V3(-0.85, 0, 0), const V3(0.25, 0.35, 0.18), C.yellow);
    label(pub + const V3(0, 1.7, 0), spec.label(0, 'public'));
    label(priv + const V3(0, 1.0, 0), spec.label(1, 'private'), color: C.yellow);
    final p = t * 2 % 1.0;
    final msg = V3.lerp(const V3(-4, 0.9, 1.6), const V3(4, 0.9, 1.6), p);
    final locked = msg.x > pub.x && msg.x < priv.x;
    box(msg, const V3(0.3, 0.2, 0.05), locked ? C.accent : C.ok, glow: true);
  }

  /// Botnet: banyak perangkat nyerang satu server.
  void _botnet() {
    floor(4);
    const target = V3(0, 0.9, 0);
    box(target, const V3(0.6, 0.9, 0.6), C.ok, edge: C.lineStrong);
    label(target + const V3(0, 1.5, 0), spec.label(0, 'server'));
    for (var i = 0; i < 9; i++) {
      final a = i / 9 * math.pi * 2;
      final bot = V3(math.cos(a) * 3.3, 0.3, math.sin(a) * 3.3);
      box(bot, const V3(0.25, 0.25, 0.25), C.red);
      final p = (t * 3 + i / 9) % 1.0;
      box(V3.lerp(bot, target, p), const V3(0.08, 0.08, 0.08), C.orange, glow: true);
    }
    label(const V3(3.3, 1.1, 0), spec.label(1, 'bot'), size: 9.5, color: C.red);
  }

  @override
  bool shouldRepaint(_ScenePainter old) => true;
}
