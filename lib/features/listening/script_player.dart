import 'package:material_ui/material_ui.dart';

import '../../app_scope.dart';
import '../../content/models.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../services/audio_service.dart';
import '../../widgets/celebration.dart';
import '../../widgets/common.dart';
import '../../widgets/mascot.dart';
import 'speed_control.dart';

const Map<String, Color> _speakerColours = {
  'Robbie': Color(0xFFF29D0A),
  'Rosie': Color(0xFFFF6B5E),
  'Ahmed': Color(0xFF3D7BF7),
  'Nada': Color(0xFFD6479B),
  'Hani': Color(0xFF2EAD5B),
  'Iman': Color(0xFF8E5CC9),
  'Teacher': Color(0xFF15A6B8),
};

Color speakerColour(String s) => _speakerColours[s] ?? const Color(0xFF6C7A93);

String scriptKindLabel(ScriptKind k) => switch (k) {
      ScriptKind.conversation => 'Conversation',
      ScriptKind.song => 'Song',
      ScriptKind.chant => 'Chant',
      ScriptKind.story => 'Story',
      ScriptKind.phrases => 'Listen and say',
    };

IconData scriptKindIcon(ScriptKind k) => switch (k) {
      ScriptKind.conversation => Icons.forum_rounded,
      ScriptKind.song => Icons.music_note_rounded,
      ScriptKind.chant => Icons.music_note_rounded,
      ScriptKind.story => Icons.auto_stories_rounded,
      ScriptKind.phrases => Icons.record_voice_over_rounded,
    };

/// Plays a dialogue / song / story from the textbook transcripts line by
/// line in British English, with "listen and say" pauses for repetition.
class ScriptPlayerScreen extends StatefulWidget {
  const ScriptPlayerScreen({super.key, required this.script, this.bookPage, this.colour = AppColors.teal});
  final Script script;
  final int? bookPage;
  final Color colour;

  @override
  State<ScriptPlayerScreen> createState() => _ScriptPlayerScreenState();
}

class _ScriptPlayerScreenState extends State<ScriptPlayerScreen> {
  int? _current;
  bool _playingAll = false;
  bool _repeatMode = false;
  int _run = 0;
  final Set<int> _heard = {};
  bool _recorded = false;

  Future<void> _playLine(int i) async {
    final audio = AppScope.read(context).audio;
    setState(() => _current = i);
    await audio.say(widget.script.lines[i].text);
    _heard.add(i);
  }

  Future<void> _playAll() async {
    final run = ++_run;
    setState(() => _playingAll = true);
    for (var i = 0; i < widget.script.lines.length; i++) {
      if (!mounted || run != _run) return;
      await _playLine(i);
      if (!mounted || run != _run) return;
      // Listen and say: leave time for the child to repeat the line.
      final words = widget.script.lines[i].text.split(' ').length;
      await Future<void>.delayed(Duration(milliseconds: _repeatMode ? 1200 + words * 450 : 350));
    }
    if (!mounted || run != _run) return;
    setState(() {
      _playingAll = false;
      _current = null;
    });
    if (!_recorded && _heard.length == widget.script.lines.length) {
      _recorded = true;
      await finishActivity(context, kind: 'listen', ref: widget.script.title, score: 1, total: 1);
    }
  }

  void _stop() {
    _run++;
    AppScope.read(context).audio.stop();
    setState(() {
      _playingAll = false;
      _current = null;
    });
  }

  late AudioOut _audio;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audio = AppScope.read(context).audio;
  }

  @override
  void dispose() {
    _run++;
    _audio.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.script;
    final isSong = s.kind == ScriptKind.song || s.kind == ScriptKind.chant;
    return AppPage(
      title: s.title,
      colour: widget.colour,
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(spacing: 8, runSpacing: 6, alignment: WrapAlignment.center, children: [
            Pill(text: scriptKindLabel(s.kind), icon: scriptKindIcon(s.kind), colour: widget.colour),
            if (s.track != null) Pill(text: 'Book track ${s.track}', icon: Icons.headphones_rounded, colour: AppColors.grass),
            if (widget.bookPage != null)
              Pill(text: '${context.tr('page')} ${widget.bookPage}', icon: Icons.menu_book_rounded, colour: AppColors.primary),
          ]),
        ),
        if (s.instruction != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: EnglishContent(
                child: Text(s.instruction!, textAlign: TextAlign.center, style: learningText(17, color: AppColors.inkSoft))),
          ),
        if (isSong)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Text(
              'Words of the song from the book, read aloud in British English. The original song recording is not included.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
            ),
          ),
        Expanded(
          child: EnglishContent(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: s.lines.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _LineBubble(
                key: ValueKey('line_$i'),
                line: s.lines[i],
                active: _current == i,
                story: s.kind == ScriptKind.story,
                onTap: () {
                  _run++;
                  _playLine(i);
                },
              ),
            ),
          ),
        ),
        Material(
          color: Colors.white,
          elevation: 3,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    key: const ValueKey('playAll'),
                    onPressed: _playingAll ? _stop : _playAll,
                    icon: Icon(_playingAll ? Icons.stop_rounded : Icons.play_arrow_rounded),
                    label: Text(_playingAll ? context.tr('stop') : context.tr('playAll')),
                  ),
                  FilterChip(
                    key: const ValueKey('repeatMode'),
                    selected: _repeatMode,
                    onSelected: (v) => setState(() => _repeatMode = v),
                    avatar: const Icon(Icons.record_voice_over_rounded, size: 18),
                    label: Text(context.tr('listenAndSay')),
                  ),
                  const SpeedControl(),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _LineBubble extends StatelessWidget {
  const _LineBubble({super.key, required this.line, required this.active, required this.onTap, required this.story});
  final ScriptLine line;
  final bool active;
  final bool story;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colour = line.speaker.isEmpty ? AppColors.teal : speakerColour(line.speaker);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: active ? colour.withValues(alpha: 0.16) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: active ? colour : Colors.transparent, width: 3),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (line.speaker.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: colour, borderRadius: BorderRadius.circular(14)),
                child: Text(line.speaker, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            Expanded(
              child: Text(line.text, style: learningText(story ? 19 : 24, weight: story ? FontWeight.w500 : FontWeight.w700)),
            ),
            Icon(active ? Icons.graphic_eq_rounded : Icons.volume_up_rounded, color: colour),
          ]),
        ),
      ),
    );
  }
}

/// Small helper used by lesson screens.
class MascotSays extends StatelessWidget {
  const MascotSays({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Row(children: [
        const Mascot(size: 64),
        const SizedBox(width: 8),
        Expanded(
          child: Panel(
            padding: const EdgeInsets.all(12),
            child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ]);
}
