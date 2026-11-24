import 'package:cipher/core/content_repository.dart';
import 'package:cipher/l10n/strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('semua teks UI punya terjemahan Inggris', () {
    expect(missingEnglishKeys(), isEmpty);
  });

  test('tr mengisi placeholder dan ikut bahasa aktif', () {
    L.lang = AppLang.id;
    expect(tr('min', {'n': 5}), '5 mnt');
    L.lang = AppLang.en;
    expect(tr('min', {'n': 5}), '5 min');
    L.lang = AppLang.id;
  });

  test('materi ID dan EN sejajar (modul, jumlah soal, kunci jawaban)', () async {
    final id = await Content.load('id');
    final en = await Content.load('en');
    expect(en.levels.length, id.levels.length);
    expect(en.modules.keys, id.modules.keys);
    for (final key in id.modules.keys) {
      final a = id.modules[key]!, b = en.modules[key]!;
      expect(b.pages.length, a.pages.length, reason: key);
      expect(b.quiz.length, a.quiz.length, reason: key);
      for (var i = 0; i < a.quiz.length; i++) {
        expect(b.quiz[i].answer, a.quiz[i].answer, reason: '$key soal $i');
      }
    }
    expect(en.placement.length, id.placement.length);
    expect(en.glossary.length, id.glossary.length);
  });
}
