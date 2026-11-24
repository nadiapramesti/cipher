import 'package:cipher/widgets/scene3d.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // HP kecil, HP biasa, HP lebar, tablet
  const sizes = [Size(320, 300), Size(360, 300), Size(412, 300), Size(742, 300), Size(1000, 300)];

  for (final size in sizes) {
    test('peta level muat di ${size.width.toInt()}x${size.height.toInt()}', () {
      final layout = IsoLayout(size, 5);
      for (var i = 0; i < 5; i++) {
        for (final p in [...layout.top(i), ...layout.bottom(i)]) {
          expect(p.dx, inInclusiveRange(0, size.width), reason: 'tile $i keluar kiri/kanan');
          expect(p.dy, inInclusiveRange(0, size.height), reason: 'tile $i keluar atas/bawah');
        }
        final chipLeft = layout.leftCorner(i).dx - IsoLayout.chipSpace;
        expect(chipLeft, greaterThanOrEqualTo(0), reason: 'chip $i kepotong kiri');
        final cy = layout.center(i).dy;
        expect(cy - 22, greaterThanOrEqualTo(0), reason: 'chip $i kepotong atas');
      }
      expect(layout.tile, lessThanOrEqualTo(IsoLayout.maxTile));
    });
  }
}
