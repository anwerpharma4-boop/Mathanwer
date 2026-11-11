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
import '../games/choice_game.dart';
import '../games/choice_round.dart';
import '../reader/reader_screen.dart';
import 'tracing.dart';

class LetterScreen extends StatefulWidget {
  const LetterScreen({super.key, required this.letter});
  final LetterInfo letter;

  @override
  State<LetterScreen> createState() => _LetterScreenState();
}

class _LetterScreenState extends State<LetterScreen> {
  bool _upper = false;
  static const colour = Color(0xFFE5484D);

  LetterInfo get l => widget.letter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => AppScope.read(context).audio.letterName(l.lower));
  }

  void _openPage(int page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReaderScreen(initialPage: page)));

  List<String> _quizLetters() {
    final i = alphabet.indexOf(l);
    return [for (var k = math.max(0, i - 2); k <= math.min(alphabet.length - 1, i + 2); k++) alphabet[k].lower];
  }

  @override
  Widget build(BuildContext context) {
    final words = l.words.map((id) => vocabularyById[id]!).toList();
    final next = alphabet.indexOf(l) + 1 < alphabet.length ? alphabet[alphabet.indexOf(l) + 1] : null;
    return AppPage(
      title: '${context.tr('alphabet')}: ${l.upper} ${l.lower}',
      colour: colour,
      actions: [
        if (next != null)
          IconButton(
            tooltip: context.tr('next'),
            icon: const Icon(Icons.arrow_forward_rounded),
            onPressed: () =>
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => LetterScreen(letter: next))),
          ),
      ],
      body: EnglishContent(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Panel(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 24,
                runSpacing: 12,
                children: [
                  Text(
                    '${l.upper} ${l.lower}',
                    key: const ValueKey('bigLetter'),
                    style: learningText(110, color: colour),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SoundRow(
                        label: context.tr('letterName'),
                        ipa: '/${l.nameIpa}/',
                        button: SpeakButton(
                          key: const ValueKey('letterNameBtn'),
                          text: l.upper,
                          letterName: l.lower,
                          colour: colour,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _SoundRow(
                        label: context.tr('letterSound'),
                        ipa: '/${l.soundIpa}/  ·  ${l.soundHint}',
                        button: SpeakButton(
                          key: const ValueKey('letterSoundBtn'),
                          text: l.lower,
                          letterSound: l.lower,
                          colour: AppColors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionTitle(context.tr('examples')),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                Panel(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(l.cardImage, width: 120, height: 150, fit: BoxFit.contain),
                      TextButton.icon(
                        onPressed: () => _openPage(l.cardPage),
                        icon: const Icon(Icons.menu_book_rounded, size: 18),
                        label: Text('${context.tr('page')} ${l.cardPage}'),
                      ),
                    ],
                  ),
                ),
                for (final w in words)
                  Panel(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        WordPicture(word: w, size: 120),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: w.text.substring(0, 1),
                                style: learningText(28, color: colour),
                              ),
                              TextSpan(text: w.text.substring(1), style: learningText(28)),
                            ],
                          ),
                        ),
                        SpeakButton(text: w.spoken, size: 44),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _openPage(l.lessonPage),
                icon: const Icon(Icons.auto_stories_rounded),
                label: Text('${context.tr('openInReader')} · ${context.tr('page')} ${l.lessonPage}'),
              ),
            ),
            const SizedBox(height: 14),
            _SectionTitle(context.tr('trace')),
            Center(
              child: SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: false, label: Text(l.lower, style: learningText(22))),
                  ButtonSegment(value: true, label: Text(l.upper, style: learningText(22))),
                ],
                selected: {_upper},
                onSelectionChanged: (s) => setState(() => _upper = s.first),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 420,
              child: TracingPad(
                letter: _upper ? l.upper : l.lower,
                colour: colour,
                onPassed: (score) async {
                  await AppScope.read(context).progress.recordResult(
                    kind: 'trace',
                    ref: l.lower,
                    score: (score.coverage * 10).round().clamp(0, 10),
                    total: 10,
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            _SectionTitle(context.tr('findLetter')),
            FindLetterGrid(letter: l.lower),
            const SizedBox(height: 18),
            FilledButton.icon(
              key: const ValueKey('miniQuiz'),
              style: FilledButton.styleFrom(backgroundColor: colour),
              onPressed: () => openChoiceGame(
                context,
                title: '${context.tr('miniQuiz')}: ${l.upper} ${l.lower}',
                instruction: 'Which picture starts with this sound?',
                makeRounds: () {
                  final f = RoundFactory();
                  final letters = _quizLetters();
                  return [
                    ...f.initialSound(rounds: 2, letters: [l.lower]),
                    ...f.upperLower(rounds: 1, letters: [l.lower]),
                    ...f.findLetter(rounds: 1, letters: [l.lower], upper: false),
                    ...f.initialSound(rounds: 1, letters: letters),
                  ];
                },
                kind: 'alphabet',
                ref: 'quiz_${l.lower}',
                colour: colour,
              ),
              icon: const Icon(Icons.quiz_rounded),
              label: Text(context.tr('miniQuiz')),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoundRow extends StatelessWidget {
  const _SoundRow({required this.label, required this.ipa, required this.button});
  final String label;
  final String ipa;
  final Widget button;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      button,
      const SizedBox(width: 10),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text(ipa, style: const TextStyle(color: AppColors.inkSoft, fontSize: 15)),
        ],
      ),
    ],
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
  );
}

/// "Find and point" letter recognition, like the textbook letter grids
/// (e.g. page 14): tap every copy of the target letter.
class FindLetterGrid extends StatefulWidget {
  const FindLetterGrid({super.key, required this.letter, this.random});
  final String letter;
  final math.Random? random;

  @override
  State<FindLetterGrid> createState() => FindLetterGridState();
}

class FindLetterGridState extends State<FindLetterGrid> {
  late List<String> _cells;
  final Set<int> _found = {};
  final Set<int> _misses = {};
  bool _done = false;

  List<String> get cells => _cells;

  @override
  void initState() {
    super.initState();
    _build();
  }

  void _build() {
    final rnd = widget.random ?? math.Random();
    final others = alphabet.map((l) => l.lower).where((x) => x != widget.letter).toList()..shuffle(rnd);
    _cells = [...List.filled(4, widget.letter), ...others.take(8)]..shuffle(rnd);
    _found.clear();
    _misses.clear();
    _done = false;
  }

  Future<void> tap(int i) async {
    if (_found.contains(i) || _done) return;
    final services = AppScope.read(context);
    if (_cells[i] == widget.letter) {
      services.audio.sfx(Sfx.correct);
      setState(() => _found.add(i));
      if (_found.length == 4) {
        _done = true;
        await services.audio.letterName(widget.letter);
        if (!mounted) return;
        await finishActivity(
          context,
          kind: 'alphabet',
          ref: 'find_${widget.letter}',
          score: math.max(0, 4 - _misses.length),
          total: 4,
        );
        if (mounted) setState(_build);
      }
    } else {
      services.audio.sfx(Sfx.wrong);
      setState(() => _misses.add(i));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        children: [
          Text('Find the letter ${widget.letter}', style: learningText(20, color: AppColors.inkSoft)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              for (var i = 0; i < _cells.length; i++)
                GestureDetector(
                  key: ValueKey('find_$i'),
                  onTap: () => tap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _found.contains(i)
                          ? AppColors.success.withValues(alpha: 0.2)
                          : (_misses.contains(i)
                                ? AppColors.gentleError.withValues(alpha: 0.15)
                                : const Color(0xFFF4F6FA)),
                      shape: BoxShape.circle,
                      border: Border.all(color: _found.contains(i) ? AppColors.success : Colors.transparent, width: 3),
                    ),
                    child: Text(_cells[i], style: learningText(36, color: AppTheme.letterColour(i))),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
