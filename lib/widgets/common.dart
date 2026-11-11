import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../app_scope.dart';
import '../content/models.dart';
import '../core/l10n.dart';
import '../core/theme.dart';
import '../services/audio_service.dart';

/// Scaffold with the app background, a large back button and a title.
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    required this.body,
    this.colour = AppColors.primary,
    this.actions = const [],
    this.floatingActionButton,
  });

  final String title;
  final Widget body;
  final Color colour;
  final List<Widget> actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: floatingActionButton,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.lerp(colour, Colors.white, 0.82)!, AppColors.background],
            stops: const [0, 0.35],
          ),
        ),
        // Transparent Material so list tiles / ink splashes paint above the
        // gradient background.
        child: Material(
          type: MaterialType.transparency,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
                  child: Row(
                    children: [
                      if (Navigator.of(context).canPop())
                        Tooltip(
                          message: context.tr('back'),
                          child: Material(
                            color: Colors.white,
                            shape: const CircleBorder(),
                            elevation: 1,
                            child: IconButton(
                              icon: const BackButtonIcon(),
                              color: colour,
                              onPressed: () => Navigator.of(context).maybePop(),
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color.lerp(colour, AppColors.ink, 0.45),
                          ),
                        ),
                      ),
                      ...actions,
                    ],
                  ),
                ),
                Expanded(child: body),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded, coloured tile used on menus.
class BigTile extends StatelessWidget {
  const BigTile({
    super.key,
    required this.title,
    required this.icon,
    required this.colour,
    required this.onTap,
    this.subtitle,
    this.badge,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color colour;
  final VoidCallback onTap;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: colour,
        borderRadius: BorderRadius.circular(28),
        elevation: 2,
        shadowColor: colour.withValues(alpha: 0.5),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () {
            AppScope.read(context).audio.sfx(Sfx.tap);
            onTap();
          },
          child: Stack(
            children: [
              Positioned(
                right: -18,
                bottom: -18,
                child: Icon(icon, size: 96, color: Colors.white.withValues(alpha: 0.18)),
              ),
              LayoutBuilder(
                builder: (context, c) {
                  final compact = c.maxHeight < 140;
                  return Padding(
                    padding: EdgeInsets.all(compact ? 10 : 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(compact ? 6 : 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(icon, color: Colors.white, size: compact ? 24 : 30),
                        ),
                        const Spacer(),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              if (badge != null) Positioned(top: 10, right: 10, child: badge!),
            ],
          ),
        ),
      ),
    );
  }
}

/// Round speaker button that plays British English audio for [text].
class SpeakButton extends StatefulWidget {
  const SpeakButton({
    super.key,
    required this.text,
    this.size = 52,
    this.colour = AppColors.primary,
    this.letterName,
    this.letterSound,
  });

  final String text;
  final double size;
  final Color colour;
  final String? letterName;
  final String? letterSound;

  @override
  State<SpeakButton> createState() => _SpeakButtonState();
}

class _SpeakButtonState extends State<SpeakButton> {
  bool _playing = false;

  Future<void> _play() async {
    final audio = AppScope.read(context).audio;
    setState(() => _playing = true);
    var ok = true;
    if (widget.letterName != null) {
      await audio.letterName(widget.letterName!);
    } else if (widget.letterSound != null) {
      await audio.letterSound(widget.letterSound!);
    } else {
      ok = await audio.say(widget.text);
    }
    if (!mounted) return;
    setState(() => _playing = false);
    if (!ok) {
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(const SnackBar(content: Text('British English audio is not available for this text.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Listen: ${widget.text}',
      child: Material(
        color: _playing ? AppColors.sunshine : widget.colour,
        shape: const CircleBorder(),
        elevation: 2,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _play,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Icon(
              _playing ? Icons.graphic_eq : Icons.volume_up_rounded,
              color: _playing ? AppColors.ink : Colors.white,
              size: widget.size * 0.55,
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows the original textbook picture for a word, a paint swatch for a
/// colour, or counting dots for a number.
class WordPicture extends StatelessWidget {
  const WordPicture({super.key, required this.word, this.size = 120, this.showLabel = false});

  final VocabWord word;
  final double size;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    Widget pic;
    if (word.image != null) {
      pic = Image.asset(
        word.image!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        semanticLabel: word.text,
        errorBuilder: (_, _, _) => _textCard(),
      );
    } else if (word.colour != null) {
      pic = SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: PaintSplatPainter(Color(word.colour!))),
      );
    } else if (word.count != null) {
      pic = SizedBox(
        width: size,
        height: size,
        child: CountDots(count: word.count!),
      );
    } else {
      pic = _textCard();
    }
    if (!showLabel) return pic;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        pic,
        const SizedBox(height: 6),
        EnglishContent(child: Text(word.text, style: learningText(size * 0.2))),
      ],
    );
  }

  Widget _textCard() => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: const Color(0xFFFFF1D6), borderRadius: BorderRadius.circular(size * 0.18)),
    child: EnglishContent(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: FittedBox(
          child: Text(word.text, style: learningText(size * 0.24, color: AppColors.orange)),
        ),
      ),
    ),
  );
}

/// A paint splat (like the colour splats used in the book's colour lessons).
class PaintSplatPainter extends CustomPainter {
  PaintSplatPainter(this.colour);
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide * 0.32;
    final path = Path();
    const n = 9;
    for (var i = 0; i <= n * 2; i++) {
      final a = i * math.pi / n;
      final rr = i.isEven ? r * 1.25 : r * 0.82;
      final p = c + Offset(math.cos(a), math.sin(a)) * rr;
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        final prevA = (i - 0.5) * math.pi / n;
        final ctrl = c + Offset(math.cos(prevA), math.sin(prevA)) * r * 1.1;
        path.quadraticBezierTo(ctrl.dx, ctrl.dy, p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = colour);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.black.withValues(alpha: colour.computeLuminance() > 0.8 ? 0.35 : 0.12),
    );
    canvas.drawCircle(
      c + Offset(-r * 0.35, -r * 0.35),
      r * 0.14,
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(PaintSplatPainter old) => old.colour != colour;
}

/// Dots arranged like dice for counting.
class CountDots extends StatelessWidget {
  const CountDots({super.key, required this.count, this.colour = AppColors.coral});
  final int count;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = count <= 3 ? count : (count <= 6 ? 3 : 5);
        final rows = (count / cols).ceil();
        final d = math.min(c.maxWidth / (cols + 0.6), c.maxHeight / (rows + 0.6)) * 0.8;
        return Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: d * 0.2,
            runSpacing: d * 0.2,
            children: List.generate(
              count,
              (_) => Container(
                width: d,
                height: d,
                decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
              ),
            ),
          ),
        );
      },
    );
  }
}

class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.stars, this.max = 3, this.size = 28});
  final int stars;
  final int max;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(
      max,
      (i) => Icon(
        i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
        size: size,
        color: i < stars ? AppColors.sunshine : Colors.black26,
      ),
    ),
  );
}

/// Adaptive grid column count for phones and tablets.
int gridColumns(double width, {double minTile = 160}) => math.max(2, (width / minTile).floor());

/// Small rounded label.
class Pill extends StatelessWidget {
  const Pill({super.key, required this.text, this.colour = AppColors.primary, this.icon});
  final String text;
  final Color colour;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: colour.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(30)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 16, color: colour), const SizedBox(width: 4)],
        Text(
          text,
          style: TextStyle(color: Color.lerp(colour, Colors.black, 0.3), fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ],
    ),
  );
}

/// White rounded panel.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.colour = Colors.white});
  final Widget child;
  final EdgeInsets padding;
  final Color colour;

  @override
  Widget build(BuildContext context) => Material(
    color: colour,
    elevation: 1.5,
    shadowColor: Colors.black26,
    borderRadius: BorderRadius.circular(24),
    child: Padding(padding: padding, child: child),
  );
}

IconData iconByName(String name) {
  const map = {
    'school': Icons.school_rounded,
    'menu_book': Icons.menu_book_rounded,
    'auto_stories': Icons.auto_stories_rounded,
    'sports_esports': Icons.sports_esports_rounded,
    'emoji_events': Icons.emoji_events_rounded,
    'star': Icons.star_rounded,
    'military_tech': Icons.military_tech_rounded,
    'abc': Icons.abc_rounded,
    'gesture': Icons.gesture_rounded,
    'headphones': Icons.headphones_rounded,
    'palette': Icons.palette_rounded,
    'flag': Icons.flag_rounded,
    'looks_one': Icons.looks_one_rounded,
    'looks_two': Icons.looks_two_rounded,
    'looks_3': Icons.looks_3_rounded,
    'looks_4': Icons.looks_4_rounded,
    'looks_5': Icons.looks_5_rounded,
    'looks_6': Icons.looks_6_rounded,
    'filter_7': Icons.filter_7_rounded,
    'filter_8': Icons.filter_8_rounded,
  };
  return map[name] ?? Icons.star_rounded;
}
