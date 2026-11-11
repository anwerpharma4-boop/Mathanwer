import 'package:material_ui/material_ui.dart';

import '../../app_scope.dart';
import '../../content/book_data.dart';
import '../../content/models.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/progress_store.dart';
import '../../widgets/celebration.dart';
import '../../widgets/common.dart';
import '../alphabet/letter_screen.dart';
import '../alphabet/tracing.dart';
import '../drawing/drawing_screen.dart';
import '../games/choice_game.dart';
import '../games/choice_round.dart';
import '../listening/listen_repeat_screen.dart';
import '../listening/script_player.dart';
import '../reader/page_image.dart';
import '../reader/reader_screen.dart';
import '../reader/zoom_math.dart';

/// One lesson of the book, linked to its original textbook page(s).
/// Tabs: original page · learn · listen · words · practise.
class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key, required this.lesson, this.initialTab = 0});
  final Lesson lesson;
  final int initialTab;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  Lesson get lesson => widget.lesson;
  Unit get unit => unitById(lesson.unitId);

  List<VocabWord> get words => lesson.words.map((id) => vocabularyById[id]).whereType<VocabWord>().toList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => AppScope.read(context).progress.markLessonStarted(lesson.id));
  }

  Future<void> _complete() async {
    final services = AppScope.read(context);
    await services.progress.completeLesson(lesson.id);
    final badges = services.progress.takeNewBadges();
    if (!mounted) return;
    await showCelebration(context, stars: 3, badges: badges, canRetry: false);
  }

  String get _heading {
    final kind = switch (lesson.kind) {
      LessonKind.project => context.tr('project'),
      LessonKind.story => context.tr('story'),
      _ => '${context.tr('lesson')} ${lesson.number}',
    };
    return '${context.tr('unit')} ${unit.id} · $kind';
  }

  @override
  Widget build(BuildContext context) {
    final colour = Color(unit.colour);
    final tabs = [
      Tab(icon: const Icon(Icons.menu_book_rounded), text: context.tr('bookPage')),
      Tab(icon: const Icon(Icons.lightbulb_rounded), text: context.tr('learn')),
      Tab(icon: const Icon(Icons.headphones_rounded), text: context.tr('listen')),
      Tab(icon: const Icon(Icons.collections_rounded), text: context.tr('words')),
      Tab(icon: const Icon(Icons.sports_esports_rounded), text: context.tr('practise')),
    ];
    return DefaultTabController(
      length: tabs.length,
      initialIndex: widget.initialTab,
      child: AppPage(
        title: _heading,
        colour: colour,
        actions: [
          ListenableBuilder(
            listenable: AppScope.of(context).progress,
            builder: (context, _) {
              final done = AppScope.of(context).progress.lesson(lesson.id).status == LessonStatus.completed;
              return IconButton(
                key: const ValueKey('completeLesson'),
                tooltip: context.tr('markComplete'),
                icon: Icon(done ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                    color: done ? AppColors.success : colour, size: 32),
                onPressed: _complete,
              );
            },
          ),
        ],
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: EnglishContent(
              child: Text(lesson.title, style: learningText(24, color: colour), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            labelColor: colour,
            indicatorColor: colour,
            tabs: tabs,
          ),
          Expanded(
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(), // keep swipes for the page zoom
              children: [
                _BookPageTab(lesson: lesson, colour: colour),
                _LearnTab(lesson: lesson, words: words, colour: colour, onComplete: _complete),
                _ListenTab(lesson: lesson, colour: colour),
                _WordsTab(words: words, colour: colour),
                _PractiseTab(lesson: lesson, words: words, colour: colour, onComplete: _complete),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ----------------------------------------------------------------- book page
class _BookPageTab extends StatefulWidget {
  const _BookPageTab({required this.lesson, required this.colour});
  final Lesson lesson;
  final Color colour;

  @override
  State<_BookPageTab> createState() => _BookPageTabState();
}

class _BookPageTabState extends State<_BookPageTab> {
  int _i = 0;
  final _tc = TransformationController();

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = widget.lesson.pages;
    final page = pages[_i];
    final aspect = AppScope.of(context).book.aspectRatio;
    return Column(children: [
      Expanded(
        child: LayoutBuilder(builder: (context, c) {
          final viewport = Size(c.maxWidth, c.maxHeight);
          final rect = ZoomMath.fitPage(viewport, aspect);
          return ListenableBuilder(
            listenable: _tc,
            builder: (context, _) => InteractiveViewer(
              key: const ValueKey('lessonPageViewer'),
              transformationController: _tc,
              minScale: ZoomMath.minScale,
              maxScale: ZoomMath.maxScale,
              boundaryMargin: EdgeInsets.zero,
              child: SizedBox.fromSize(
                size: viewport,
                child: Stack(children: [
                  Positioned.fromRect(
                    rect: rect,
                    child: PdfPageImage(
                      key: ValueKey('lessonpage_$page'),
                      page: page,
                      targetWidthPx: rect.width * ZoomMath.scaleOf(_tc.value).clamp(1.0, 3.0) * MediaQuery.devicePixelRatioOf(context),
                    ),
                  ),
                ]),
              ),
            ),
          );
        }),
      ),
      Padding(
        padding: const EdgeInsets.all(10),
        child: Wrap(spacing: 10, runSpacing: 8, alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
          if (pages.length > 1)
            SegmentedButton<int>(
              segments: [for (var k = 0; k < pages.length; k++) ButtonSegment(value: k, label: Text('${pages[k]}'))],
              selected: {_i},
              onSelectionChanged: (s) => setState(() {
                _i = s.first;
                _tc.value = Matrix4.identity();
              }),
            )
          else
            Pill(text: '${context.tr('page')} $page / $bookPageCount', colour: widget.colour, icon: Icons.menu_book_rounded),
          FilledButton.icon(
            key: const ValueKey('openReader'),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReaderScreen(initialPage: page))),
            icon: const Icon(Icons.open_in_full_rounded),
            label: Text(context.tr('openInReader')),
          ),
        ]),
      ),
    ]);
  }
}

// ----------------------------------------------------------------- learn
class _LearnTab extends StatelessWidget {
  const _LearnTab({required this.lesson, required this.words, required this.colour, required this.onComplete});
  final Lesson lesson;
  final List<VocabWord> words;
  final Color colour;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return EnglishContent(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final letter in lesson.letters) ...[
            _LetterCard(info: letterInfo(letter), colour: colour),
            const SizedBox(height: 12),
          ],
          if (words.isNotEmpty) ...[
            Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: [
              for (final w in words.take(lesson.letters.isEmpty ? 12 : 2))
                Panel(
                  padding: const EdgeInsets.all(8),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    WordPicture(word: w, size: 110),
                    Text(w.text, style: learningText(24)),
                    SpeakButton(text: w.spoken, size: 42, colour: colour),
                  ]),
                ),
            ]),
            const SizedBox(height: 14),
          ],
          if (lesson.language.isNotEmpty)
            Panel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Say it', style: learningText(20, color: colour)),
                const SizedBox(height: 6),
                for (final s in lesson.language)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      SpeakButton(text: s, size: 42, colour: colour),
                      const SizedBox(width: 10),
                      Expanded(child: Text(s, style: learningText(22))),
                    ]),
                  ),
              ]),
            ),
          if (lesson.bookActivities.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(context.tr('fromBook'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final a in lesson.bookActivities) Pill(text: a, colour: colour, icon: Icons.check_rounded),
            ]),
          ],
          if (lesson.kind == LessonKind.project) ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DrawingHomeScreen())),
              icon: const Icon(Icons.palette_rounded),
              label: Text(context.tr('drawing')),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: onComplete,
            icon: const Icon(Icons.emoji_events_rounded),
            label: Text(context.tr('markComplete')),
          ),
        ],
      ),
    );
  }
}

class _LetterCard extends StatelessWidget {
  const _LetterCard({required this.info, required this.colour});
  final LetterInfo info;
  final Color colour;

  @override
  Widget build(BuildContext context) => Panel(
        child: Row(children: [
          Text('${info.upper} ${info.lower}', style: learningText(72, color: colour)),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(spacing: 10, runSpacing: 10, children: [
              SpeakButton(text: info.upper, letterName: info.lower, colour: colour),
              SpeakButton(text: info.lower, letterSound: info.lower, colour: AppColors.orange),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LetterScreen(letter: info))),
                icon: const Icon(Icons.gesture_rounded),
                label: Text(context.tr('trace')),
              ),
            ]),
          ),
        ]),
      );
}

// ----------------------------------------------------------------- listen
class _ListenTab extends StatelessWidget {
  const _ListenTab({required this.lesson, required this.colour});
  final Lesson lesson;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    if (lesson.scripts.isEmpty && lesson.language.isEmpty) {
      return Center(child: Text(context.tr('noData')));
    }
    return ListView(padding: const EdgeInsets.all(16), children: [
      for (final s in lesson.scripts)
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(backgroundColor: colour.withValues(alpha: 0.15), child: Icon(scriptKindIcon(s.kind), color: colour)),
            title: EnglishContent(child: Text(s.title, style: learningText(20))),
            subtitle: Text('${scriptKindLabel(s.kind)}${s.track != null ? ' · Track ${s.track}' : ''}'),
            trailing: Icon(Icons.play_circle_fill_rounded, color: colour, size: 40),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ScriptPlayerScreen(script: s, bookPage: lesson.page, colour: colour))),
          ),
        ),
      if (lesson.language.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: FilledButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ListenRepeatScreen(
                    title: context.tr('listenAndSay'),
                    colour: colour,
                    items: [for (final s in lesson.language) RepeatItem(s)]))),
            icon: const Icon(Icons.record_voice_over_rounded),
            label: Text(context.tr('listenAndSay')),
          ),
        ),
    ]);
  }
}

// ----------------------------------------------------------------- words
class _WordsTab extends StatelessWidget {
  const _WordsTab({required this.words, required this.colour});
  final List<VocabWord> words;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty) return Center(child: Text(context.tr('noData')));
    return EnglishContent(
      child: LayoutBuilder(builder: (context, c) {
        final cols = gridColumns(c.maxWidth, minTile: 150);
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.8),
          itemCount: words.length + 1,
          itemBuilder: (context, i) {
            if (i == words.length) {
              return BigTile(
                title: context.tr('listenAndSay'),
                icon: Icons.record_voice_over_rounded,
                colour: colour,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ListenRepeatScreen(
                        title: context.tr('listenAndSay'),
                        colour: colour,
                        items: [for (final w in words) RepeatItem(w.spoken, word: w)]))),
              );
            }
            final w = words[i];
            return Panel(
              padding: const EdgeInsets.all(8),
              child: Column(children: [
                Expanded(child: WordPicture(word: w, size: 130)),
                Text(w.text, style: learningText(22)),
                SpeakButton(text: w.spoken, size: 42, colour: colour),
              ]),
            );
          },
        );
      }),
    );
  }
}

// ----------------------------------------------------------------- practise
class _PractiseTab extends StatelessWidget {
  const _PractiseTab({required this.lesson, required this.words, required this.colour, required this.onComplete});
  final Lesson lesson;
  final List<VocabWord> words;
  final Color colour;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final pics = words.where((w) => w.image != null || w.colour != null || w.count != null).toList();
    // Small sets are padded with other textbook words so there are always
    // enough options; the target words stay the lesson's own words.
    final pool = pics.length >= 4 ? pics : [...pics, ...vocabulary.where((w) => w.image != null).take(12)];
    final items = <Widget>[
      if (pics.isNotEmpty)
        BigTile(
          title: 'Listen and choose',
          icon: Icons.hearing_rounded,
          colour: colour,
          onTap: () => openChoiceGame(context,
              title: lesson.title,
              instruction: 'Listen and choose the picture.',
              makeRounds: () => RoundFactory().listenAndChoose(pool, rounds: 6, options: 3, targets: pics),
              kind: 'lesson',
              ref: lesson.id,
              unitId: lesson.unitId,
              colour: colour),
        ),
      if (pics.where((w) => w.image != null).length >= 2)
        BigTile(
          title: 'Word and picture',
          icon: Icons.image_search_rounded,
          colour: AppColors.primary,
          onTap: () => openChoiceGame(context,
              title: lesson.title,
              instruction: 'Match the word to the picture.',
              makeRounds: () => RoundFactory().wordToPicture(pool, rounds: 6, targets: pics),
              kind: 'lesson',
              ref: '${lesson.id}_read',
              unitId: lesson.unitId,
              colour: AppColors.primary),
        ),
      for (final l in lesson.letters)
        BigTile(
          title: '${context.tr('trace')} ${l.toUpperCase()} $l',
          icon: Icons.gesture_rounded,
          colour: AppColors.berry,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => AppPage(
                    title: '${context.tr('trace')} $l',
                    colour: AppColors.berry,
                    body: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TracingPad(
                        letter: l,
                        colour: AppColors.berry,
                        onPassed: (s) => AppScope.read(context)
                            .progress
                            .recordResult(kind: 'trace', ref: l, score: (s.coverage * 10).round().clamp(0, 10), total: 10),
                      ),
                    ),
                  ))),
        ),
      if (lesson.letters.isNotEmpty)
        BigTile(
          title: context.tr('initialSound'),
          icon: Icons.abc_rounded,
          colour: AppColors.coral,
          onTap: () => openChoiceGame(context,
              title: context.tr('initialSound'),
              instruction: 'Which picture starts with this sound?',
              makeRounds: () => RoundFactory().initialSound(rounds: 4, letters: lesson.letters),
              kind: 'lesson',
              ref: '${lesson.id}_sound',
              unitId: lesson.unitId,
              colour: AppColors.coral),
        ),
      if (lesson.language.isNotEmpty)
        BigTile(
          title: 'Listen and repeat',
          icon: Icons.record_voice_over_rounded,
          colour: AppColors.sky,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ListenRepeatScreen(
                  title: lesson.title, items: [for (final s in lesson.language) RepeatItem(s)]))),
        ),
      BigTile(
        title: context.tr('markComplete'),
        icon: Icons.emoji_events_rounded,
        colour: AppColors.success,
        onTap: onComplete,
      ),
    ];
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 700 ? 3 : 2;
      return GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: cols,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.15,
        children: items,
      );
    });
  }
}
