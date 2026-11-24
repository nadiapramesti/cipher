class LessonPage {
  const LessonPage({required this.title, required this.body, this.tip});

  final String title;
  final String body;
  final String? tip;

  factory LessonPage.fromJson(Map<String, dynamic> j) => LessonPage(
        title: j['title'] as String,
        body: j['body'] as String,
        tip: j['tip'] as String?,
      );
}

class QuizQuestion {
  const QuizQuestion({
    required this.prompt,
    required this.options,
    required this.answer,
    this.explanation = '',
    this.level = 0,
  });

  final String prompt;
  final List<String> options;
  final int answer;
  final String explanation;

  /// Dipakai di tes penempatan: soal ini menguji level berapa.
  final int level;

  factory QuizQuestion.fromJson(Map<String, dynamic> j) => QuizQuestion(
        prompt: j['prompt'] as String,
        options: (j['options'] as List).cast<String>(),
        answer: j['answer'] as int,
        explanation: (j['explanation'] as String?) ?? '',
        level: (j['level'] as int?) ?? 0,
      );
}

class LearnModule {
  const LearnModule({
    required this.id,
    required this.level,
    required this.title,
    required this.summary,
    required this.minutes,
    required this.pages,
    required this.quiz,
  });

  final String id;
  final int level;
  final String title;
  final String summary;
  final int minutes;
  final List<LessonPage> pages;
  final List<QuizQuestion> quiz;

  factory LearnModule.fromJson(Map<String, dynamic> j) => LearnModule(
        id: j['id'] as String,
        level: j['level'] as int,
        title: j['title'] as String,
        summary: j['summary'] as String,
        minutes: (j['minutes'] as int?) ?? 5,
        pages: (j['pages'] as List)
            .map((e) => LessonPage.fromJson(e as Map<String, dynamic>))
            .toList(),
        quiz: (j['quiz'] as List)
            .map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class Level {
  const Level({
    required this.index,
    required this.title,
    required this.tagline,
    required this.moduleIds,
    required this.available,
  });

  final int index;
  final String title;
  final String tagline;
  final List<String> moduleIds;
  final bool available;

  /// Contoh: LV.00
  String get code => 'LV.${index.toString().padLeft(2, '0')}';

  factory Level.fromJson(Map<String, dynamic> j, List<String> moduleIds) =>
      Level(
        index: j['index'] as int,
        title: j['title'] as String,
        tagline: j['tagline'] as String,
        moduleIds: moduleIds,
        available: moduleIds.isNotEmpty,
      );
}

class GlossaryTerm {
  const GlossaryTerm({
    required this.term,
    required this.short,
    required this.analogy,
  });

  final String term;
  final String short;
  final String analogy;

  factory GlossaryTerm.fromJson(Map<String, dynamic> j) => GlossaryTerm(
        term: j['term'] as String,
        short: j['short'] as String,
        analogy: j['analogy'] as String,
      );
}

class ScamItem {
  const ScamItem({
    required this.channel,
    required this.sender,
    required this.text,
    required this.scam,
    required this.why,
  });

  final String channel;
  final String sender;
  final String text;
  final bool scam;
  final String why;

  factory ScamItem.fromJson(Map<String, dynamic> j) => ScamItem(
        channel: j['channel'] as String,
        sender: j['sender'] as String,
        text: j['text'] as String,
        scam: j['scam'] as bool,
        why: j['why'] as String,
      );
}
