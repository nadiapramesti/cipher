import '../../core/models.dart';

/// Nilai minimal biar modul dianggap lulus.
const int passThreshold = 70;

int scorePercent(int correct, int total) {
  if (total <= 0) return 0;
  return (correct * 100 / total).round();
}

bool isPassed(int percent) => percent >= passThreshold;

/// XP: lulus pertama kali 40 (sempurna 60), ngulang yang udah lulus 10,
/// belum lulus tetap dapet 5 biar usahanya kehitung.
int xpFor(int percent, {bool alreadyPassed = false}) {
  if (!isPassed(percent)) return 5;
  if (alreadyPassed) return 10;
  return percent == 100 ? 60 : 40;
}

/// Rekomendasi level dari tes penempatan.
/// User "lolos" sebuah level kalau semua soal level itu dijawab benar,
/// dan level dicek berurutan dari LV.00. Jawaban `null` = dilewati.
int recommendLevel(
  List<QuizQuestion> questions,
  List<int?> answers, {
  int maxLevel = 4,
}) {
  var level = 0;
  while (level < maxLevel) {
    final idx = [
      for (var i = 0; i < questions.length; i++)
        if (questions[i].level == level) i,
    ];
    if (idx.isEmpty) break;
    final allCorrect = idx.every(
      (i) => i < answers.length && answers[i] == questions[i].answer,
    );
    if (!allCorrect) break;
    level++;
  }
  return level;
}

DateTime _day(DateTime d) => DateTime.utc(d.year, d.month, d.day);

/// Streak masih hidup kalau terakhir aktif hari ini atau kemarin.
bool isStreakAlive({required DateTime? last, required DateTime today}) {
  if (last == null) return false;
  return _day(today).difference(_day(last)).inDays <= 1;
}

int nextStreak({
  required DateTime? last,
  required DateTime today,
  required int current,
}) {
  if (last == null) return 1;
  final diff = _day(today).difference(_day(last)).inDays;
  if (diff <= 0) return current < 1 ? 1 : current;
  if (diff == 1) return current + 1;
  return 1;
}
