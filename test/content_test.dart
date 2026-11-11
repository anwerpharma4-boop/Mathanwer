import 'dart:convert';
import 'dart:io';

import 'package:english_for_iraq/content/app_phrases.dart';
import 'package:english_for_iraq/content/book_data.dart';
import 'package:english_for_iraq/core/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final manifest = (jsonDecode(File('assets/audio/speech_manifest.json').readAsStringSync()) as Map)['clips'] as Map;

  test('audio manifest declares British English', () {
    final m = jsonDecode(File('assets/audio/speech_manifest.json').readAsStringSync()) as Map;
    expect(m['locale'], 'en-GB');
    expect(m['voice'], contains('en_GB'));
  });

  test('all 26 letters have British letter-name and phonics audio', () {
    expect(alphabet.length, 26);
    for (final l in alphabet) {
      expect(File('assets/audio/letters/name_${l.lower}.ogg').existsSync(), isTrue, reason: l.lower);
      expect(File('assets/audio/letters/sound_${l.lower}.ogg').existsSync(), isTrue, reason: l.lower);
      expect(File(l.cardImage).existsSync(), isTrue, reason: l.cardImage);
    }
    // British letter name for z.
    expect(letterInfo('z').nameIpa, 'zɛd');
  });

  test('every word, sentence, dialogue line and app phrase has bundled audio', () {
    final missing = <String>[];
    void check(String t) {
      if (t.trim().isEmpty) return;
      final f = manifest[t];
      if (f == null || !File('assets/audio/speech/$f').existsSync()) missing.add(t);
    }

    for (final w in vocabulary) {
      check(w.spoken);
      check(w.text);
    }
    for (final l in allLessons) {
      l.language.forEach(check);
      for (final s in l.scripts) {
        for (final line in s.lines) {
          check(line.text);
        }
      }
    }
    allAppPhrases.forEach(check);
    expect(missing, isEmpty);
  });

  test('sound effects exist', () {
    for (final s in ['correct', 'wrong', 'complete', 'tap', 'star', 'flip']) {
      expect(File('assets/audio/sfx/$s.ogg').existsSync(), isTrue, reason: s);
    }
  });

  test('every referenced textbook picture exists', () {
    for (final w in vocabulary) {
      if (w.image != null) expect(File(w.image!).existsSync(), isTrue, reason: '${w.id} -> ${w.image}');
    }
  });

  test('vocabulary comes from the textbook only (no supplementary words)', () {
    expect(vocabulary.where((w) => w.supplementary), isEmpty);
    // Alphabet words exactly as in the Picture dictionary (pages 94-96).
    final alpha = vocabulary.where((w) => w.topic == topicAlphabet).map((w) => w.text).toList();
    expect(alpha, containsAll(['apple', 'ant', 'x-ray', 'yo-yo', 'zebra', 'question', 'queen']));
    // Picture dictionary pages 94-96: 16 + 16 + 17 entries.
    expect(alpha.length, 49);
    // British spellings as printed in the book.
    final all = vocabulary.map((w) => w.text).toSet();
    expect(all, containsAll(['rubber', 'mum', 'grey', 'jumper']));
    expect(all, isNot(contains('eraser')));
    expect(all, isNot(contains('mom')));
    expect(all, isNot(contains('gray')));
  });

  test('every lesson word id resolves to a vocabulary item', () {
    for (final l in allLessons) {
      for (final id in l.words) {
        expect(vocabularyById.containsKey(id), isTrue, reason: '${l.id}: $id');
      }
    }
    final ids = allLessons.map((l) => l.id).toList();
    expect(ids.toSet().length, ids.length, reason: 'lesson ids must be unique');
  });

  test('all 26 letters are taught in a lesson, on the right page', () {
    final taught = {for (final l in allLessons) ...l.letters};
    expect(taught.length, 26);
    for (final l in allLessons) {
      for (final letter in l.letters) {
        expect(letterInfo(letter).lessonPage, l.page);
      }
    }
  });

  test('transcript tracks referenced in lessons are within the book range 2-88', () {
    for (final s in allScripts) {
      if (s.track != null) expect(s.track, inInclusiveRange(2, 88), reason: s.title);
    }
  });

  test('Arabic interface strings cover every English key', () {
    final missing = L10n.keys.where((k) => !L10n.hasArabic(k)).toList();
    expect(missing, isEmpty);
  });
}
