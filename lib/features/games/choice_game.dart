import 'package:material_ui/material_ui.dart';

import '../../app_scope.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../services/audio_service.dart';
import '../../widgets/celebration.dart';
import '../../widgets/common.dart';
import 'choice_round.dart';

/// Generic multiple-choice activity used by many games, the alphabet module
/// and the quizzes. Wrong answers are never punished: the child simply tries
/// again; only first-try answers count towards the score.
class ChoiceGameScreen extends StatefulWidget {
  const ChoiceGameScreen({
    super.key,
    required this.title,
    required this.instruction,
    required this.makeRounds,
    required this.kind,
    required this.ref,
    this.unitId,
    this.colour = AppColors.primary,
  });

  final String title;

  /// English instruction (spoken in British English and shown on screen).
  final String instruction;
  final List<ChoiceRound> Function() makeRounds;
  final String kind;
  final String ref;
  final int? unitId;
  final Color colour;

  @override
  State<ChoiceGameScreen> createState() => ChoiceGameScreenState();
}

class ChoiceGameScreenState extends State<ChoiceGameScreen> {
  late List<ChoiceRound> _rounds;
  int _index = 0;
  int _score = 0;
  bool _firstTry = true;
  final Set<int> _wrong = {};
  int? _correctPicked;
  int _shake = 0;
  bool _finished = false;

  int get score => _score;
  int get index => _index;
  List<ChoiceRound> get rounds => _rounds;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _rounds = widget.makeRounds();
    _index = 0;
    _score = 0;
    _finished = false;
    _resetRound();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await AppScope.read(context).audio.say(widget.instruction);
      _playPrompt();
    });
  }

  void _resetRound() {
    _firstTry = true;
    _wrong.clear();
    _correctPicked = null;
  }

  ChoiceRound get _round => _rounds[_index];

  Future<void> _playPrompt() async {
    if (!mounted || _rounds.isEmpty) return;
    final audio = AppScope.read(context).audio;
    final p = _round.prompt;
    if (p.letterName != null && p.letterSound == null) {
      await audio.letterName(p.letterName!);
    } else if (p.letterSound != null) {
      await audio.letterSound(p.letterSound!);
    } else if (p.speak != null) {
      await audio.say(p.speak!);
    }
  }

  Future<void> choose(int i) async {
    if (_correctPicked != null || _finished || _wrong.contains(i)) return;
    final services = AppScope.read(context);
    final round = _round;
    if (i == round.answer) {
      if (_firstTry) _score++;
      setState(() => _correctPicked = i);
      services.audio.sfx(Sfx.correct);
      if (round.wordId != null) services.progress.recordWord(round.wordId!, _firstTry);
      if (round.sayOnCorrect != null) {
        await services.audio.say(round.sayOnCorrect!);
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 700));
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      if (_index + 1 >= _rounds.length) {
        _finish();
      } else {
        setState(() {
          _index++;
          _resetRound();
        });
        _playPrompt();
      }
    } else {
      services.audio.sfx(Sfx.wrong);
      setState(() {
        _firstTry = false;
        _wrong.add(i);
        _shake++;
      });
    }
  }

  Future<void> _finish() async {
    setState(() => _finished = true);
    final again = await finishActivity(context,
        kind: widget.kind, ref: widget.ref, unitId: widget.unitId, score: _score, total: _rounds.length);
    if (!mounted) return;
    if (again) {
      setState(_start);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  late AudioOut _audio;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audio = AppScope.read(context).audio;
  }

  @override
  void dispose() {
    _audio.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_rounds.isEmpty) {
      return AppPage(
        title: widget.title,
        colour: widget.colour,
        body: Center(child: Text(context.tr('nothingToReview'), style: const TextStyle(fontSize: 18))),
      );
    }
    final round = _round;
    return AppPage(
      title: widget.title,
      colour: widget.colour,
      body: LayoutBuilder(builder: (context, c) {
        final landscape = c.maxWidth > c.maxHeight * 1.1;
        final prompt = _PromptView(
          round: round,
          answered: _correctPicked != null,
          onReplay: _playPrompt,
          colour: widget.colour,
        );
        final options = Shake(
          trigger: _shake,
          child: _OptionsGrid(
            round: round,
            wrong: _wrong,
            correct: _correctPicked,
            onTap: choose,
            maxWidth: landscape ? c.maxWidth * 0.55 : c.maxWidth,
          ),
        );
        return Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [
              EnglishContent(
                child: Text(widget.instruction,
                    textAlign: TextAlign.center,
                    style: learningText(18, color: AppColors.inkSoft, weight: FontWeight.w600)),
              ),
              const SizedBox(height: 8),
              _ProgressDots(count: _rounds.length, index: _index, colour: widget.colour),
            ]),
          ),
          Expanded(
            child: landscape
                ? Row(children: [
                    Expanded(child: Center(child: prompt)),
                    Expanded(child: Center(child: options)),
                  ])
                : Column(children: [
                    Expanded(flex: 5, child: Center(child: prompt)),
                    Expanded(flex: 6, child: Center(child: options)),
                  ]),
          ),
        ]);
      }),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.count, required this.index, required this.colour});
  final int count;
  final int index;
  final Color colour;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 6,
        children: List.generate(
            count,
            (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: i == index ? 26 : 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: i <= index ? colour : colour.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                )),
      );
}

class _PromptView extends StatelessWidget {
  const _PromptView({required this.round, required this.answered, required this.onReplay, required this.colour});
  final ChoiceRound round;
  final bool answered;
  final VoidCallback onReplay;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    final p = round.prompt;
    final hasAudio = p.speak != null || p.letterName != null || p.letterSound != null;
    final showText = p.text != null && (!p.hideTextUntilAnswered || answered);
    return EnglishContent(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (p.picture != null)
            p.repeat > 1
                ? ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 6,
                      runSpacing: 6,
                      children: List.generate(p.repeat, (_) => WordPicture(word: p.picture!, size: p.repeat > 6 ? 70 : 92)),
                    ),
                  )
                : WordPicture(word: p.picture!, size: 150),
          if (showText)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(p.text!, key: const ValueKey('promptText'), style: learningText(p.text!.length <= 2 ? 84 : 46, color: colour)),
            ),
          if (!showText && p.picture == null)
            Icon(Icons.hearing_rounded, size: 90, color: colour.withValues(alpha: 0.5)),
          if (hasAudio) ...[
            const SizedBox(height: 10),
            SpeakButton(
              key: const ValueKey('replayPrompt'),
              text: p.speak ?? p.text ?? '',
              size: 64,
              colour: colour,
              letterName: p.letterSound == null ? p.letterName : null,
              letterSound: p.letterSound,
            ),
          ],
        ]),
      ),
    );
  }
}

class _OptionsGrid extends StatelessWidget {
  const _OptionsGrid({required this.round, required this.wrong, required this.correct, required this.onTap, required this.maxWidth});
  final ChoiceRound round;
  final Set<int> wrong;
  final int? correct;
  final void Function(int) onTap;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final n = round.options.length;
    final size = ((maxWidth - 48) / (n == 4 ? 2 : n)).clamp(90.0, 170.0);
    return EnglishContent(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 14,
        runSpacing: 14,
        children: [
          for (var i = 0; i < n; i++)
            _OptionTile(
              key: ValueKey('option_$i'),
              option: round.options[i],
              size: size,
              state: correct == i ? _OptState.correct : (wrong.contains(i) ? _OptState.wrong : _OptState.idle),
              onTap: () => onTap(i),
            ),
        ],
      ),
    );
  }
}

enum _OptState { idle, correct, wrong }

class _OptionTile extends StatelessWidget {
  const _OptionTile({super.key, required this.option, required this.size, required this.state, required this.onTap});
  final ChoiceOption option;
  final double size;
  final _OptState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = switch (state) {
      _OptState.correct => AppColors.success,
      _OptState.wrong => AppColors.gentleError,
      _OptState.idle => Colors.transparent,
    };
    Widget content;
    if (option.letter != null) {
      content = Text(option.letter!, style: learningText(size * 0.5));
    } else if (option.word != null && option.showPicture) {
      content = WordPicture(word: option.word!, size: size * 0.78);
    } else {
      final t = option.word?.text ?? option.text ?? '';
      content = Padding(
        padding: const EdgeInsets.all(8),
        child: FittedBox(child: Text(t, style: learningText(size * 0.26))),
      );
    }
    return Semantics(
      button: true,
      label: option.word?.text ?? option.letter ?? option.text,
      child: AnimatedScale(
        scale: state == _OptState.correct ? 1.08 : 1,
        duration: const Duration(milliseconds: 200),
        child: AnimatedOpacity(
          opacity: state == _OptState.wrong ? 0.45 : 1,
          duration: const Duration(milliseconds: 200),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            elevation: 2,
            child: InkWell(
              borderRadius: BorderRadius.circular(26),
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: border, width: 5),
                ),
                child: Stack(alignment: Alignment.center, children: [
                  content,
                  if (state == _OptState.correct)
                    const Positioned(top: 4, right: 4, child: Icon(Icons.check_circle_rounded, color: AppColors.success, size: 30)),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Convenience to open a choice game.
Future<void> openChoiceGame(
  BuildContext context, {
  required String title,
  required String instruction,
  required List<ChoiceRound> Function() makeRounds,
  required String kind,
  required String ref,
  int? unitId,
  Color colour = AppColors.primary,
}) =>
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChoiceGameScreen(
        title: title,
        instruction: instruction,
        makeRounds: makeRounds,
        kind: kind,
        ref: ref,
        unitId: unitId,
        colour: colour,
      ),
    ));
