import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/content_repository.dart';
import '../core/models.dart';
import '../features/quiz/quiz_logic.dart';

/// Progres user disimpan lokal di HP. Gak ada akun, gak ada server.
class AppState extends ChangeNotifier {
  AppState(this._prefs, this.content) {
    _load();
  }

  final SharedPreferences _prefs;
  final Content content;

  static const _kOnboarding = 'onboarding_done';
  static const _kStartLevel = 'start_level';
  static const _kXp = 'xp';
  static const _kStreak = 'streak';
  static const _kLastActive = 'last_active';
  static const _kScores = 'best_scores';

  bool onboardingDone = false;
  int startLevel = 0;
  int xp = 0;
  int _streak = 0;
  DateTime? lastActive;
  Map<String, int> bestScores = {};

  void _load() {
    onboardingDone = _prefs.getBool(_kOnboarding) ?? false;
    startLevel = _prefs.getInt(_kStartLevel) ?? 0;
    xp = _prefs.getInt(_kXp) ?? 0;
    _streak = _prefs.getInt(_kStreak) ?? 0;
    final last = _prefs.getString(_kLastActive);
    lastActive = last == null ? null : DateTime.tryParse(last);
    final raw = _prefs.getString(_kScores);
    if (raw != null) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      bestScores = decoded.map((k, v) => MapEntry(k, v as int));
    }
  }

  int get streak =>
      isStreakAlive(last: lastActive, today: DateTime.now()) ? _streak : 0;

  bool isModuleDone(String id) => isPassed(bestScores[id] ?? 0);

  bool isLevelUnlocked(Level level) {
    if (level.index <= startLevel) return true;
    final prev = content.levelAt(level.index - 1);
    if (prev == null || prev.moduleIds.isEmpty) return false;
    return prev.moduleIds.every(isModuleDone);
  }

  bool isLevelIndexUnlocked(int index) {
    final level = content.levelAt(index);
    return level != null && isLevelUnlocked(level);
  }

  bool isModuleUnlocked(LearnModule m) {
    final level = content.levelAt(m.level);
    if (level == null || !isLevelUnlocked(level)) return false;
    final i = level.moduleIds.indexOf(m.id);
    return i <= 0 || isModuleDone(level.moduleIds[i - 1]);
  }

  int levelProgress(Level l) => l.moduleIds.where(isModuleDone).length;

  /// Modul pertama yang udah kebuka tapi belum lulus.
  LearnModule? get nextModule {
    for (final level in content.levels) {
      for (final id in level.moduleIds) {
        final m = content.modules[id];
        if (m != null && isModuleUnlocked(m) && !isModuleDone(id)) return m;
      }
    }
    return null;
  }

  Future<void> completeOnboarding(int level) async {
    onboardingDone = true;
    startLevel = level;
    await _prefs.setBool(_kOnboarding, true);
    await _prefs.setInt(_kStartLevel, level);
    notifyListeners();
  }

  /// Simpan hasil kuis, balikin XP yang didapat.
  Future<int> recordQuiz(String moduleId, int percent) async {
    final previous = bestScores[moduleId];
    final gained = xpFor(
      percent,
      alreadyPassed: previous != null && isPassed(previous),
    );
    if (previous == null || percent > previous) {
      bestScores[moduleId] = percent;
    }
    xp += gained;

    final now = DateTime.now();
    _streak = nextStreak(last: lastActive, today: now, current: _streak);
    lastActive = now;

    await _prefs.setString(_kScores, jsonEncode(bestScores));
    await _prefs.setInt(_kXp, xp);
    await _prefs.setInt(_kStreak, _streak);
    await _prefs.setString(_kLastActive, now.toIso8601String());
    notifyListeners();
    return gained;
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Buat dipakai di callback (onPressed dll), gak bikin rebuild.
  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
