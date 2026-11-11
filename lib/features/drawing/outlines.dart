import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Simple colouring-page outlines (original line art, drawn in code) of
/// objects from the textbook: the ball of the Unit 1 project, an apple, a
/// fish, a flower, a kite, a house, a balloon and the sun.
class ColouringPage {
  const ColouringPage(this.id, this.word, this.build);
  final String id;
  final String word;

  /// Builds the outline path inside a square of side 1.
  final Path Function() build;
}

Path _ball() {
  final p = Path()..addOval(Rect.fromCircle(center: const Offset(.5, .5), radius: .38));
  // Stripes like the balls in the "Draw and colour a ball" project.
  for (final dy in [-.18, 0.0, .18]) {
    p.moveTo(.14, .5 + dy);
    p.quadraticBezierTo(.5, .5 + dy - .12, .86, .5 + dy);
  }
  return p;
}

Path _apple() {
  final p = Path()
    ..moveTo(.5, .3)
    ..cubicTo(.35, .18, .12, .26, .14, .5)
    ..cubicTo(.16, .78, .36, .9, .5, .82)
    ..cubicTo(.64, .9, .84, .78, .86, .5)
    ..cubicTo(.88, .26, .65, .18, .5, .3)
    ..moveTo(.5, .3)
    ..quadraticBezierTo(.49, .2, .55, .1)
    ..moveTo(.53, .2)
    ..cubicTo(.6, .1, .78, .1, .82, .16)
    ..cubicTo(.72, .26, .6, .26, .53, .2);
  return p;
}

Path _fish() {
  final p = Path()
    ..moveTo(.12, .5)
    ..cubicTo(.25, .25, .6, .22, .72, .5)
    ..cubicTo(.6, .78, .25, .75, .12, .5)
    ..moveTo(.72, .5)
    ..lineTo(.9, .32)
    ..lineTo(.88, .68)
    ..close()
    ..addOval(Rect.fromCircle(center: const Offset(.27, .46), radius: .035))
    ..moveTo(.42, .3)
    ..quadraticBezierTo(.5, .2, .58, .32);
  return p;
}

Path _flower() {
  final p = Path();
  for (var i = 0; i < 6; i++) {
    final a = i * math.pi / 3;
    final c = Offset(.5 + math.cos(a) * .17, .36 + math.sin(a) * .17);
    p.addOval(Rect.fromCircle(center: c, radius: .11));
  }
  p.addOval(Rect.fromCircle(center: const Offset(.5, .36), radius: .09));
  p.moveTo(.5, .53);
  p.lineTo(.5, .92);
  p.moveTo(.5, .75);
  p.cubicTo(.4, .62, .26, .66, .24, .72);
  p.cubicTo(.32, .8, .44, .8, .5, .75);
  p.moveTo(.5, .8);
  p.cubicTo(.6, .68, .74, .72, .76, .78);
  p.cubicTo(.68, .86, .56, .86, .5, .8);
  return p;
}

Path _kite() {
  final p = Path()
    ..moveTo(.5, .08)
    ..lineTo(.8, .38)
    ..lineTo(.5, .74)
    ..lineTo(.2, .38)
    ..close()
    ..moveTo(.5, .08)
    ..lineTo(.5, .74)
    ..moveTo(.2, .38)
    ..lineTo(.8, .38)
    ..moveTo(.5, .74)
    ..cubicTo(.45, .82, .58, .86, .5, .94);
  for (final y in [.82, .9]) {
    p.moveTo(.44, y);
    p.lineTo(.56, y + .04);
    p.lineTo(.56, y - .04);
    p.lineTo(.44, y);
  }
  return p;
}

Path _house() {
  final p = Path()
    ..addRect(const Rect.fromLTWH(.2, .45, .6, .45))
    ..moveTo(.12, .47)
    ..lineTo(.5, .14)
    ..lineTo(.88, .47)
    ..close()
    ..addRect(const Rect.fromLTWH(.43, .64, .14, .26))
    ..addRect(const Rect.fromLTWH(.26, .54, .12, .12))
    ..addRect(const Rect.fromLTWH(.62, .54, .12, .12))
    ..addRect(const Rect.fromLTWH(.64, .18, .08, .14));
  return p;
}

Path _balloon() {
  final p = Path()
    ..addOval(const Rect.fromLTWH(.28, .08, .44, .54))
    ..moveTo(.47, .62)
    ..lineTo(.5, .66)
    ..lineTo(.53, .62)
    ..moveTo(.5, .66)
    ..cubicTo(.42, .74, .58, .82, .5, .94);
  return p;
}

Path _sun() {
  final p = Path()..addOval(Rect.fromCircle(center: const Offset(.5, .5), radius: .2));
  for (var i = 0; i < 10; i++) {
    final a = i * math.pi / 5;
    p.moveTo(.5 + math.cos(a) * .27, .5 + math.sin(a) * .27);
    p.lineTo(.5 + math.cos(a) * .42, .5 + math.sin(a) * .42);
  }
  p.addOval(Rect.fromCircle(center: const Offset(.43, .46), radius: .025));
  p.addOval(Rect.fromCircle(center: const Offset(.57, .46), radius: .025));
  p.moveTo(.42, .56);
  p.quadraticBezierTo(.5, .63, .58, .56);
  return p;
}

final List<ColouringPage> colouringPages = [
  ColouringPage('ball', 'ball', _ball),
  ColouringPage('apple', 'apple', _apple),
  ColouringPage('fish', 'fish', _fish),
  ColouringPage('flower', 'flower', _flower),
  ColouringPage('kite', 'kite', _kite),
  ColouringPage('house', 'house', _house),
  ColouringPage('balloon', 'balloon', _balloon),
  ColouringPage('sun', 'sun', _sun),
];

/// Draws an outline (unit-square path) scaled to [size].
void paintOutline(Canvas canvas, Size size, Path unitPath) {
  final m = Matrix4.diagonal3Values(size.width, size.height, 1);
  final path = unitPath.transform(m.storage);
  canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(3, size.shortestSide * 0.012)
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF26324A));
}
