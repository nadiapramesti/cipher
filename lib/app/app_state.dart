import 'dart:convert';

import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/backup.dart';
import '../core/content_repository.dart';
import '../core/models.dart';
import '../features/quiz/quiz_logic.dart';
import '../l10n/strings.dart';
import 'theme.dart';

/// Progres user disimpan lokal di HP. Gak ada akun, gak ada server.
/// true hanya untuk build yang dijual di Play Store.
const bool kStoreBuild = bool.fromEnvironment('STORE_BUILD');

class AppState extends ChangeNotifier {
  AppState(this._prefs, this.content) {
    _load();
  }

  final SharedPreferences _prefs;
  Content content;

  static const _kLang = 'lang';
  static const _kAccent = 'theme_accent';
  static const _kMode = 'theme_mode';

  /// Bahasa awal: pilihan tersimpan, kalau belum ada ikut bahasa HP.
  static AppLang initialLang(SharedPreferences prefs) {
    final saved = prefs.getString(_kLang);
    if (saved == 'en') return AppLang.en;
    if (saved == 'id') return AppLang.id;
    final device = PlatformDispatcher.instance.locale.languageCode;
    return device == 'id' || device == 'in' ? AppLang.id : AppLang.en;
  }

  ThemeAccent accent = ThemeAccent.violet;
  AppThemeMode themeMode = AppThemeMode.dark;
  AppLang get lang => L.lang;

  Future<void> setAccent(ThemeAccent a) async {
    accent = a;
    await _prefs.setString(_kAccent, a.name);
    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode m) async {
    themeMode = m;
    await _prefs.setString(_kMode, m.name);
    notifyListeners();
  }

  Future<void> setLang(AppLang l) async {
    if (l == L.lang) return;
    content = await Content.load(l.name);
    L.lang = l;
    await _prefs.setString(_kLang, l.name);
    notifyListeners();
  }

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
    accent = ThemeAccent.values.asNameMap()[_prefs.getString(_kAccent)] ?? ThemeAccent.violet;
    themeMode = AppThemeMode.values.asNameMap()[_prefs.getString(_kMode)] ?? AppThemeMode.dark;
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
    _loadExtra();
  }

  /// Kode backup progres (buat dipindah ke HP lain).
  String exportBackup() => encodeBackup(BackupData(
        onboardingDone: onboardingDone,
        startLevel: startLevel,
        xp: xp,
        streak: _streak,
        lastActive: lastActive,
        bestScores: Map.of(bestScores),
        accent: accent.name,
        themeMode: themeMode.name,
        lang: L.code,
        extra: extraJson,
      ));

  /// Pulihkan dari kode backup. Lempar [FormatException] kalau kodenya gak valid.
  Future<void> importBackup(String code) async {
    final d = decodeBackup(code);
    onboardingDone = d.onboardingDone;
    startLevel = d.startLevel;
    xp = d.xp;
    _streak = d.streak;
    lastActive = d.lastActive;
    bestScores = Map.of(d.bestScores);
    await _prefs.setBool(_kOnboarding, onboardingDone);
    await _prefs.setInt(_kStartLevel, startLevel);
    await _prefs.setInt(_kXp, xp);
    await _prefs.setInt(_kStreak, _streak);
    if (lastActive != null) {
      await _prefs.setString(_kLastActive, lastActive!.toIso8601String());
    } else {
      await _prefs.remove(_kLastActive);
    }
    await _prefs.setString(_kScores, jsonEncode(bestScores));
    if (d.extra != null) {
      _applyExtra(d.extra!);
      await _saveExtra(notify: false);
    }
    final a = ThemeAccent.values.asNameMap()[d.accent];
    if (a != null) {
      accent = a;
      await _prefs.setString(_kAccent, a.name);
    }
    final m = AppThemeMode.values.asNameMap()[d.themeMode];
    if (m != null) {
      themeMode = m;
      await _prefs.setString(_kMode, m.name);
    }
    final l = AppLang.values.asNameMap()[d.lang];
    if (l != null && l != L.lang) {
      await setLang(l); // ini sekalian notifyListeners
      return;
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Data tambahan: statistik (buat lencana), flag CTF, antrean ulasan,
  // pengingat harian, status Pro, nama di sertifikat.
  // ---------------------------------------------------------------------------
  static const _kExtra = 'extra_v1';

  Map<String, int> stats = {};
  Set<String> flags = {};

  /// kunci "modulId#indexSoal" -> "YYYY-MM-DD|kotak" (Leitner sederhana)
  Map<String, String> reviewQueue = {};
  bool reminderOn = false;
  int reminderHour = 19;
  int reminderMinute = 0;
  bool isPro = false;
  String certName = '';

  void _loadExtra() {
    final raw = _prefs.getString(_kExtra);
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      stats = (j['stats'] as Map? ?? {}).map((k, v) => MapEntry(k as String, (v as num).toInt()));
      flags = ((j['flags'] as List?) ?? []).cast<String>().toSet();
      reviewQueue = (j['review'] as Map? ?? {}).map((k, v) => MapEntry(k as String, v as String));
      reminderOn = j['remOn'] as bool? ?? false;
      reminderHour = (j['remH'] as num?)?.toInt() ?? 19;
      reminderMinute = (j['remM'] as num?)?.toInt() ?? 0;
      isPro = j['pro'] as bool? ?? false;
      certName = j['cert'] as String? ?? '';
    } catch (_) {
      // data rusak: mulai bersih, progres utama tetap aman
    }
  }

  Map<String, Object?> get extraJson => {
        'stats': stats,
        'flags': flags.toList(),
        'review': reviewQueue,
        'remOn': reminderOn,
        'remH': reminderHour,
        'remM': reminderMinute,
        'cert': certName,
      };

  Future<void> _saveExtra({bool notify = true}) async {
    await _prefs.setString(_kExtra, jsonEncode({...extraJson, 'pro': isPro}));
    if (notify) notifyListeners();
  }

  void _applyExtra(Map<String, dynamic> j) {
    stats = (j['stats'] as Map? ?? {}).map((k, v) => MapEntry(k as String, (v as num).toInt()));
    flags = ((j['flags'] as List?) ?? []).cast<String>().toSet();
    reviewQueue = (j['review'] as Map? ?? {}).map((k, v) => MapEntry(k as String, v as String));
    certName = j['cert'] as String? ?? certName;
  }

  int stat(String key) => stats[key] ?? 0;

  /// Naikin statistik ke nilai tertinggi (mis. skor terbaik Tebak Penipuan).
  Future<void> bumpMax(String key, int value) async {
    if (value <= stat(key)) return;
    stats[key] = value;
    await _saveExtra();
  }

  Future<void> addStat(String key, [int by = 1]) async {
    stats[key] = stat(key) + by;
    await _saveExtra();
  }

  Future<void> captureFlag(String id) async {
    if (!flags.add(id)) return;
    xp += 25;
    await _prefs.setInt(_kXp, xp);
    await _saveExtra();
  }

  // --- ulasan (spaced repetition ringan) ---
  static const _boxDays = [1, 3, 7];

  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> markWrong(String moduleId, int index) async {
    final due = DateTime.now().add(const Duration(days: 1));
    reviewQueue['$moduleId#$index'] = '${_day(due)}|0';
    await _saveExtra(notify: false);
  }

  /// Soal yang udah waktunya diulang (dan modulnya masih ada).
  List<String> get dueReviews {
    final today = _day(DateTime.now());
    final out = <String>[];
    reviewQueue.forEach((key, v) {
      final due = v.split('|').first;
      final id = key.split('#').first;
      if (due.compareTo(today) <= 0 && content.modules.containsKey(id)) out.add(key);
    });
    out.sort();
    return out;
  }

  QuizQuestion? reviewQuestion(String key) {
    final parts = key.split('#');
    final m = content.modules[parts.first];
    final i = int.tryParse(parts.length > 1 ? parts[1] : '');
    if (m == null || i == null || i < 0 || i >= m.quiz.length) return null;
    return m.quiz[i];
  }

  Future<void> answerReview(String key, bool correct) async {
    final v = reviewQueue[key];
    if (v == null) return;
    final box = int.tryParse(v.split('|').last) ?? 0;
    if (!correct) {
      reviewQueue[key] = '${_day(DateTime.now().add(const Duration(days: 1)))}|0';
    } else if (box + 1 >= _boxDays.length) {
      reviewQueue.remove(key);
    } else {
      final next = box + 1;
      reviewQueue[key] = '${_day(DateTime.now().add(Duration(days: _boxDays[next])))}|$next';
    }
    await _saveExtra(notify: false);
  }

  Future<void> finishReviewSession(int answered) async {
    stats['reviews'] = stat('reviews') + 1;
    xp += answered * 3;
    await _prefs.setInt(_kXp, xp);
    await _touchStreak();
    await _saveExtra();
  }

  // --- pengingat ---
  Future<void> setReminder({required bool on, int? hour, int? minute}) async {
    reminderOn = on;
    reminderHour = hour ?? reminderHour;
    reminderMinute = minute ?? reminderMinute;
    await _saveExtra();
  }

  // --- Pro & sertifikat ---
  Future<void> setPro(bool value) async {
    if (isPro == value) return;
    isPro = value;
    await _saveExtra();
  }

  Future<void> setCertName(String name) async {
    certName = name.trim();
    await _saveExtra();
  }

  /// Level ini termasuk konten Pro? (LV.02 ke atas)
  static bool isProLevel(int index) => index >= 2;

  /// Edisi pribadi (default): semua fitur Pro kebuka tanpa beli.
  /// Build Play Store: `flutter build appbundle --dart-define=STORE_BUILD=true`.
  bool get hasPro => isPro || !kStoreBuild;

  Future<void> _touchStreak() async {
    final now = DateTime.now();
    _streak = nextStreak(last: lastActive, today: now, current: _streak);
    lastActive = now;
    stats['maxStreak'] = _streak > stat('maxStreak') ? _streak : stat('maxStreak');
    await _prefs.setInt(_kStreak, _streak);
    await _prefs.setString(_kLastActive, now.toIso8601String());
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
    if (percent == 100) stats['perfect'] = stat('perfect') + 1;

    await _touchStreak();
    await _prefs.setString(_kScores, jsonEncode(bestScores));
    await _prefs.setInt(_kXp, xp);
    await _saveExtra();
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
