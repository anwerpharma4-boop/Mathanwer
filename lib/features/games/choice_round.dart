import 'dart:math' as math;

import '../../content/book_data.dart';
import '../../content/models.dart';

/// What is shown as one answer option.
class ChoiceOption {
  const ChoiceOption({this.word, this.text, this.letter, this.showPicture = true, this.showText = false});

  final VocabWord? word;
  final String? text;
  final String? letter;
  final bool showPicture;
  final bool showText;

  String get id => word?.id ?? letter ?? text ?? '';
}

/// What the child is asked.
class ChoicePrompt {
  const ChoicePrompt({
    this.text,
    this.picture,
    this.repeat = 1,
    this.speak,
    this.letterName,
    this.letterSound,
    this.hideTextUntilAnswered = false,
  });

  /// Big text (word, letter, "_pple" ...).
  final String? text;

  /// Picture of a word (repeated [repeat] times for counting).
  final VocabWord? picture;
  final int repeat;

  /// British English text to play when the round starts / on replay.
  final String? speak;
  final String? letterName;
  final String? letterSound;
  final bool hideTextUntilAnswered;
}

class ChoiceRound {
  ChoiceRound({required this.prompt, required this.options, required this.answer, this.wordId, this.sayOnCorrect})
      : assert(answer >= 0 && answer < options.length);

  final ChoicePrompt prompt;
  final List<ChoiceOption> options;
  final int answer;

  /// Vocabulary id for statistics (revision recommendations).
  final String? wordId;

  /// Text to say after a correct answer.
  final String? sayOnCorrect;
}

/// Builds rounds for games and quizzes from textbook vocabulary only.
class RoundFactory {
  RoundFactory([math.Random? random]) : rnd = random ?? math.Random();

  final math.Random rnd;

  List<T> _pick<T>(List<T> pool, int n, {T? include}) {
    final copy = List<T>.from(pool)..shuffle(rnd);
    final out = <T>[];
    if (include != null) out.add(include);
    for (final x in copy) {
      if (out.length >= n) break;
      if (!out.contains(x)) out.add(x);
    }
    return out..shuffle(rnd);
  }

  /// Distinct-looking distractors: avoid the same spelling twice.
  List<VocabWord> _options(VocabWord target, List<VocabWord> pool, int n) {
    final others = pool
        .where((w) => w.text != target.text && (target.image == null || w.image != target.image))
        .toList();
    final seen = <String>{target.text};
    final distinct = <VocabWord>[];
    others.shuffle(rnd);
    for (final w in others) {
      if (seen.add(w.text)) distinct.add(w);
      if (distinct.length >= n - 1) break;
    }
    return [target, ...distinct]..shuffle(rnd);
  }

  List<VocabWord> withPictures(Iterable<VocabWord> words) => words.where((w) => w.image != null).toList();

  /// Rounds use a target sequence without repeats when possible.
  List<VocabWord> _targets(List<VocabWord> pool, int rounds) {
    final unique = <String, VocabWord>{};
    for (final w in pool) {
      unique.putIfAbsent(w.text, () => w);
    }
    final list = unique.values.toList()..shuffle(rnd);
    final out = <VocabWord>[];
    while (out.length < rounds && list.isNotEmpty) {
      out.add(list[out.length % list.length]);
    }
    return out;
  }

  /// Show the word, choose the picture.
  List<ChoiceRound> wordToPicture(List<VocabWord> pool, {int rounds = 8, int options = 3, List<VocabWord>? targets}) {
    final pics = withPictures(pool);
    return [
      for (final t in _targets(withPictures(targets ?? pics), rounds))
        () {
          final opts = _options(t, pics, options);
          return ChoiceRound(
            prompt: ChoicePrompt(text: t.text, speak: t.spoken),
            options: [for (final o in opts) ChoiceOption(word: o)],
            answer: opts.indexOf(t),
            wordId: t.id,
          );
        }(),
    ];
  }

  /// Show the picture, choose the word (reading).
  List<ChoiceRound> pictureToWord(List<VocabWord> pool, {int rounds = 8, int options = 3}) {
    final pics = withPictures(pool);
    return [
      for (final t in _targets(pics, rounds))
        () {
          final opts = _options(t, pics, options);
          return ChoiceRound(
            prompt: ChoicePrompt(picture: t),
            options: [for (final o in opts) ChoiceOption(word: o, showPicture: false, showText: true)],
            answer: opts.indexOf(t),
            wordId: t.id,
            sayOnCorrect: t.spoken,
          );
        }(),
    ];
  }

  /// Hear the word, choose the picture.
  List<ChoiceRound> listenAndChoose(List<VocabWord> pool, {int rounds = 8, int options = 4, List<VocabWord>? targets}) {
    bool visual(VocabWord w) => w.image != null || w.colour != null || w.count != null;
    final pics = pool.where(visual).toList();
    return [
      for (final t in _targets((targets ?? pics).where(visual).toList(), rounds))
        () {
          final opts = _options(t, pics, options);
          return ChoiceRound(
            prompt: ChoicePrompt(speak: t.spoken, text: t.text, hideTextUntilAnswered: true),
            options: [for (final o in opts) ChoiceOption(word: o)],
            answer: opts.indexOf(t),
            wordId: t.id,
          );
        }(),
    ];
  }

  /// Picture + word with one letter missing; choose the letter.
  List<ChoiceRound> missingLetter({int rounds = 8}) {
    final pool = vocabulary
        .where((w) => w.topic == topicAlphabet && w.image != null && RegExp(r'^[a-z]{3,7}$').hasMatch(w.text))
        .toList();
    return [
      for (final t in _targets(pool, rounds))
        () {
          final i = rnd.nextInt(t.text.length);
          final missing = t.text[i];
          final blanked = '${t.text.substring(0, i)}_${t.text.substring(i + 1)}';
          final letters = _pick('abcdefghijklmnopqrstuvwxyz'.split('').where((l) => l != missing).toList(), 2)
            ..add(missing)
            ..shuffle(rnd);
          return ChoiceRound(
            prompt: ChoicePrompt(text: blanked, picture: t, speak: t.spoken),
            options: [for (final l in letters) ChoiceOption(letter: l)],
            answer: letters.indexOf(missing),
            wordId: t.id,
            sayOnCorrect: t.spoken,
          );
        }(),
    ];
  }

  /// Hear a colour, choose the paint splat.
  List<ChoiceRound> colours({int rounds = 8}) => listenAndChoose(wordsInTopic(topicColours), rounds: rounds, options: 4)
      .map((r) => ChoiceRound(
            prompt: ChoicePrompt(speak: r.prompt.speak, text: r.prompt.text),
            options: r.options,
            answer: r.answer,
            wordId: r.wordId,
          ))
      .toList();

  /// Count the pictures, choose the number (1-10, Unit 3).
  List<ChoiceRound> counting({int rounds = 8, int max = 10}) {
    final pics = withPictures(vocabulary.where((w) => w.topic == topicAlphabet || w.topic == topicToys || w.topic == topicAnimals));
    final numbers = wordsInTopic(topicNumbers);
    final out = <ChoiceRound>[];
    final counts = List.generate(max, (i) => i + 1)..shuffle(rnd);
    for (var r = 0; r < rounds; r++) {
      final n = counts[r % counts.length];
      final thing = pics[rnd.nextInt(pics.length)];
      final target = numbers[n - 1];
      final opts = _pick(numbers, 3, include: target);
      out.add(ChoiceRound(
        prompt: ChoicePrompt(picture: thing, repeat: n, speak: 'How many can you see?'),
        options: [for (final o in opts) ChoiceOption(word: o, showPicture: false, showText: true)],
        answer: opts.indexOf(target),
        wordId: target.id,
        sayOnCorrect: target.spoken,
      ));
    }
    return out;
  }

  /// Animals from the book (Unit 5 + alphabet animals): see, choose word.
  List<ChoiceRound> animals({int rounds = 8}) {
    const alphabetAnimals = ['ant', 'cat', 'dog', 'duck', 'elephant', 'fish', 'goat', 'horse', 'lion', 'monkey', 'rabbit', 'snake', 'zebra'];
    final pool = [
      ...wordsInTopic(topicAnimals),
      ...alphabetAnimals.map((a) => vocabularyById[wordId(a)]!),
    ];
    return pictureToWord(pool, rounds: rounds, options: 3);
  }

  /// Classroom objects (Unit 2): hear, choose the picture.
  List<ChoiceRound> classroom({int rounds = 8}) =>
      listenAndChoose(wordsInTopic(topicClassroom), rounds: rounds, options: 3);

  /// Hear the letter name, choose the letter.
  List<ChoiceRound> findLetter({int rounds = 8, List<String>? letters, bool upper = false}) {
    final all = letters ?? alphabet.map((l) => l.lower).toList();
    final targets = List<String>.from(all)..shuffle(rnd);
    return [
      for (var i = 0; i < rounds; i++)
        () {
          final t = targets[i % targets.length];
          final opts = _pick(alphabet.map((l) => l.lower).where((l) => l != t).toList(), 3)
            ..add(t)
            ..shuffle(rnd);
          return ChoiceRound(
            prompt: ChoicePrompt(letterName: t),
            options: [for (final o in opts) ChoiceOption(letter: upper ? o.toUpperCase() : o)],
            answer: opts.indexOf(t),
            sayOnCorrect: null,
          );
        }(),
    ];
  }

  /// Hear the letter sound, choose the picture that starts with it.
  List<ChoiceRound> initialSound({int rounds = 8, List<String>? letters}) {
    final all = letters ?? alphabet.map((l) => l.lower).toList();
    final targets = List<String>.from(all)..shuffle(rnd);
    final out = <ChoiceRound>[];
    for (var i = 0; i < rounds; i++) {
      final letter = targets[i % targets.length];
      final info = letterInfo(letter);
      final target = vocabularyById[info.words[rnd.nextInt(info.words.length)]]!;
      final others = withPictures(vocabulary.where((w) => w.topic == topicAlphabet && !w.text.startsWith(letter)));
      final opts = [target, ..._pick(others, 2)]..shuffle(rnd);
      out.add(ChoiceRound(
        prompt: ChoicePrompt(letterSound: letter, text: letter),
        options: [for (final o in opts) ChoiceOption(word: o)],
        answer: opts.indexOf(target),
        wordId: target.id,
        sayOnCorrect: target.spoken,
      ));
    }
    return out;
  }

  /// Show the big letter, choose the small one (and vice versa).
  List<ChoiceRound> upperLower({int rounds = 8, List<String>? letters}) {
    final all = letters ?? alphabet.map((l) => l.lower).toList();
    final targets = List<String>.from(all)..shuffle(rnd);
    return [
      for (var i = 0; i < rounds; i++)
        () {
          final t = targets[i % targets.length];
          final upperPrompt = i.isEven;
          final opts = _pick(alphabet.map((l) => l.lower).where((l) => l != t).toList(), 2)
            ..add(t)
            ..shuffle(rnd);
          return ChoiceRound(
            prompt: ChoicePrompt(text: upperPrompt ? t.toUpperCase() : t, letterName: t),
            options: [for (final o in opts) ChoiceOption(letter: upperPrompt ? o : o.toUpperCase())],
            answer: opts.indexOf(t),
          );
        }(),
    ];
  }

  /// Mixed quiz for a unit, built from that unit's lesson vocabulary.
  List<ChoiceRound> unitQuiz(Unit unit, {int rounds = 10}) {
    final ids = <String>{for (final l in unit.lessons) ...l.words};
    var pool = ids.map((id) => vocabularyById[id]).whereType<VocabWord>().toList();
    if (pool.length < 4) {
      // Revision unit 8 revises everything from the book.
      pool = vocabulary;
    }
    final kinds = [
      (int n) => listenAndChoose(pool, rounds: n, options: 3),
      (int n) => wordToPicture(pool, rounds: n),
      (int n) => pictureToWord(pool, rounds: n),
    ];
    final out = <ChoiceRound>[];
    var k = 0;
    while (out.length < rounds) {
      final batch = kinds[k % kinds.length](1);
      if (batch.isEmpty) break;
      if (!out.any((r) => r.wordId == batch.first.wordId) || out.length > pool.length) out.add(batch.first);
      k++;
      if (k > rounds * 6) break;
    }
    return out;
  }

  /// Revision of words the child found difficult.
  List<ChoiceRound> revision(List<String> weakIds, {int rounds = 8}) {
    final weak = weakIds.map((id) => vocabularyById[id]).whereType<VocabWord>().toList();
    if (weak.isEmpty) return [];
    final pics = withPictures(vocabulary);
    final out = <ChoiceRound>[];
    for (var i = 0; i < rounds; i++) {
      final t = weak[i % weak.length];
      final pool = t.image != null ? pics : wordsInTopic(t.topic);
      final opts = _options(t, pool, 3);
      out.add(ChoiceRound(
        prompt: ChoicePrompt(speak: t.spoken, text: t.text, hideTextUntilAnswered: i.isEven),
        options: [for (final o in opts) ChoiceOption(word: o)],
        answer: opts.indexOf(t),
        wordId: t.id,
      ));
    }
    return out;
  }
}
