import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// "Bolt", the app's own friendly robot mascot (original artwork drawn in
/// code; it is not the textbook's Robbie character).
class Mascot extends StatefulWidget {
  const Mascot({super.key, this.size = 120, this.mood = MascotMood.happy, this.animate = true});

  final double size;
  final MascotMood mood;
  final bool animate;

  @override
  State<Mascot> createState() => _MascotState();
}

enum MascotMood { happy, cheer, think }

class _MascotState extends State<Mascot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect the system "remove animations" accessibility setting.
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.animate && !reduce) {
      if (!_c.isAnimating) _c.repeat(reverse: true);
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Robot mascot',
      image: true,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          size: Size(widget.size, widget.size * 1.15),
          painter: _RobotPainter(t: Curves.easeInOut.transform(_c.value), mood: widget.mood),
        ),
      ),
    );
  }
}

class _RobotPainter extends CustomPainter {
  _RobotPainter({required this.t, required this.mood});

  final double t;
  final MascotMood mood;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bob = math.sin(t * math.pi) * h * 0.02;
    canvas.translate(0, -bob);

    final body = Paint()..color = const Color(0xFF39B6E8);
    final bodyDark = Paint()..color = const Color(0xFF1F8FC0);
    final face = Paint()..color = const Color(0xFFEAF8FF);
    final accent = Paint()..color = const Color(0xFFFFC93C);
    final ink = Paint()..color = const Color(0xFF26324A);
    final cheek = Paint()..color = const Color(0xFFFF9AA2);

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.97 + bob), width: w * 0.55, height: h * 0.05),
      Paint()..color = Colors.black.withValues(alpha: 0.08),
    );

    // Antenna
    final antennaTop = Offset(w * 0.5, h * 0.06);
    canvas.drawLine(
      Offset(w * 0.5, h * 0.18),
      antennaTop,
      Paint()
        ..color = bodyDark.color
        ..strokeWidth = w * 0.03
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(antennaTop, w * 0.045 + t * w * 0.01, accent);

    // Arms (one waving)
    final armPaint = Paint()
      ..color = bodyDark.color
      ..strokeWidth = w * 0.07
      ..strokeCap = StrokeCap.round;
    final wave = mood == MascotMood.cheer ? 0.9 : 0.5;
    final angle = -math.pi / 3 - t * wave;
    final shoulderR = Offset(w * 0.8, h * 0.62);
    final handR = shoulderR + Offset(math.cos(angle), math.sin(angle)) * w * 0.22;
    canvas.drawLine(shoulderR, handR, armPaint);
    canvas.drawCircle(handR, w * 0.06, accent);
    final shoulderL = Offset(w * 0.2, h * 0.62);
    final leftAngle = mood == MascotMood.cheer ? -math.pi * 2 / 3 + t * 0.5 : math.pi * 0.62;
    final handL = shoulderL + Offset(math.cos(leftAngle), math.sin(leftAngle)) * w * 0.2;
    canvas.drawLine(shoulderL, handL, armPaint);
    canvas.drawCircle(handL, w * 0.06, accent);

    // Legs
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.33, h * 0.82, w * 0.12, h * 0.12), Radius.circular(w * 0.04)),
      bodyDark,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.55, h * 0.82, w * 0.12, h * 0.12), Radius.circular(w * 0.04)),
      bodyDark,
    );

    // Body
    final bodyRect = Rect.fromLTWH(w * 0.22, h * 0.52, w * 0.56, h * 0.34);
    canvas.drawRRect(RRect.fromRectAndRadius(bodyRect, Radius.circular(w * 0.12)), body);
    // Heart panel with colour squares
    final colours = [
      const Color(0xFFFF6B5E),
      const Color(0xFF2EAD5B),
      const Color(0xFFFFC93C),
      const Color(0xFF8E5CC9),
    ];
    for (var i = 0; i < 4; i++) {
      final dx = (i % 2) * w * 0.11;
      final dy = (i ~/ 2) * w * 0.11;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.39 + dx, h * 0.6 + dy, w * 0.095, w * 0.095),
          Radius.circular(w * 0.02),
        ),
        Paint()..color = colours[i],
      );
    }

    // Head
    final headRect = Rect.fromLTWH(w * 0.14, h * 0.16, w * 0.72, h * 0.38);
    canvas.drawRRect(RRect.fromRectAndRadius(headRect, Radius.circular(w * 0.18)), body);
    canvas.drawRRect(RRect.fromRectAndRadius(headRect.deflate(w * 0.06), Radius.circular(w * 0.13)), face);
    // Ears
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.06, h * 0.28, w * 0.1, h * 0.14), Radius.circular(w * 0.04)),
      accent,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.84, h * 0.28, w * 0.1, h * 0.14), Radius.circular(w * 0.04)),
      accent,
    );

    // Eyes (blink near the end of the cycle)
    final blink = t > 0.92 ? 0.15 : 1.0;
    for (final x in [0.37, 0.63]) {
      canvas.drawOval(Rect.fromCenter(center: Offset(w * x, h * 0.32), width: w * 0.12, height: w * 0.14 * blink), ink);
      if (blink > 0.5) canvas.drawCircle(Offset(w * x + w * 0.02, h * 0.31), w * 0.022, Paint()..color = Colors.white);
    }
    canvas.drawCircle(Offset(w * 0.27, h * 0.41), w * 0.04, cheek);
    canvas.drawCircle(Offset(w * 0.73, h * 0.41), w * 0.04, cheek);

    // Mouth
    final mouth = Path();
    if (mood == MascotMood.think) {
      mouth.addOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.43), width: w * 0.08, height: w * 0.06));
      canvas.drawPath(mouth, ink);
    } else {
      final open = mood == MascotMood.cheer ? 0.09 : 0.06;
      mouth.moveTo(w * 0.38, h * 0.41);
      mouth.quadraticBezierTo(w * 0.5, h * (0.41 + open + t * 0.01), w * 0.62, h * 0.41);
      mouth.close();
      canvas.drawPath(mouth, ink);
    }
  }

  @override
  bool shouldRepaint(_RobotPainter old) => old.t != t || old.mood != mood;
}
