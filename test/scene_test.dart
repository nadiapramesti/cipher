import 'package:cipher/core/content_repository.dart';
import 'package:cipher/core/models.dart';
import 'package:cipher/features/tools/cheatsheet_screen.dart';
import 'package:cipher/l10n/strings.dart';
import 'package:cipher/widgets/lesson_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('SceneSpec cuma menerima jenis adegan yang dikenal', () {
    expect(SceneSpec.fromJson({'kind': 'vault'})?.kind, 'vault');
    expect(SceneSpec.fromJson({'kind': 'naga'}), isNull);
    expect(SceneSpec.fromJson(null), isNull);
    expect(const SceneSpec('vault', ['A']).label(3, 'x'), 'x');
  });

  test('adegan 3D ID dan EN sejajar di semua materi', () async {
    final id = await Content.load('id');
    final en = await Content.load('en');
    var total = 0;
    for (final key in id.modules.keys) {
      final a = id.modules[key]!.pages, b = en.modules[key]!.pages;
      for (var i = 0; i < a.length; i++) {
        expect(b[i].visual?.kind, a[i].visual?.kind, reason: '$key hal $i');
        expect(b[i].visual?.labels.length, a[i].visual?.labels.length, reason: '$key hal $i');
        if (a[i].visual != null) total++;
      }
    }
    expect(total, greaterThan(40));
    expect(id.levels.length, 10);
  });

  for (final kind in SceneSpec.kinds) {
    testWidgets('adegan "$kind" bisa digambar dan diputer', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Center(child: SizedBox(width: 360, child: LessonScene(spec: SceneSpec(kind))))),
      ));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.drag(find.byType(LessonScene), const Offset(80, 20));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });
  }

  test('contekan perintah ID dan EN sejajar', () async {
    L.lang = AppLang.id;
    final id = await loadCheatsheet();
    L.lang = AppLang.en;
    final en = await loadCheatsheet();
    L.lang = AppLang.id;
    expect(en.length, id.length);
    for (var i = 0; i < id.length; i++) {
      expect(en[i].items.map((e) => e.$1), id[i].items.map((e) => e.$1));
    }
  });
}
