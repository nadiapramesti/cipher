import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'models.dart';

/// Semua materi dibaca dari assets/content/*.json.
/// Nambah modul baru cukup edit JSON, gak perlu ubah kode.
class Content {
  Content({
    required this.levels,
    required this.modules,
    required this.placement,
    required this.glossary,
  });

  final List<Level> levels;
  final Map<String, LearnModule> modules;
  final List<QuizQuestion> placement;
  final List<GlossaryTerm> glossary;

  Level? levelAt(int index) {
    for (final l in levels) {
      if (l.index == index) return l;
    }
    return null;
  }

  List<LearnModule> modulesOf(Level level) => level.moduleIds
      .map((id) => modules[id])
      .whereType<LearnModule>()
      .toList();

  static Future<dynamic> _json(String path) async =>
      jsonDecode(await rootBundle.loadString(path));

  /// [lang] = 'id' atau 'en'. Materi tiap bahasa ada di assets/content/<lang>/.
  static Future<Content> load([String lang = 'id']) async {
    final dir = 'assets/content/$lang';
    final levelsRaw = await _json('$dir/levels.json') as List;
    final levels = <Level>[];
    final modules = <String, LearnModule>{};

    for (final raw in levelsRaw) {
      final map = raw as Map<String, dynamic>;
      final file = map['moduleFile'] as String?;
      final ids = <String>[];
      if (file != null) {
        final list = await _json('$dir/$file') as List;
        for (final m in list) {
          final module = LearnModule.fromJson(m as Map<String, dynamic>);
          modules[module.id] = module;
          ids.add(module.id);
        }
      }
      levels.add(Level.fromJson(map, ids));
    }
    levels.sort((a, b) => a.index.compareTo(b.index));

    final placement = (await _json('$dir/placement.json') as List)
        .map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
        .toList();

    final glossary = (await _json('$dir/glossary.json') as List)
        .map((e) => GlossaryTerm.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.term.toLowerCase().compareTo(b.term.toLowerCase()));

    return Content(
      levels: levels,
      modules: modules,
      placement: placement,
      glossary: glossary,
    );
  }
}
