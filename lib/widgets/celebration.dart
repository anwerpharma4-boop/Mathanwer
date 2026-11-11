import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../app_scope.dart';
import '../content/app_phrases.dart';
import '../core/l10n.dart';
import '../core/theme.dart';
import '../data/progress_store.dart';
import '../services/audio_service.dart';
import 'common.dart';
import 'mascot.dart';

/// Records a result and shows an encouraging celebration.
/// Returns true if the child wants to play again.
Future<bool> finishActivity(
  BuildContext context, {
  required String kind,
  required String ref,
  int? unitId,
  required int score,
  required int total,
}) async {
  final services = AppScope.read(context);
  final result = await services.progress.recordResult(kind: kind, ref: ref, unitId: unitId, score: score, total: total);
  final badges = services.progress.takeNewBadges();
  if (!context.mounted) return false;
  final again = await showCelebration(context, stars: result.stars, score: score, total: total, badges: badges);
  return again;
}

Future<bool> showCelebration(
  BuildContext context, {
  required int stars,
  int? score,
  int? total,
  List<BadgeDef> badges = const [],
  bool canRetry = true,
}) async {
  final audio = AppScope.read(context).audio;
  audio.sfx(Sfx.complete);
  final phrase = praisePhrases[math.Random().nextInt(praisePhrases.length)];
  Future.delayed(const Duration(milliseconds: 700), () => audio.say(phrase));
  final res = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black45,
    transitionDuration: const Duration(milliseconds: 350),
    transitionBuilder: (context, a, _, child) => ScaleTransition(
      scale: CurvedAnimation(parent: a, curve: Curves.elasticOut),
      child: child,
    ),
    pageBuilder: (context, _, _) => _CelebrationCard(
      stars: stars,
      score: score,
      total: total,
      badges: badges,
      phrase: phrase,
      canRetry: canRetry,
    ),
  );
  return res ?? false;
}

class _CelebrationCard extends StatelessWidget {
  const _CelebrationCard({
    required this.stars,
    required this.score,
    required this.total,
    required this.badges,
    required this.phrase,
    required this.canRetry,
  });

  final int stars;
  final int? score;
  final int? total;
  final List<BadgeDef> badges;
  final String phrase;
  final bool canRetry;

  @override
  Widget build(BuildContext context) {
    final arabic = context.l10n.isArabic;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Material(
          color: Colors.transparent,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              const Positioned.fill(child: IgnorePointer(child: Confetti())),
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32)),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Mascot(size: 96, mood: MascotMood.cheer),
                      EnglishContent(child: Text(phrase, style: learningText(30, color: AppColors.grass))),
                      const SizedBox(height: 8),
                      StarRow(stars: stars, size: 52),
                      if (score != null && total != null) ...[
                        const SizedBox(height: 6),
                        Text('$score / $total ${context.tr('correct')}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
                      ],
                      for (final b in badges)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Pill(
                            text: '${context.tr('badges')}: ${arabic ? b.titleAr : b.title}',
                            colour: AppColors.grape,
                            icon: iconByName(b.icon),
                          ),
                        ),
                      const SizedBox(height: 18),
                      Row(children: [
                        if (canRetry)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).pop(true),
                              icon: const Icon(Icons.replay_rounded),
                              label: Text(context.tr('retry')),
                            ),
                          ),
                        if (canRetry) const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => Navigator.of(context).pop(false),
                            icon: const Icon(Icons.check_rounded),
                            label: Text(context.tr('done')),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lightweight confetti animation.
class Confetti extends StatefulWidget {
  const Confetti({super.key});

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 3))..forward();
  final _rnd = math.Random();
  late final List<_Bit> _bits = List.generate(
      40,
      (_) => _Bit(_rnd.nextDouble(), _rnd.nextDouble() * 0.4, 0.5 + _rnd.nextDouble(),
          AppColors.tiles[_rnd.nextInt(AppColors.tiles.length)], _rnd.nextDouble() * math.pi));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(painter: _ConfettiPainter(_bits, _c.value)),
      );
}

class _Bit {
  _Bit(this.x, this.delay, this.speed, this.colour, this.rot);
  final double x, delay, speed, rot;
  final Color colour;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.bits, this.t);
  final List<_Bit> bits;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in bits) {
      final p = ((t - b.delay) * b.speed).clamp(0.0, 1.0);
      if (p <= 0 || p >= 1) continue;
      final y = p * size.height;
      final x = b.x * size.width + math.sin(p * 10 + b.rot) * 14;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(b.rot + p * 8);
      canvas.drawRect(const Rect.fromLTWH(-5, -3, 10, 6), Paint()..color = b.colour.withValues(alpha: 1 - p * 0.5));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

/// Shakes its child horizontally when [trigger] changes (gentle "try again").
class Shake extends StatefulWidget {
  const Shake({super.key, required this.trigger, required this.child});
  final int trigger;
  final Widget child;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void didUpdateWidget(Shake old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, child) => Transform.translate(
          offset: Offset(math.sin(_c.value * math.pi * 5) * 10 * (1 - _c.value), 0),
          child: child,
        ),
        child: widget.child,
      );
}
