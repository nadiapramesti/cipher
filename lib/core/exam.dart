import 'dart:math';

import 'content_repository.dart';
import 'models.dart';

/// Ujian akhir level: soal acak dari semua modul di level itu, lulus kalau skor >= [examPassPercent].
const examPassPercent = 80;
const examQuestionCount = 10;

String examKey(int level) => 'exam-$level';
bool isExamKey(String key) => key.startsWith('exam-');

class ExamSet {
  const ExamSet(this.level, this.module, this.sourceKeys);
  final Level level;

  /// Modul sintetis berisi soal ujian (biar bisa dipakai QuizScreen).
  final LearnModule module;

  /// Asal tiap soal, format "modulId#index" (buat antrean ulasan).
  final List<String> sourceKeys;
}

/// Ambil soal secara merata dari tiap modul, lalu acak.
ExamSet buildExam(Content content, Level level, String title, {int count = examQuestionCount, Random? rng}) {
  final r = rng ?? Random();
  final pools = <List<(String, QuizQuestion)>>[
    for (final m in content.modulesOf(level))
      ([for (var i = 0; i < m.quiz.length; i++) ('${m.id}#$i', m.quiz[i])]..shuffle(r)),
  ];
  final picked = <(String, QuizQuestion)>[];
  var round = 0;
  while (picked.length < count && pools.any((p) => p.length > round)) {
    for (final p in pools) {
      if (round < p.length && picked.length < count) picked.add(p[round]);
    }
    round++;
  }
  picked.shuffle(r);
  return ExamSet(
    level,
    LearnModule(
      id: examKey(level.index),
      level: level.index,
      title: title,
      summary: '',
      minutes: picked.length,
      pages: const [],
      quiz: [for (final p in picked) p.$2],
    ),
    [for (final p in picked) p.$1],
  );
}
