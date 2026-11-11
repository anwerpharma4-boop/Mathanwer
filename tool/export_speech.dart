// Exports every text the app needs to speak, as JSON, for
// tool/generate_audio.py.  Run:  dart run tool/export_speech.dart > build/speech.json
// ignore_for_file: avoid_print
import 'dart:convert';

import 'package:english_for_iraq/content/app_phrases.dart';
import 'package:english_for_iraq/content/book_data.dart';

void main() {
  final texts = <String>{};
  for (final w in vocabulary) {
    texts.add(w.spoken);
    texts.add(w.text);
  }
  for (final l in allLessons) {
    texts.addAll(l.language);
    for (final s in l.scripts) {
      for (final line in s.lines) {
        texts.add(line.text);
      }
    }
  }
  texts.addAll(allAppPhrases);
  texts.removeWhere((t) => t.trim().isEmpty);

  final letters = [
    for (final l in alphabet)
      {'letter': l.lower, 'name': l.nameIpa, 'sound': l.soundIpa},
  ];
  print(const JsonEncoder.withIndent(' ').convert({
    'texts': texts.toList()..sort(),
    'letters': letters,
  }));
}
