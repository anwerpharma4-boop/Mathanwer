import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../../app_scope.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../services/audio_service.dart';

/// Result of comparing a child's strokes with the letter shape.
class TraceScore {
  const TraceScore(this.coverage, this.precision);

  /// Fraction of the letter that was traced over.
  final double coverage;

  /// Fraction of the drawn ink that lies on (or near) the letter.
  final double precision;

  bool get passed => coverage >= 0.55 && precision >= 0.55;

  @override
  String toString() =>
      'TraceScore(coverage: ${coverage.toStringAsFixed(2)}, precision: ${precision.toStringAsFixed(2)})';
}

/// Pure scoring on a grid (unit tested).
class TraceGrader {
  TraceGrader(this.mask, this.n);

  /// n*n booleans: true where the letter glyph is.
  final List<bool> mask;
  final int n;

  late final List<bool> _dilated = _dilate(mask, n, 2);

  static List<bool> _dilate(List<bool> m, int n, int r) {
    final out = List<bool>.filled(n * n, false);
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        if (!m[y * n + x]) continue;
        for (var dy = -r; dy <= r; dy++) {
          for (var dx = -r; dx <= r; dx++) {
            final xx = x + dx, yy = y + dy;
            if (xx >= 0 && yy >= 0 && xx < n && yy < n) out[yy * n + xx] = true;
          }
        }
      }
    }
    return out;
  }

  /// [strokes] in unit coordinates (0..1), brush radius in unit coordinates.
  TraceScore grade(List<List<Offset>> strokes, double brush) {
    final ink = List<bool>.filled(n * n, false);
    final r = math.max(1, (brush * n).round());
    void stamp(Offset p) {
      final cx = (p.dx * n).floor(), cy = (p.dy * n).floor();
      for (var dy = -r; dy <= r; dy++) {
        for (var dx = -r; dx <= r; dx++) {
          if (dx * dx + dy * dy > r * r) continue;
          final x = cx + dx, y = cy + dy;
          if (x >= 0 && y >= 0 && x < n && y < n) ink[y * n + x] = true;
        }
      }
    }

    for (final s in strokes) {
      for (var i = 0; i < s.length; i++) {
        stamp(s[i]);
        if (i > 0) {
          final a = s[i - 1], b = s[i];
          final steps = ((b - a).distance * n).ceil();
          for (var k = 1; k < steps; k++) {
            stamp(Offset.lerp(a, b, k / steps)!);
          }
        }
      }
    }
    var glyph = 0, covered = 0, inkCount = 0, inkOnGlyph = 0;
    for (var i = 0; i < n * n; i++) {
      if (mask[i]) {
        glyph++;
        if (ink[i]) covered++;
      }
      if (ink[i]) {
        inkCount++;
        if (_dilated[i]) inkOnGlyph++;
      }
    }
    return TraceScore(glyph == 0 ? 0 : covered / glyph, inkCount == 0 ? 0 : inkOnGlyph / inkCount);
  }
}

/// Lays out the guide glyph inside a square of [side].
TextPainter glyphPainter(String letter, double side) {
  final tp = TextPainter(
    text: TextSpan(
      text: letter,
      style: TextStyle(fontFamily: AppTheme.englishFont, fontSize: side * 0.78, height: 1.0),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  return tp;
}

Offset glyphOffset(TextPainter tp, double side) => Offset((side - tp.width) / 2, (side - tp.height) / 2);

/// Rasterises the glyph to an n*n mask.
Future<List<bool>> glyphMask(String letter, {int n = 64}) async {
  const side = 256.0;
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  final tp = glyphPainter(letter, side);
  tp.paint(canvas, glyphOffset(tp, side));
  final img = await rec.endRecording().toImage(side.toInt(), side.toInt());
  final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
  img.dispose();
  final bytes = data?.buffer.asUint8List() ?? Uint8List(0);
  final mask = List<bool>.filled(n * n, false);
  if (bytes.isEmpty) return mask;
  final cell = side / n;
  for (var y = 0; y < n; y++) {
    for (var x = 0; x < n; x++) {
      final px = ((x + 0.5) * cell).floor();
      final py = ((y + 0.5) * cell).floor();
      final alpha = bytes[(py * side.toInt() + px) * 4 + 3];
      mask[y * n + x] = alpha > 100;
    }
  }
  return mask;
}

/// Finger tracing over a large letter.
class TracingPad extends StatefulWidget {
  const TracingPad({super.key, required this.letter, this.onPassed, this.colour = AppColors.primary});
  final String letter;
  final ValueChanged<TraceScore>? onPassed;
  final Color colour;

  @override
  State<TracingPad> createState() => TracingPadState();
}

class TracingPadState extends State<TracingPad> {
  final List<List<Offset>> _strokes = [];
  TraceGrader? _grader;
  TraceScore? _score;
  double _side = 1;
  static const double brush = 0.06;

  List<List<Offset>> get strokes => _strokes;

  @override
  void initState() {
    super.initState();
    _loadMask();
  }

  @override
  void didUpdateWidget(TracingPad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.letter != widget.letter) {
      _strokes.clear();
      _score = null;
      _grader = null;
      _loadMask();
    }
  }

  Future<void> _loadMask() async {
    final m = await glyphMask(widget.letter);
    if (mounted) setState(() => _grader = TraceGrader(m, 64));
  }

  void clear() => setState(() {
    _strokes.clear();
    _score = null;
  });

  TraceScore? check() {
    final g = _grader;
    if (g == null) return null;
    final unit = [for (final s in _strokes) s.map((p) => Offset(p.dx / _side, p.dy / _side)).toList()];
    final score = g.grade(unit, brush);
    setState(() => _score = score);
    final audio = AppScope.read(context).audio;
    if (score.passed) {
      audio.sfx(Sfx.star);
      widget.onPassed?.call(score);
    } else {
      audio.say('Try again.');
    }
    return score;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        _side = math.min(c.maxWidth, c.maxHeight.isFinite ? c.maxHeight - 64 : c.maxWidth).clamp(160.0, 520.0);
        final passed = _score?.passed ?? false;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _side,
              height: _side,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: passed ? AppColors.success : widget.colour.withValues(alpha: 0.3), width: 4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: GestureDetector(
                  key: const ValueKey('tracingSurface'),
                  onPanStart: (d) => setState(() => _strokes.add([d.localPosition])),
                  onPanUpdate: (d) => setState(() => _strokes.last.add(d.localPosition)),
                  onPanEnd: (_) {
                    final g = _grader;
                    if (g == null) return;
                    final unit = [for (final s in _strokes) s.map((p) => Offset(p.dx / _side, p.dy / _side)).toList()];
                    // Auto-check once most of the letter is covered.
                    if (g.grade(unit, brush).coverage >= 0.7) check();
                  },
                  child: CustomPaint(
                    size: Size(_side, _side),
                    painter: _TracePainter(widget.letter, _strokes, widget.colour, passed),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  key: const ValueKey('traceClear'),
                  onPressed: clear,
                  icon: const Icon(Icons.cleaning_services_rounded),
                  label: Text(context.tr('clear')),
                ),
                FilledButton.icon(
                  key: const ValueKey('traceCheck'),
                  onPressed: check,
                  icon: Icon(passed ? Icons.star_rounded : Icons.check_rounded),
                  label: Text(passed ? context.tr('great') : context.tr('done')),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _TracePainter extends CustomPainter {
  _TracePainter(this.letter, this.strokes, this.colour, this.passed);
  final String letter;
  final List<List<Offset>> strokes;
  final Color colour;
  final bool passed;

  @override
  void paint(Canvas canvas, Size size) {
    // Writing lines like the textbook tracing rows.
    final line = Paint()
      ..color = const Color(0xFF9BD3F0)
      ..strokeWidth = 2;
    for (final f in [0.2, 0.42, 0.72, 0.9]) {
      canvas.drawLine(Offset(0, size.height * f), Offset(size.width, size.height * f), line);
    }
    final tp = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          fontFamily: AppTheme.englishFont,
          fontSize: size.width * 0.78,
          height: 1.0,
          color: passed ? AppColors.success.withValues(alpha: 0.35) : colour.withValues(alpha: 0.18),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2));
    final ink = Paint()
      ..color = passed ? AppColors.success : colour
      ..strokeWidth = size.width * 0.06 * 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final s in strokes) {
      if (s.length == 1) {
        canvas.drawCircle(s.first, ink.strokeWidth / 2, Paint()..color = ink.color);
        continue;
      }
      final path = Path()..moveTo(s.first.dx, s.first.dy);
      for (final p in s.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, ink);
    }
  }

  @override
  bool shouldRepaint(_TracePainter old) => true;
}
