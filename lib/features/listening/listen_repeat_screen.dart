import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../app_scope.dart';
import '../../content/book_data.dart';
import '../../content/models.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../services/recorder.dart';
import '../../widgets/celebration.dart';
import '../../widgets/common.dart';
import 'speed_control.dart';

/// Something to listen to and repeat (a word or a sentence from the book).
class RepeatItem {
  const RepeatItem(this.text, {this.word});
  final String text;
  final VocabWord? word;
}

/// A random mix of words with pictures and key sentences from the lessons.
List<RepeatItem> listenRepeatDefault({int count = 8, math.Random? random}) {
  final rnd = random ?? math.Random();
  final words = vocabulary.where((w) => w.image != null).toList()..shuffle(rnd);
  final sentences = <String>{for (final l in allLessons) ...l.language.where((s) => s.contains(' '))}.toList()
    ..shuffle(rnd);
  final out = <RepeatItem>[];
  for (var i = 0; out.length < count; i++) {
    if (i.isEven && words.isNotEmpty) {
      final w = words.removeLast();
      if (out.every((o) => o.text != w.text)) out.add(RepeatItem(w.spoken, word: w));
    } else if (sentences.isNotEmpty) {
      out.add(RepeatItem(sentences.removeLast()));
    }
    if (words.isEmpty && sentences.isEmpty) break;
  }
  return out;
}

/// Listen to the British English model, say it aloud, optionally record
/// yourself and compare. (No automatic speech recognition is used.)
class ListenRepeatScreen extends StatefulWidget {
  const ListenRepeatScreen({super.key, required this.title, required this.items, this.colour = AppColors.sky});
  final String title;
  final List<RepeatItem> items;
  final Color colour;

  @override
  State<ListenRepeatScreen> createState() => _ListenRepeatScreenState();
}

class _ListenRepeatScreenState extends State<ListenRepeatScreen> {
  int _i = 0;
  final VoiceRecorder _rec = VoiceRecorder();
  bool _recording = false;
  bool _hasMine = false;
  bool _micFailed = false;

  RepeatItem get item => widget.items[_i];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  @override
  void dispose() {
    _rec.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    if (!mounted) return;
    await AppScope.read(context).audio.say(item.text);
  }

  Future<void> _toggleRecord() async {
    if (_recording) {
      await _rec.stop();
      setState(() {
        _recording = false;
        _hasMine = _rec.hasRecording;
      });
      if (_hasMine) await _rec.playBack();
    } else {
      await AppScope.read(context).audio.stop();
      final ok = await _rec.start();
      setState(() {
        _recording = ok;
        _micFailed = !ok;
      });
    }
  }

  Future<void> _next() async {
    if (_recording) await _rec.stop();
    if (!mounted) return;
    if (_i + 1 >= widget.items.length) {
      final again = await finishActivity(
        context,
        kind: 'speak',
        ref: widget.title,
        score: widget.items.length,
        total: widget.items.length,
      );
      if (!mounted) return;
      if (again) {
        setState(() => _i = 0);
        _play();
      } else {
        Navigator.of(context).maybePop();
      }
      return;
    }
    setState(() {
      _i++;
      _recording = false;
      _hasMine = false;
    });
    _play();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return AppPage(title: widget.title, body: const SizedBox.shrink());
    }
    return AppPage(
      title: widget.title,
      colour: widget.colour,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Text(
                  '${_i + 1} / ${widget.items.length}',
                  style: const TextStyle(fontSize: 16, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 8),
                Panel(
                  child: EnglishContent(
                    child: Column(
                      children: [
                        if (item.word != null) WordPicture(word: item.word!, size: 170),
                        const SizedBox(height: 8),
                        Text(
                          item.word?.text ?? item.text,
                          key: const ValueKey('repeatText'),
                          textAlign: TextAlign.center,
                          style: learningText(36, color: widget.colour),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: [
                    _RoundAction(
                      key: const ValueKey('listenModel'),
                      icon: Icons.volume_up_rounded,
                      label: context.tr('listen'),
                      colour: widget.colour,
                      onTap: _play,
                    ),
                    _RoundAction(
                      key: const ValueKey('recordMine'),
                      icon: _recording ? Icons.stop_rounded : Icons.mic_rounded,
                      label: _recording ? context.tr('recording') : context.tr('record'),
                      colour: _recording ? AppColors.coral : AppColors.berry,
                      onTap: _toggleRecord,
                    ),
                    _RoundAction(
                      icon: Icons.person_rounded,
                      label: context.tr('playMine'),
                      colour: _hasMine ? AppColors.grape : Colors.black26,
                      onTap: _hasMine ? _rec.playBack : null,
                    ),
                  ],
                ),
                if (_micFailed)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      context.tr('micUnavailable'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.inkSoft),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  context.tr('speakingNote'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.inkSoft),
                ),
                const SizedBox(height: 16),
                const SpeedControl(),
                const SizedBox(height: 16),
                FilledButton.icon(
                  key: const ValueKey('repeatNext'),
                  onPressed: _next,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(context.tr('next')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({super.key, required this.icon, required this.label, required this.colour, required this.onTap});
  final IconData icon;
  final String label;
  final Color colour;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Material(
        color: colour,
        shape: const CircleBorder(),
        elevation: 3,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 84, height: 84, child: Icon(icon, color: Colors.white, size: 44)),
        ),
      ),
      const SizedBox(height: 6),
      Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    ],
  );
}
