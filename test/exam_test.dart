import 'dart:math';

import 'package:cipher/core/content_repository.dart';
import 'package:cipher/core/exam.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ujian ambil soal merata dari semua modul level', () async {
    final c = await Content.load('id');
    for (final level in c.levels.where((l) => l.available)) {
      final set = buildExam(c, level, 'x', rng: Random(7));
      expect(set.module.quiz.length, examQuestionCount, reason: level.code);
      expect(set.sourceKeys.toSet().length, set.sourceKeys.length, reason: 'soal gak boleh dobel');
      final fromModules = set.sourceKeys.map((k) => k.split('#').first).toSet();
      final n = level.moduleIds.length;
      expect(fromModules.length, n < examQuestionCount ? n : examQuestionCount, reason: level.code);
      for (var i = 0; i < set.sourceKeys.length; i++) {
        final p = set.sourceKeys[i].split('#');
        expect(c.modules[p.first]!.quiz[int.parse(p.last)].prompt, set.module.quiz[i].prompt);
      }
    }
  });

  test('kunci ujian dibedain dari id modul', () {
    expect(examKey(3), 'exam-3');
    expect(isExamKey('exam-3'), isTrue);
    expect(isExamKey('lv3-tls'), isFalse);
  });
}
