// Renders the main screens to PNG files for visual review.
// Run:  SCREENSHOTS=1 BOOK_PAGES=/path/to/rendered/pages flutter test test/screenshots_test.dart
// (BOOK_PAGES: optional folder with p-01.png ... p-96.png, e.g. from
//  `pdftoppm -r 60 -png assets/book/*.pdf <dir>/p`).
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:english_for_iraq/app.dart';
import 'package:english_for_iraq/app_scope.dart';
import 'package:english_for_iraq/content/book_data.dart';
import 'package:english_for_iraq/core/theme.dart';
import 'package:english_for_iraq/features/alphabet/alphabet_screen.dart';
import 'package:english_for_iraq/features/alphabet/letter_screen.dart';
import 'package:english_for_iraq/features/drawing/drawing_screen.dart';
import 'package:english_for_iraq/features/games/choice_game.dart';
import 'package:english_for_iraq/features/games/choice_round.dart';
import 'package:english_for_iraq/features/games/extra_games.dart';
import 'package:english_for_iraq/features/games/games_screen.dart';
import 'package:english_for_iraq/features/lessons/lesson_screen.dart';
import 'package:english_for_iraq/features/lessons/units_screen.dart';
import 'package:english_for_iraq/features/listening/listening_screen.dart';
import 'package:english_for_iraq/features/listening/script_player.dart';
import 'package:english_for_iraq/features/parent/parent_dashboard.dart';
import 'package:english_for_iraq/features/progress/progress_screen.dart';
import 'package:english_for_iraq/features/quizzes/quizzes_screen.dart';
import 'package:english_for_iraq/features/reader/reader_screen.dart';
import 'package:english_for_iraq/features/settings/settings_screen.dart';
import 'package:english_for_iraq/features/vocabulary/vocabulary_screen.dart';
import 'package:english_for_iraq/services/book_source.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';

class _FileBook extends BookSource {
  _FileBook(this.dir);
  final String? dir;
  @override
  int get pageCount => 96;
  @override
  Future<void> open() async {}
  @override
  Future<Uint8List?> render(int page, int widthPx, {bool Function()? isWanted}) async {
    final f = File('$dir/p-${page.toString().padLeft(2, '0')}.png');
    return dir != null && f.existsSync() ? f.readAsBytesSync() : tinyPng;
  }

  @override
  Future<void> close() async {}
}

final _enabled = Platform.environment['SCREENSHOTS'] == '1';

void main() {
  final out = Directory('build/screenshots')..createSync(recursive: true);

  Future<void> shot(
    WidgetTester tester,
    String name,
    Widget home, {
    Size size = const Size(400, 820),
    String lang = 'en',
    Future<void> Function(WidgetTester)? act,
  }) async {
    final s = await tester.runAsync(() => makeServices(prefs: {'language': lang}));
    final services = AppServices(
      settings: s!.settings,
      progress: s.progress,
      audio: s.audio,
      voice: s.voice,
      book: _FileBook(Platform.environment['BOOK_PAGES']),
    );
    await services.progress.completeLesson('u1l1');
    await services.progress.recordResult(kind: 'quiz', ref: 'unit_1', unitId: 1, score: 8, total: 10);
    await services.progress.recordWord('cat', false);
    final key = GlobalKey();
    await pumpApp(tester, size: size, services: services, home: const SizedBox());
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: name.startsWith('home') ? EnglishForIraqApp(services: services) : _Shell(services: services, home: home),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
      await tester.pump(const Duration(milliseconds: 300));
    }
    if (act != null) await act(tester);
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
      await tester.pump(const Duration(milliseconds: 400));
    }
    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
    final bytes = await tester.runAsync(() async {
      final img = await boundary.toImage(pixelRatio: 1);
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    });
    File('${out.path}/$name.png').writeAsBytesSync(bytes!);
    await tester.pumpWidget(const SizedBox());
  }

  final cases = <String, Widget>{
    'units': const UnitsScreen(),
    'unit1': UnitScreen(unit: units.first),
    'lesson_book': LessonScreen(lesson: lessonById('u1l4')),
    'lesson_learn': LessonScreen(lesson: lessonById('u1l4'), initialTab: 1),
    'lesson_words': LessonScreen(lesson: lessonById('u2l2'), initialTab: 3),
    'lesson_practise': LessonScreen(lesson: lessonById('u1l1'), initialTab: 4),
    'reader': const ReaderScreen(initialPage: 11, continuous: false),
    'reader_continuous': const ReaderScreen(initialPage: 44, continuous: true),
    'alphabet': const AlphabetScreen(),
    'letter_a': LetterScreen(letter: letterInfo('a')),
    'vocabulary': const VocabularyScreen(),
    'topic_family': const TopicScreen(topic: topicFamily),
    'topic_colours': const TopicScreen(topic: topicColours),
    'listening': const ListeningScreen(),
    'script': ScriptPlayerScreen(script: lessonById('u1l6').scripts[1], bookPage: 13),
    'games': const GamesScreen(),
    'game_listen': ChoiceGameScreen(
      title: 'Listen and choose',
      instruction: 'Listen and choose the picture.',
      makeRounds: () => RoundFactory(math.Random(3)).listenAndChoose(vocabulary.where((w) => w.image != null).toList()),
      kind: 'x',
      ref: 'x',
    ),
    'game_count': ChoiceGameScreen(
      title: 'Count',
      instruction: 'How many can you see?',
      makeRounds: () => RoundFactory(math.Random(3)).counting(),
      kind: 'x',
      ref: 'x',
    ),
    'game_missing': ChoiceGameScreen(
      title: 'Missing letter',
      instruction: 'Find the missing letter.',
      makeRounds: () => RoundFactory(math.Random(5)).missingLetter(),
      kind: 'x',
      ref: 'x',
    ),
    'game_memory': MemoryGame(random: math.Random(1)),
    'game_drag': DragDropGame(random: math.Random(1)),
    'game_arrange': ArrangeLettersGame(random: math.Random(1)),
    'quizzes': const QuizzesScreen(),
    'progress': const ProgressScreen(),
    'settings': const SettingsScreen(),
    'parents': const ParentDashboard(),
    'drawing': const DrawingHomeScreen(),
  };

  testWidgets('home phone', (t) => shot(t, 'home_phone', const SizedBox()), skip: !_enabled);
  testWidgets('home phone arabic', (t) => shot(t, 'home_phone_ar', const SizedBox(), lang: 'ar'), skip: !_enabled);
  testWidgets(
    'home tablet',
    (t) => shot(t, 'home_tablet', const SizedBox(), size: const Size(1280, 800)),
    skip: !_enabled,
  );
  testWidgets(
    'home phone landscape',
    (t) => shot(t, 'home_landscape', const SizedBox(), size: const Size(820, 400)),
    skip: !_enabled,
  );
  for (final e in cases.entries) {
    testWidgets(e.key, (t) => shot(t, e.key, e.value), skip: !_enabled);
  }
  testWidgets(
    'reader tablet',
    (t) =>
        shot(t, 'reader_tablet', const ReaderScreen(initialPage: 19, continuous: false), size: const Size(1280, 800)),
    skip: !_enabled,
  );
  testWidgets('reader zoomed', (t) async {
    await shot(
      t,
      'reader_zoomed',
      const ReaderScreen(initialPage: 19, continuous: false),
      act: (tester) async {
        tester.state<ReaderScreenState>(find.byType(ReaderScreen)).zoomBy(3);
        await tester.pumpAndSettle();
      },
    );
  }, skip: !_enabled);
  testWidgets(
    'lesson tablet',
    (t) =>
        shot(t, 'lesson_tablet', LessonScreen(lesson: lessonById('u5l1'), initialTab: 1), size: const Size(1280, 800)),
    skip: !_enabled,
  );
  testWidgets('arabic units', (t) => shot(t, 'units_ar', const UnitsScreen(), lang: 'ar'), skip: !_enabled);
}

/// Same theme and text direction as the real app, with a custom first screen.
class _Shell extends StatelessWidget {
  const _Shell({required this.services, required this.home});
  final AppServices services;
  final Widget home;

  @override
  Widget build(BuildContext context) {
    final arabic = services.settings.languageCode == 'ar';
    return AppScope(
      services: services,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(arabic: arabic),
        builder: (context, child) =>
            Directionality(textDirection: arabic ? TextDirection.rtl : TextDirection.ltr, child: child!),
        home: home,
      ),
    );
  }
}
