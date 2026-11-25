import 'package:cipher/widgets/city_map.dart';
import 'package:cipher/widgets/scene3d.dart' show IsoTileState;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('gedung punya jarak tetap jadi label gak tabrakan', () {
    for (var i = 1; i < 14; i++) {
      final a = CityMap.baseOf(i - 1, 250), b = CityMap.baseOf(i, 250);
      expect(b.dx - a.dx, CityMap.spacing);
      // ruang atas buat pin + ruang bawah buat label
      expect(b.dy - 104, greaterThanOrEqualTo(0));
      expect(b.dy + 46, lessThanOrEqualTo(250));
    }
  });

  testWidgets('peta 14 level bisa digambar, digeser, dan diketuk', (tester) async {
    int? tapped;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 380,
          child: CityMap(
            nodes: [
              for (var i = 0; i < 14; i++)
                CityNode(
                  code: 'LV.${i.toString().padLeft(2, '0')}',
                  state: i < 2 ? IsoTileState.done : (i == 2 ? IsoTileState.active : IsoTileState.locked),
                  tier: i <= 1 ? 0 : (i <= 5 ? 1 : (i <= 9 ? 2 : 3)),
                  progress: i <= 2 ? '1/4' : null,
                ),
            ],
            current: 2,
            onTap: (i) => tapped = i,
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('LV.02'));
    expect(tapped, 2);
    await tester.drag(find.byType(SingleChildScrollView), const Offset(-600, 0));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('LV.13'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
