import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../app_scope.dart';
import '../../content/book_data.dart';
import '../../content/models.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../services/audio_service.dart';
import '../../widgets/celebration.dart';
import '../../widgets/common.dart';

// ===========================================================================
// Match uppercase and lowercase letters (tap a big letter, then its small one)
// ===========================================================================

class MatchCaseGame extends StatefulWidget {
  const MatchCaseGame({super.key, this.letters, this.rounds = 3, this.random});
  final List<String>? letters;
  final int rounds;
  final math.Random? random;

  @override
  State<MatchCaseGame> createState() => MatchCaseGameState();
}

class MatchCaseGameState extends State<MatchCaseGame> {
  late final math.Random _rnd = widget.random ?? math.Random();
  int _round = 0;
  late List<String> _left; // uppercase order
  late List<String> _right; // lowercase order
  final Set<String> _matched = {};
  String? _selected;
  int _mistakes = 0;
  int _score = 0;
  int _shake = 0;

  List<String> get left => _left;
  List<String> get right => _right;

  @override
  void initState() {
    super.initState();
    _newRound();
    WidgetsBinding.instance.addPostFrameCallback((_) => AppScope.read(context).audio.say('Match the big and small letters.'));
  }

  void _newRound() {
    final pool = List<String>.from(widget.letters ?? alphabet.map((l) => l.lower))..shuffle(_rnd);
    final set = pool.take(math.min(5, pool.length)).toList();
    _left = List.of(set)..shuffle(_rnd);
    _right = List.of(set)..shuffle(_rnd);
    _matched.clear();
    _selected = null;
    _mistakes = 0;
  }

  void tapUpper(String l) {
    if (_matched.contains(l)) return;
    setState(() => _selected = l);
    AppScope.read(context).audio.letterName(l);
  }

  Future<void> tapLower(String l) async {
    final audio = AppScope.read(context).audio;
    if (_selected == null || _matched.contains(l)) {
      audio.letterName(l);
      return;
    }
    if (_selected == l) {
      audio.sfx(Sfx.correct);
      setState(() {
        _matched.add(l);
        _selected = null;
      });
      if (_matched.length == _left.length) {
        if (_mistakes == 0) _score++;
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        if (_round + 1 >= widget.rounds) {
          final again = await finishActivity(context, kind: 'game_case', ref: 'match_case', score: _score, total: widget.rounds);
          if (!mounted) return;
          if (again) {
            setState(() {
              _round = 0;
              _score = 0;
              _newRound();
            });
          } else {
            Navigator.of(context).maybePop();
          }
        } else {
          setState(() {
            _round++;
            _newRound();
          });
        }
      }
    } else {
      audio.sfx(Sfx.wrong);
      setState(() {
        _mistakes++;
        _shake++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget tile(String text, {required bool selected, required bool done, required VoidCallback onTap, required Color colour, Key? key}) {
      return AnimatedOpacity(
        key: key,
        opacity: done ? 0.25 : 1,
        duration: const Duration(milliseconds: 250),
        child: Material(
          color: selected ? colour : Colors.white,
          borderRadius: BorderRadius.circular(22),
          elevation: selected ? 4 : 1,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: done ? null : onTap,
            child: SizedBox(
              width: 86,
              height: 86,
              child: Center(child: Text(text, style: learningText(52, color: selected ? Colors.white : colour))),
            ),
          ),
        ),
      );
    }

    return AppPage(
      title: context.tr('matchCase'),
      colour: AppColors.coral,
      body: EnglishContent(
        child: Column(children: [
          Text('${_round + 1} / ${widget.rounds}', style: learningText(18, color: AppColors.inkSoft)),
          Text('Match the big and small letters.', style: learningText(18, color: AppColors.inkSoft, weight: FontWeight.w600)),
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Shake(
                  trigger: _shake,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Column(children: [
                      for (final l in _left)
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: tile(l.toUpperCase(),
                              key: ValueKey('upper_$l'),
                              selected: _selected == l,
                              done: _matched.contains(l),
                              onTap: () => tapUpper(l),
                              colour: AppColors.coral),
                        ),
                    ]),
                    const SizedBox(width: 40),
                    Column(children: [
                      for (final l in _right)
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: tile(l,
                              key: ValueKey('lower_$l'),
                              selected: false,
                              done: _matched.contains(l),
                              onTap: () => tapLower(l),
                              colour: AppColors.primary),
                        ),
                    ]),
                  ]),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ===========================================================================
// Arrange letters into words
// ===========================================================================

class ArrangeLettersGame extends StatefulWidget {
  const ArrangeLettersGame({super.key, this.rounds = 6, this.random, this.words});
  final int rounds;
  final math.Random? random;
  final List<VocabWord>? words;

  @override
  State<ArrangeLettersGame> createState() => ArrangeLettersGameState();
}

class ArrangeLettersGameState extends State<ArrangeLettersGame> {
  late final math.Random _rnd = widget.random ?? math.Random();
  late List<VocabWord> _words;
  int _index = 0;
  late List<String> _tiles; // scrambled letters
  final List<int> _placed = []; // indexes into _tiles
  bool _firstTry = true;
  int _score = 0;
  int _shake = 0;
  bool _solved = false;

  VocabWord get word => _words[_index];

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    final pool = (widget.words ??
            vocabulary.where((w) => w.topic == topicAlphabet && w.image != null && RegExp(r'^[a-z]{3,5}$').hasMatch(w.text)).toList())
        .toList()
      ..shuffle(_rnd);
    _words = pool.take(widget.rounds).toList();
    _index = 0;
    _score = 0;
    _setup();
  }

  void _setup() {
    final letters = word.text.split('');
    do {
      letters.shuffle(_rnd);
    } while (letters.join() == word.text && word.text.split('').toSet().length > 1);
    _tiles = letters;
    _placed.clear();
    _firstTry = true;
    _solved = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.read(context).audio.say(word.spoken);
    });
  }

  Future<void> place(int tileIndex) async {
    if (_placed.contains(tileIndex) || _solved) return;
    final audio = AppScope.read(context).audio;
    audio.sfx(Sfx.tap);
    setState(() => _placed.add(tileIndex));
    if (_placed.length == _tiles.length) {
      final attempt = _placed.map((i) => _tiles[i]).join();
      final progress = AppScope.read(context).progress;
      if (attempt == word.text) {
        _solved = true;
        if (_firstTry) _score++;
        progress.recordWord(word.id, _firstTry);
        audio.sfx(Sfx.correct);
        await audio.say(word.spoken);
        await Future<void>.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;
        if (_index + 1 >= _words.length) {
          final again = await finishActivity(context, kind: 'game_spell', ref: 'arrange', score: _score, total: _words.length);
          if (!mounted) return;
          if (again) {
            setState(_start);
          } else {
            Navigator.of(context).maybePop();
          }
        } else {
          setState(() {
            _index++;
            _setup();
          });
        }
      } else {
        audio.sfx(Sfx.wrong);
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        setState(() {
          _firstTry = false;
          _shake++;
          _placed.clear();
        });
      }
    }
  }

  void undo() {
    if (_placed.isEmpty || _solved) return;
    setState(() => _placed.removeLast());
  }

  @override
  Widget build(BuildContext context) {
    final placedLetters = _placed.map((i) => _tiles[i]).toList();
    return AppPage(
      title: 'Spell the word',
      colour: AppColors.grape,
      body: EnglishContent(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Text('Put the letters in order.', style: learningText(18, color: AppColors.inkSoft, weight: FontWeight.w600)),
            Text('${_index + 1} / ${_words.length}', style: learningText(16, color: AppColors.inkSoft)),
            const SizedBox(height: 8),
            WordPicture(word: word, size: 150),
            SpeakButton(text: word.spoken, colour: AppColors.grape),
            const SizedBox(height: 16),
            Shake(
              trigger: _shake,
              child: Wrap(spacing: 8, children: [
                for (var i = 0; i < _tiles.length; i++)
                  Container(
                    key: ValueKey('slot_$i'),
                    width: 58,
                    height: 66,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i < placedLetters.length ? (_solved ? AppColors.success : AppColors.grape) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.grape.withValues(alpha: 0.4), width: 2),
                    ),
                    child: Text(i < placedLetters.length ? placedLetters[i] : '',
                        style: learningText(36, color: Colors.white)),
                  ),
              ]),
            ),
            const SizedBox(height: 22),
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (var i = 0; i < _tiles.length; i++)
                AnimatedOpacity(
                  opacity: _placed.contains(i) ? 0.2 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: Material(
                    color: AppColors.sunshine,
                    borderRadius: BorderRadius.circular(16),
                    elevation: 2,
                    child: InkWell(
                      key: ValueKey('tile_$i'),
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => place(i),
                      child: SizedBox(
                          width: 62, height: 70, child: Center(child: Text(_tiles[i], style: learningText(38)))),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 16),
            TextButton.icon(onPressed: undo, icon: const Icon(Icons.undo_rounded), label: Text(context.tr('back'))),
          ]),
        ),
      ),
    );
  }
}

// ===========================================================================
// Memory cards: match a picture with its word
// ===========================================================================

class MemoryGame extends StatefulWidget {
  const MemoryGame({super.key, this.pairs = 6, this.random, this.words});
  final int pairs;
  final math.Random? random;
  final List<VocabWord>? words;

  @override
  State<MemoryGame> createState() => MemoryGameState();
}

class _Card {
  _Card(this.word, this.isPicture);
  final VocabWord word;
  final bool isPicture;
  bool faceUp = false;
  bool matched = false;
}

class MemoryGameState extends State<MemoryGame> {
  late final math.Random _rnd = widget.random ?? math.Random();
  late List<_Card> _cards;
  final List<int> _open = [];
  int _moves = 0;
  bool _busy = false;

  int get moves => _moves;
  List<String> get cardWords => _cards.map((c) => '${c.word.text}:${c.isPicture}').toList();

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    final pool = (widget.words ?? vocabulary.where((w) => w.image != null && w.topic == topicAlphabet).toList()).toList()
      ..shuffle(_rnd);
    final chosen = <VocabWord>[];
    for (final w in pool) {
      if (chosen.every((c) => c.text != w.text)) chosen.add(w);
      if (chosen.length == widget.pairs) break;
    }
    _cards = [for (final w in chosen) ...[_Card(w, true), _Card(w, false)]]..shuffle(_rnd);
    _open.clear();
    _moves = 0;
    _busy = false;
  }

  Future<void> flip(int i) async {
    if (_busy || _cards[i].faceUp || _cards[i].matched) return;
    final audio = AppScope.read(context).audio;
    audio.sfx(Sfx.flip);
    setState(() {
      _cards[i].faceUp = true;
      _open.add(i);
    });
    if (_open.length < 2) return;
    _moves++;
    final a = _cards[_open[0]];
    final b = _cards[_open[1]];
    if (a.word.text == b.word.text && a.isPicture != b.isPicture) {
      audio.sfx(Sfx.correct);
      setState(() {
        a.matched = true;
        b.matched = true;
        _open.clear();
      });
      AppScope.read(context).progress.recordWord(a.word.id, true);
      await audio.say(a.word.spoken);
      if (_cards.every((c) => c.matched)) {
        if (!mounted) return;
        // Perfect = one move per pair; still always at least one star.
        final score = (widget.pairs * 2 - _moves).clamp(0, widget.pairs) + (widget.pairs - (widget.pairs * 2 - _moves).clamp(0, widget.pairs)) ~/ 2;
        final again = await finishActivity(context, kind: 'game_memory', ref: 'memory', score: score, total: widget.pairs);
        if (!mounted) return;
        if (again) {
          setState(_start);
        } else {
          Navigator.of(context).maybePop();
        }
      }
    } else {
      _busy = true;
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      setState(() {
        a.faceUp = false;
        b.faceUp = false;
        _open.clear();
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Memory cards',
      colour: AppColors.teal,
      body: EnglishContent(
        child: LayoutBuilder(builder: (context, c) {
          final cols = c.maxWidth > c.maxHeight ? 6 : (c.maxWidth > 600 ? 4 : 3);
          final rows = (_cards.length / cols).ceil();
          final size = math.min((c.maxWidth - 32 - (cols - 1) * 10) / cols, (c.maxHeight - 60 - (rows - 1) * 10) / rows);
          return Column(children: [
            Text('Find the pairs.', style: learningText(18, color: AppColors.inkSoft, weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (var i = 0; i < _cards.length; i++)
                      _MemoryCard(key: ValueKey('card_$i'), card: _cards[i], size: size, onTap: () => flip(i)),
                  ],
                ),
              ),
            ),
          ]);
        }),
      ),
    );
  }
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({super.key, required this.card, required this.size, required this.onTap});
  final _Card card;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final up = card.faceUp || card.matched;
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: up ? 1 : 0),
        duration: const Duration(milliseconds: 300),
        builder: (context, v, _) {
          final showFront = v > 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(math.pi * v),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: showFront ? Colors.white : AppColors.teal,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: card.matched ? AppColors.success : Colors.transparent, width: 4),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6)],
              ),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateY(showFront ? math.pi : 0),
                child: showFront
                    ? Padding(
                        padding: const EdgeInsets.all(6),
                        child: card.isPicture
                            ? WordPicture(word: card.word, size: size * 0.8)
                            : FittedBox(child: Text(card.word.text, style: learningText(30))),
                      )
                    : Icon(Icons.question_mark_rounded, color: Colors.white, size: size * 0.45),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ===========================================================================
// Drag and drop: drag each picture to the letter it starts with
// ===========================================================================

class DragDropGame extends StatefulWidget {
  const DragDropGame({super.key, this.rounds = 3, this.random});
  final int rounds;
  final math.Random? random;

  @override
  State<DragDropGame> createState() => DragDropGameState();
}

class DragDropGameState extends State<DragDropGame> {
  late final math.Random _rnd = widget.random ?? math.Random();
  int _round = 0;
  late List<String> _letters;
  late List<VocabWord> _items;
  final Set<String> _done = {};
  int _mistakes = 0;
  int _score = 0;

  List<String> get letters => _letters;
  List<VocabWord> get items => _items;

  @override
  void initState() {
    super.initState();
    _setup();
    WidgetsBinding.instance.addPostFrameCallback((_) => AppScope.read(context).audio.say('Drag the picture to its letter.'));
  }

  void _setup() {
    final ls = alphabet.where((l) => l.words.length >= 2).map((l) => l.lower).toList()..shuffle(_rnd);
    _letters = ls.take(3).toList();
    _items = [
      for (final l in _letters) ...letterInfo(l).words.map((id) => vocabularyById[id]!).where((w) => w.image != null),
    ]..shuffle(_rnd);
    _done.clear();
    _mistakes = 0;
  }

  Future<void> drop(VocabWord w, String letter) async {
    final services = AppScope.read(context);
    if (w.text.startsWith(letter)) {
      services.audio.sfx(Sfx.correct);
      services.progress.recordWord(w.id, true);
      setState(() => _done.add(w.id));
      await services.audio.say(w.spoken);
      if (_done.length == _items.length) {
        if (_mistakes <= 1) _score++;
        if (!mounted) return;
        if (_round + 1 >= widget.rounds) {
          final again = await finishActivity(context, kind: 'game_drag', ref: 'drag_drop', score: _score, total: widget.rounds);
          if (!mounted) return;
          if (again) {
            setState(() {
              _round = 0;
              _score = 0;
              _setup();
            });
          } else {
            Navigator.of(context).maybePop();
          }
        } else {
          setState(() {
            _round++;
            _setup();
          });
        }
      }
    } else {
      services.audio.sfx(Sfx.wrong);
      setState(() => _mistakes++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _items.where((w) => !_done.contains(w.id)).toList();
    return AppPage(
      title: 'Drag and drop',
      colour: AppColors.orange,
      body: EnglishContent(
        child: Column(children: [
          Text('Drag the picture to its letter.', style: learningText(18, color: AppColors.inkSoft, weight: FontWeight.w600)),
          Text('${_round + 1} / ${widget.rounds}', style: learningText(16, color: AppColors.inkSoft)),
          Expanded(
            child: Center(
              child: Wrap(spacing: 14, runSpacing: 14, alignment: WrapAlignment.center, children: [
                for (final w in remaining)
                  Draggable<VocabWord>(
                    key: ValueKey('drag_${w.id}'),
                    data: w,
                    feedback: Material(color: Colors.transparent, child: WordPicture(word: w, size: 110)),
                    childWhenDragging: Opacity(opacity: 0.3, child: WordPicture(word: w, size: 100)),
                    child: Panel(padding: const EdgeInsets.all(6), child: WordPicture(word: w, size: 100)),
                  ),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
            child: Row(children: [
              for (final l in _letters)
                Expanded(
                  child: DragTarget<VocabWord>(
                    key: ValueKey('target_$l'),
                    onAcceptWithDetails: (d) => drop(d.data, l),
                    builder: (context, cand, _) => AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.all(6),
                      height: 130,
                      decoration: BoxDecoration(
                        color: cand.isNotEmpty ? AppColors.sunshine : Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: AppColors.orange, width: 3),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('${l.toUpperCase()} $l', style: learningText(44, color: AppColors.orange)),
                        Wrap(children: [
                          for (final w in _items.where((w) => _done.contains(w.id) && w.text.startsWith(l)))
                            WordPicture(word: w, size: 34),
                        ]),
                      ]),
                    ),
                  ),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}
