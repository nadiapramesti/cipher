import 'package:cipher/core/models.dart';
import 'package:cipher/features/quiz/quiz_logic.dart';
import 'package:flutter_test/flutter_test.dart';

QuizQuestion _q(int level) => QuizQuestion(
      prompt: 'soal lv$level',
      options: const ['a', 'b'],
      answer: 0,
      level: level,
    );

void main() {
  group('skor & kelulusan', () {
    test('scorePercent', () {
      expect(scorePercent(4, 5), 80);
      expect(scorePercent(0, 0), 0);
      expect(scorePercent(2, 3), 67);
    });

    test('batas lulus 70%', () {
      expect(isPassed(70), isTrue);
      expect(isPassed(69), isFalse);
    });

    test('xp', () {
      expect(xpFor(100), 60);
      expect(xpFor(80), 40);
      expect(xpFor(80, alreadyPassed: true), 10);
      expect(xpFor(40), 5);
    });
  });

  group('recommendLevel', () {
    final qs = [_q(0), _q(0), _q(1), _q(1), _q(2), _q(2), _q(3), _q(3)];

    test('semua benar -> LV.04', () {
      expect(recommendLevel(qs, List.filled(8, 0)), 4);
    });

    test('salah di LV.00 -> mulai LV.00', () {
      expect(recommendLevel(qs, [1, 0, 0, 0, 0, 0, 0, 0]), 0);
    });

    test('lolos LV.00, satu salah di LV.01 -> LV.01', () {
      expect(recommendLevel(qs, [0, 0, 0, null, 0, 0, 0, 0]), 1);
    });

    test('jawaban kurang dari jumlah soal gak crash', () {
      expect(recommendLevel(qs, [0, 0]), 1);
    });
  });

  group('streak', () {
    final today = DateTime(2026, 11, 24, 9);

    test('pertama kali -> 1', () {
      expect(nextStreak(last: null, today: today, current: 0), 1);
    });

    test('hari yang sama gak nambah', () {
      expect(nextStreak(last: DateTime(2026, 11, 24, 7), today: today, current: 3), 3);
    });

    test('kemarin -> nambah 1', () {
      expect(nextStreak(last: DateTime(2026, 11, 23, 23), today: today, current: 3), 4);
    });

    test('bolong sehari -> reset', () {
      expect(nextStreak(last: DateTime(2026, 11, 21), today: today, current: 9), 1);
    });

    test('isStreakAlive', () {
      expect(isStreakAlive(last: DateTime(2026, 11, 23), today: today), isTrue);
      expect(isStreakAlive(last: DateTime(2026, 11, 22), today: today), isFalse);
      expect(isStreakAlive(last: null, today: today), isFalse);
    });
  });
}
