import 'dart:io';
import 'dart:math' as math;

import 'package:english_for_iraq/content/book_data.dart';
import 'package:english_for_iraq/data/progress_store.dart';
import 'package:english_for_iraq/features/alphabet/tracing.dart';
import 'package:english_for_iraq/features/games/choice_round.dart';
import 'package:english_for_iraq/features/reader/reader_navigator_sheet.dart';
import 'package:english_for_iraq/features/reader/zoom_math.dart';
import 'package:english_for_iraq/services/book_source.dart';
import 'package:english_for_iraq/services/british_voice.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';

void main() {
  group('ZoomMath', () {
    const viewport = Size(400, 700);

    test('fitPage keeps A4 proportions inside the viewport', () {
      final r = ZoomMath.fitPage(viewport, 841.92 / 595.32);
      expect(r.width, lessThanOrEqualTo(400));
      expect(r.height, lessThanOrEqualTo(700));
      expect(r.height / r.width, closeTo(1.4142, 0.001));
    });

    test('clamp prevents panning beyond the content edges', () {
      final m = ZoomMath.clamp(ZoomMath.make(2, const Offset(500, 500)), viewport, viewport);
      expect(ZoomMath.translationOf(m), Offset.zero);
      final m2 = ZoomMath.clamp(ZoomMath.make(2, const Offset(-5000, -5000)), viewport, viewport);
      expect(ZoomMath.translationOf(m2), const Offset(-400, -700));
    });

    test('clamp enforces min and max scale', () {
      expect(ZoomMath.scaleOf(ZoomMath.clamp(ZoomMath.make(0.2, Offset.zero), viewport, viewport)), 1);
      expect(ZoomMath.scaleOf(ZoomMath.clamp(ZoomMath.make(50, Offset.zero), viewport, viewport)), ZoomMath.maxScale);
    });

    test('zoomAt keeps the focal point fixed', () {
      const focal = Offset(100, 200);
      final m = ZoomMath.zoomAt(Matrix4.identity(), focal, 3, viewport, viewport);
      final t = ZoomMath.translationOf(m);
      // Content point (100,200) must still be under the finger.
      expect(t + focal * 3, offsetMoreOrLessEquals(focal));
    });

    test('fitWidth makes the page as wide as the screen (landscape)', () {
      const land = Size(800, 400);
      final page = ZoomMath.fitPage(land, 1.4142);
      final m = ZoomMath.fitWidth(land, land, page);
      expect(page.width * ZoomMath.scaleOf(m), closeTo(800, 0.5));
      expect(ZoomMath.translationOf(m).dx + page.left * ZoomMath.scaleOf(m), closeTo(0, 0.5));
    });

    test('render tiers top out at the 300 dpi native resolution', () {
      expect(tierFor(100), 180);
      expect(tierFor(900), 1100);
      expect(tierFor(99999), maxRenderWidth);
      expect(maxRenderWidth, 2480);
    });
  });

  group('British voice selection', () {
    test('picks an installed offline en-GB voice', () {
      final v = BritishVoice.pickVoice([
        {'name': 'en-us-x-sfg-local', 'locale': 'en-US', 'network_required': '0', 'features': ''},
        {'name': 'en-gb-x-gbb-network', 'locale': 'en-GB', 'network_required': '1', 'features': ''},
        {'name': 'en-gb-x-gba-local', 'locale': 'en-GB', 'network_required': '0', 'features': ''},
      ]);
      expect(v?['name'], 'en-gb-x-gba-local');
    });

    test('never substitutes American or other English voices', () {
      expect(
        BritishVoice.pickVoice([
          {'name': 'us', 'locale': 'en-US', 'network_required': '0'},
          {'name': 'au', 'locale': 'en-AU', 'network_required': '0'},
          {'name': 'in', 'locale': 'en-IN', 'network_required': '0'},
        ]),
        isNull,
      );
    });

    test('rejects voices that are not installed or need the network', () {
      expect(
        BritishVoice.pickVoice([
          {'name': 'a', 'locale': 'en-GB', 'network_required': '1'},
          {'name': 'b', 'locale': 'en_GB', 'network_required': '0', 'features': 'notInstalled\tlegacySetLanguageVoice'},
        ]),
        isNull,
      );
    });
  });

  group('RoundFactory', () {
    final f = RoundFactory(math.Random(7));

    void checkRounds(List<ChoiceRound> rounds, {int? options}) {
      expect(rounds, isNotEmpty);
      for (final r in rounds) {
        expect(r.answer, inInclusiveRange(0, r.options.length - 1));
        if (options != null) expect(r.options.length, options);
        final ids = r.options.map((o) => o.word?.text ?? o.letter ?? o.text).toList();
        expect(ids.toSet().length, ids.length, reason: 'duplicate options: $ids');
      }
    }

    test('word to picture', () {
      final rounds = f.wordToPicture(vocabulary);
      checkRounds(rounds, options: 3);
      for (final r in rounds) {
        expect(r.options[r.answer].word!.text, r.prompt.text);
      }
    });

    test('listen and choose', () => checkRounds(f.listenAndChoose(vocabulary), options: 4));

    test('missing letter blanks exactly one letter and the answer fills it', () {
      final rounds = f.missingLetter();
      checkRounds(rounds, options: 3);
      for (final r in rounds) {
        final word = r.prompt.picture!.text;
        final filled = r.prompt.text!.replaceFirst('_', r.options[r.answer].letter!);
        expect(filled, word);
      }
    });

    test('colours offers four colour swatches', () {
      final rounds = f.colours();
      checkRounds(rounds, options: 4);
      for (final r in rounds) {
        expect(r.options.every((o) => o.word!.colour != null), isTrue);
      }
    });

    test('counting asks for 1-10 and the answer matches the number of pictures', () {
      final rounds = f.counting();
      checkRounds(rounds, options: 3);
      for (final r in rounds) {
        expect(r.options[r.answer].word!.count, r.prompt.repeat);
      }
    });

    test('animals, classroom, letters and initial sounds', () {
      checkRounds(f.animals(), options: 3);
      checkRounds(f.classroom(), options: 3);
      checkRounds(f.findLetter(), options: 4);
      checkRounds(f.upperLower(), options: 3);
      final sounds = f.initialSound();
      checkRounds(sounds, options: 3);
      for (final r in sounds) {
        expect(r.options[r.answer].word!.text.startsWith(r.prompt.letterSound!), isTrue);
      }
    });

    test('every unit has a quiz', () {
      for (final u in units) {
        checkRounds(f.unitQuiz(u));
      }
    });

    test('revision uses the weak words', () {
      final rounds = f.revision(['apple', 'cat']);
      checkRounds(rounds);
      expect(rounds.map((r) => r.wordId).toSet(), {'apple', 'cat'});
      expect(f.revision([]), isEmpty);
    });
  });

  group('TraceGrader', () {
    // A vertical bar ("l") in a 20x20 grid.
    const n = 20;
    final mask = List<bool>.generate(n * n, (i) => (i % n) >= 9 && (i % n) <= 10 && (i ~/ n) >= 3 && (i ~/ n) <= 16);
    final g = TraceGrader(mask, n);

    test('tracing along the letter passes', () {
      final s = g.grade([
        [const Offset(0.5, 0.15), const Offset(0.5, 0.85)],
      ], 0.06);
      expect(s.passed, isTrue, reason: '$s');
    });

    test('scribbling elsewhere does not pass', () {
      final s = g.grade([
        [const Offset(0.05, 0.05), const Offset(0.2, 0.9)],
      ], 0.06);
      expect(s.passed, isFalse);
    });

    test('no strokes does not pass', () => expect(g.grade([], 0.06).passed, isFalse));
  });

  test('page search finds pages by word, topic and number', () {
    expect(searchPages('zoo', 96), containsAll([44, 45]));
    expect(searchPages('45', 96).first, 45);
    expect(searchPages('zebra', 96), containsAll([41, 96]));
    expect(searchPages('picture dictionary', 96), containsAll([94, 95, 96]));
    expect(searchPages('', 96), isEmpty);
  });

  group('Stars and levels', () {
    test('stars are encouraging (always at least one)', () {
      expect(starsFor(0, 10), 1);
      expect(starsFor(6, 10), 2);
      expect(starsFor(9, 10), 3);
    });
    test('levels', () {
      expect(levelForStars(0), 1);
      expect(levelForStars(15), 2);
      expect(levelForStars(1000), 5);
    });
  });

  group('ProgressStore persistence', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('progress'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('progress is saved and restored after restarting', () async {
      final path = '${dir.path}/p.db';
      var s = await openTestStore(path: path);
      await s.markLessonStarted('u1l2');
      await s.completeLesson('u1l1');
      await s.recordResult(kind: 'quiz', ref: 'unit_1', unitId: 1, score: 9, total: 10);
      await s.recordWord('apple', true);
      await s.recordWord('cat', false);
      await s.toggleBookmark(44);
      await s.setLastReaderPage(57);
      await s.addLearningTime(120);
      final stars = s.totalStars;
      await s.close();

      s = await openTestStore(path: path);
      expect(s.lesson('u1l1').status, LessonStatus.completed);
      expect(s.lesson('u1l2').status, LessonStatus.inProgress);
      expect(s.results.single.score, 9);
      expect(s.bestStars('quiz', 'unit_1'), 3);
      expect(s.totalStars, stars);
      expect(s.wordStat('apple').correct, 1);
      expect(s.weakWords, ['cat']);
      expect(s.bookmarks, {44});
      expect(s.lastReaderPage, 57);
      expect(s.totalSeconds, 120);
      expect(s.badges.keys, containsAll(['first_lesson', 'quiz_star']));
      await s.resetAll();
      expect(s.results, isEmpty);
      expect(s.bookmarks, isEmpty);
      await s.close();
    });

    test('unit completion and badges', () async {
      final s = await openTestStore();
      for (final l in unitById(1).lessons) {
        await s.completeLesson(l.id);
      }
      expect(s.isUnitComplete(1), isTrue);
      expect(s.unitCompletion(1), 1);
      expect(s.badges.containsKey('unit_1'), isTrue);
      expect(s.takeNewBadges(), isNotEmpty);
      expect(s.takeNewBadges(), isEmpty);
      await s.close();
    });

    test('mastered words', () async {
      final s = await openTestStore();
      for (var i = 0; i < 3; i++) {
        await s.recordWord('dog', true);
      }
      expect(s.masteredWordCount, 1);
      await s.close();
    });
  });
}
