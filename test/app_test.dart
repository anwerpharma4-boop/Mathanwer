import 'dart:math' as math;

import 'package:english_for_iraq/content/book_data.dart';
import 'package:english_for_iraq/data/progress_store.dart';
import 'package:english_for_iraq/features/alphabet/letter_screen.dart';
import 'package:english_for_iraq/features/alphabet/tracing.dart';
import 'package:english_for_iraq/features/drawing/drawing_screen.dart';
import 'package:english_for_iraq/features/drawing/outlines.dart';
import 'package:english_for_iraq/features/games/choice_game.dart';
import 'package:english_for_iraq/features/games/choice_round.dart';
import 'package:english_for_iraq/features/games/extra_games.dart';
import 'package:english_for_iraq/features/games/games_screen.dart';
import 'package:english_for_iraq/features/lessons/lesson_screen.dart';
import 'package:english_for_iraq/features/listening/listen_repeat_screen.dart';
import 'package:english_for_iraq/features/listening/script_player.dart';
import 'package:english_for_iraq/features/parent/parent_dashboard.dart';
import 'package:english_for_iraq/services/audio_service.dart';
import 'package:english_for_iraq/widgets/celebration.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';

/// Closes any celebration dialog ("Done").
Future<void> _done(WidgetTester tester) async {
  await wait(tester, 1000);
  final done = find.text('Done');
  if (done.evaluate().isNotEmpty) {
    await tester.tap(done.last);
    await tester.pumpAndSettle();
  }
}

void main() {
  const homeTiles = [
    'startLearning', 'textbook', 'lessons', 'alphabet', 'vocabulary', 'listening', //
    'games', 'quizzes', 'progress', 'settings', 'drawing',
  ];

  for (final size in const [Size(400, 820), Size(820, 400), Size(1280, 800)]) {
    testWidgets('home shows all sections and each opens (${size.width.toInt()}x${size.height.toInt()})', (tester) async {
      await pumpApp(tester, size: size);
      await tester.pumpAndSettle();
      for (final t in homeTiles) {
        final f = find.byKey(ValueKey('home_$t'));
        await tester.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);
        expect(f, findsOneWidget, reason: t);
        await tester.tap(f);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'opening $t');
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
      }
    });
  }

  testWidgets('Arabic interface is right-to-left; English content stays left-to-right', (tester) async {
    final s = await tester.runAsync(() => makeServices(prefs: {'language': 'ar'}));
    await pumpApp(tester, services: s);
    await tester.pumpAndSettle();
    expect(find.text('الكتاب الأصلي'), findsOneWidget);
    final dir = Directionality.of(tester.element(find.byKey(const ValueKey('home_textbook'))));
    expect(dir, TextDirection.rtl);
    await tester.tap(find.byKey(const ValueKey('home_vocabulary')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('topic_0')));
    await tester.pumpAndSettle();
    final word = find.text('apple').first;
    expect(Directionality.of(tester.element(word)), TextDirection.ltr);
  });

  testWidgets('choice game: wrong answers are gentle, first-try answers score', (tester) async {
    final rounds = RoundFactory(math.Random(1)).wordToPicture(vocabulary, rounds: 3);
    final s = await pumpApp(tester,
        home: ChoiceGameScreen(
            title: 'T', instruction: 'Match the word to the picture.', makeRounds: () => rounds, kind: 'game_test', ref: 'x'));
    await tester.pumpAndSettle();
    final state = tester.state<ChoiceGameScreenState>(find.byType(ChoiceGameScreen));
    // Round 1: wrong first, then right -> no score, but the game continues.
    final r0 = state.rounds[0];
    final wrong = (r0.answer + 1) % r0.options.length;
    await tester.tap(find.byKey(ValueKey('option_$wrong')));
    await wait(tester);
    expect(state.index, 0, reason: 'a wrong answer never ends the round');
    await tester.tap(find.byKey(ValueKey('option_${r0.answer}')));
    await wait(tester);
    expect(state.index, 1);
    // Rounds 2-3 correct first time.
    for (var i = 1; i < 3; i++) {
      await tester.tap(find.byKey(ValueKey('option_${state.rounds[i].answer}')));
      await wait(tester);
    }
    await settle(tester);
    expect(find.textContaining('2 / 3'), findsOneWidget);
    expect(s.progress.results.last.score, 2);
    expect(s.progress.results.last.stars, greaterThanOrEqualTo(1));
    final audio = s.audio as SilentAudio;
    expect(audio.spoken, contains('Match the word to the picture.'));
    await _done(tester);
  });

  testWidgets('match big and small letters', (tester) async {
    await pumpApp(tester, home: MatchCaseGame(letters: const ['a', 'b', 'c'], rounds: 1, random: math.Random(3)));
    await tester.pumpAndSettle();
    final st = tester.state<MatchCaseGameState>(find.byType(MatchCaseGame));
    for (final l in st.left) {
      await tester.tap(find.byKey(ValueKey('upper_$l')));
      await tester.pump();
      await tester.tap(find.byKey(ValueKey('lower_$l')));
      await tester.pump(const Duration(milliseconds: 600));
    }
    await wait(tester);
    expect(find.text('Done'), findsOneWidget, reason: 'celebration after all pairs matched');
    await _done(tester);
  });

  testWidgets('arrange letters into a word', (tester) async {
    final cat = vocabularyById['cat']!;
    await pumpApp(tester, home: ArrangeLettersGame(words: [cat], rounds: 1, random: math.Random(2)));
    await tester.pumpAndSettle();
    final st = tester.state<ArrangeLettersGameState>(find.byType(ArrangeLettersGame));
    expect(st.word.text, 'cat');
    // Tap tiles in the right order.
    final tiles = <int>[];
    final widgets = tester.widgetList<Text>(find.descendant(of: find.byType(InkWell), matching: find.byType(Text))).toList();
    final letters = widgets.map((t) => t.data).whereType<String>().where((d) => d.length == 1).toList();
    for (final ch in 'cat'.split('')) {
      final i = letters.indexWhere((l) => l == ch);
      tiles.add(i);
      letters[i] = '#';
    }
    for (final i in tiles) {
      await tester.tap(find.byKey(ValueKey('tile_$i')));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await wait(tester);
    expect(find.text('Done'), findsOneWidget);
    await _done(tester);
  });

  testWidgets('memory cards: matching pairs stay open', (tester) async {
    final words = ['apple', 'ball'].map((w) => vocabularyById[w]!).toList();
    await pumpApp(tester, home: MemoryGame(words: words, pairs: 2, random: math.Random(4)));
    await tester.pumpAndSettle();
    final st = tester.state<MemoryGameState>(find.byType(MemoryGame));
    final cards = st.cardWords;
    final pairs = <String, List<int>>{};
    for (var i = 0; i < cards.length; i++) {
      pairs.putIfAbsent(cards[i].split(':').first, () => []).add(i);
    }
    for (final p in pairs.values) {
      await tester.tap(find.byKey(ValueKey('card_${p[0]}')));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.byKey(ValueKey('card_${p[1]}')));
      await wait(tester);
    }
    expect(st.moves, 2);
    expect(find.text('Done'), findsOneWidget);
    await _done(tester);
  });

  testWidgets('drag and drop pictures to their first letter', (tester) async {
    await pumpApp(tester, home: DragDropGame(rounds: 1, random: math.Random(5)), size: const Size(800, 900));
    await tester.pumpAndSettle();
    final st = tester.state<DragDropGameState>(find.byType(DragDropGame));
    for (final w in List.of(st.items)) {
      final letter = w.text[0];
      await tester.drag(find.byKey(ValueKey('drag_${w.id}')),
          tester.getCenter(find.byKey(ValueKey('target_$letter'))) - tester.getCenter(find.byKey(ValueKey('drag_${w.id}'))));
      await wait(tester);
    }
    expect(find.text('Done'), findsOneWidget);
    await _done(tester);
  });

  testWidgets('all 12 games open', (tester) async {
    expect(games.length, 12);
    await pumpApp(tester, home: const GamesScreen(), size: const Size(900, 1400));
    await tester.pumpAndSettle();
    for (final g in games) {
      final f = find.byKey(ValueKey('game_${g.id}'));
      await tester.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(f);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: g.id);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('lesson screen shows the original page and all tabs; completing saves progress', (tester) async {
    final lesson = lessonById('u1l4');
    final s = await pumpApp(tester, home: LessonScreen(lesson: lesson));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('lessonPageViewer')), findsOneWidget);
    for (final tab in ['Learn', 'Listen', 'Words', 'Practise', 'Book page']) {
      await tester.tap(find.text(tab).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: tab);
    }
    await tester.tap(find.byKey(const ValueKey('completeLesson')));
    await wait(tester);
    expect(s.progress.lesson('u1l4').status, LessonStatus.completed);
    await _done(tester);
  });

  testWidgets('every lesson opens', (tester) async {
    await pumpApp(tester, home: const SizedBox());
    for (final l in allLessons) {
      await tester.pumpWidget(const SizedBox());
      final s = await tester.runAsync(() => makeServices());
      await pumpApp(tester, services: s, home: LessonScreen(lesson: l));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: l.id);
    }
  });

  testWidgets('script player plays lines and play-all', (tester) async {
    final script = lessonById('u1l6').scripts[1];
    final s = await pumpApp(tester, home: ScriptPlayerScreen(script: script, bookPage: 13));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('line_0')));
    await tester.pumpAndSettle();
    expect((s.audio as SilentAudio).spoken.last, "Who's this?");
    await tester.tap(find.byKey(const ValueKey('playAll')));
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    expect((s.audio as SilentAudio).spoken, contains('Hello, Iman.'));
    await _done(tester);
  });

  testWidgets('listen and repeat works without a microphone', (tester) async {
    final s = await pumpApp(tester,
        home: ListenRepeatScreen(title: 'x', items: const [RepeatItem('Hello.'), RepeatItem('Goodbye.')]));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('listenModel')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('repeatNext')));
    await tester.pumpAndSettle();
    expect(find.text('Goodbye.'), findsOneWidget);
    expect((s.audio as SilentAudio).spoken, containsAll(['Hello.', 'Goodbye.']));
  });

  testWidgets('letter screen: name, sound, recognition grid', (tester) async {
    final s = await pumpApp(tester, home: LetterScreen(letter: letterInfo('a')), size: const Size(500, 2600));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('letterSoundBtn')));
    await tester.pumpAndSettle();
    expect((s.audio as SilentAudio).spoken, containsAll(['name:a', 'sound:a']));
    final grid = tester.state<FindLetterGridState>(find.byType(FindLetterGrid));
    for (var i = 0; i < grid.cells.length; i++) {
      if (grid.cells[i] == 'a') {
        await tester.tap(find.byKey(ValueKey('find_$i')));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
    await wait(tester);
    expect(find.byType(Confetti), findsOneWidget, reason: 'celebration shown');
    await _done(tester);
  });

  testWidgets('tracing pad records strokes and checks them', (tester) async {
    await pumpApp(tester, home: const Scaffold(body: SizedBox(width: 380, height: 480, child: TracingPad(letter: 'l'))));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();
    final surface = find.byKey(const ValueKey('tracingSurface'));
    await tester.drag(surface, const Offset(0, 120));
    await tester.pumpAndSettle();
    final st = tester.state<TracingPadState>(find.byType(TracingPad));
    expect(st.strokes, isNotEmpty);
    await tester.tap(find.byKey(const ValueKey('traceClear')));
    await tester.pump();
    expect(st.strokes, isEmpty);
  });

  testWidgets('drawing canvas: draw, undo, clear, eraser', (tester) async {
    await pumpApp(tester, home: DrawingCanvasScreen(outline: colouringPages.first));
    await tester.pumpAndSettle();
    final st = tester.state<DrawingCanvasScreenState>(find.byType(DrawingCanvasScreen));
    final surface = find.byKey(const ValueKey('drawingSurface'));
    await tester.drag(surface, const Offset(60, 40));
    await tester.drag(surface, const Offset(-30, 50));
    await tester.pump();
    expect(st.strokes.length, 2);
    await tester.ensureVisible(find.byKey(const ValueKey('eraser')));
    await tester.tap(find.byKey(const ValueKey('eraser')));
    await tester.drag(surface, const Offset(20, 20));
    await tester.pump();
    expect(st.strokes.last.eraser, isTrue);
    await tester.tap(find.byKey(const ValueKey('drawUndo')));
    await tester.pump();
    expect(st.strokes.length, 2);
    await tester.tap(find.byKey(const ValueKey('drawClear')));
    await tester.pump();
    expect(st.strokes, isEmpty);
  });

  testWidgets('parent dashboard is behind a grown-up question', (tester) async {
    late BuildContext ctx;
    await pumpApp(tester, home: Builder(builder: (c) {
      ctx = c;
      return const Scaffold();
    }));
    final future = showParentGate(ctx, random: math.Random(1));
    await tester.pumpAndSettle();
    final q = tester.widget<Text>(find.byKey(const ValueKey('gateQuestion'))).data!;
    final nums = RegExp(r'\d+').allMatches(q).map((m) => int.parse(m.group(0)!)).toList();
    await tester.enterText(find.byKey(const ValueKey('gateAnswer')), '${nums[0] * nums[1] + 1}');
    await tester.tap(find.byKey(const ValueKey('gateOpen')));
    await tester.pumpAndSettle();
    expect(find.text('That is not right. Please try again.'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('gateAnswer')), '${nums[0] * nums[1]}');
    await tester.tap(find.byKey(const ValueKey('gateOpen')));
    await tester.pumpAndSettle();
    expect(await future, isTrue);
  });

  testWidgets('parent dashboard shows progress data', (tester) async {
    final store = ProgressStore.memory();
    await store.completeLesson('u1l1');
    await store.recordResult(kind: 'quiz', ref: 'unit_1', unitId: 1, score: 4, total: 10);
    await store.recordWord('cat', false);
    final s = await tester.runAsync(() => makeServices(store: store));
    await pumpApp(tester, services: s, home: const ParentDashboard(), size: const Size(500, 2400));
    await tester.pumpAndSettle();
    expect(find.text('1 / ${allLessons.length}'), findsOneWidget);
    expect(find.textContaining('4/10'), findsOneWidget);
    expect(find.text('cat'), findsOneWidget);
  });

  testWidgets('progress persists through the Start Learning flow', (tester) async {
    final s = await pumpApp(tester);
    await tester.pumpAndSettle();
    await s.progress.completeLesson(allLessons.first.id);
    await tester.tap(find.byKey(const ValueKey('home_startLearning')));
    await tester.pumpAndSettle();
    expect(find.text('Letter b'), findsWidgets, reason: 'continues with the next lesson');
  });
}
