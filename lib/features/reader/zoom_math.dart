import 'dart:math' as math;
import 'dart:ui';

import 'package:vector_math/vector_math_64.dart' show Matrix4, Vector3;

/// Pure geometry helpers for the textbook reader (unit tested).
class ZoomMath {
  /// Highest zoom offered. Beyond ~12x a phone screen shows only a few
  /// letters of the 300 dpi page, so this is a practical, not artificial, cap.
  static const double maxScale = 12.0;
  static const double minScale = 1.0;
  static const double doubleTapScale = 2.5;

  /// Rectangle of a page of [aspect] (height/width) fitted inside [box]
  /// (fit page), with [pad] pixels around it.
  static Rect fitPage(Size box, double aspect, {double pad = 8}) {
    final availW = math.max(1.0, box.width - pad * 2);
    final availH = math.max(1.0, box.height - pad * 2);
    var w = availW;
    var h = w * aspect;
    if (h > availH) {
      h = availH;
      w = h / aspect;
    }
    return Rect.fromLTWH((box.width - w) / 2, (box.height - h) / 2, w, h);
  }

  static double scaleOf(Matrix4 m) => m.getMaxScaleOnAxis();

  static Offset translationOf(Matrix4 m) {
    final t = m.getTranslation();
    return Offset(t.x, t.y);
  }

  static Matrix4 make(double scale, Offset translation) => Matrix4.identity()
    ..setTranslation(Vector3(translation.dx, translation.dy, 0))
    ..setEntry(0, 0, scale)
    ..setEntry(1, 1, scale)
    ..setEntry(2, 2, 1);

  /// Keeps the scaled [content] covering the [viewport] (no empty space can be
  /// dragged into view beyond the content edges). If the content is smaller
  /// than the viewport along an axis it is centred on that axis.
  static Matrix4 clamp(Matrix4 m, Size viewport, Size content) {
    final s = scaleOf(m).clamp(minScale, maxScale);
    final t = translationOf(m);
    double axis(double v, double view, double cont) {
      final scaled = cont * s;
      if (scaled <= view) return (view - scaled) / 2;
      return v.clamp(view - scaled, 0.0);
    }

    return make(s, Offset(axis(t.dx, viewport.width, content.width), axis(t.dy, viewport.height, content.height)));
  }

  /// Zoom to [targetScale] keeping the point under [focal] (viewport
  /// coordinates) fixed.
  static Matrix4 zoomAt(Matrix4 current, Offset focal, double targetScale, Size viewport, Size content) {
    final s0 = scaleOf(current);
    final t0 = translationOf(current);
    final s1 = targetScale.clamp(minScale, maxScale);
    // Content point under the finger.
    final cp = (focal - t0) / s0;
    final t1 = focal - cp * s1;
    return clamp(make(s1, t1), viewport, content);
  }

  /// Scale and translation that make [page] (content coordinates) as wide as
  /// the viewport, showing the top of the page.
  static Matrix4 fitWidth(Size viewport, Size content, Rect page) {
    final s = (viewport.width / page.width).clamp(minScale, maxScale);
    final t = Offset(-page.left * s, -page.top * s);
    return clamp(make(s, t), viewport, content);
  }

  /// Show [page] (content coordinates) entirely, at scale 1 by design of the
  /// layouts, aligned to its top.
  static Matrix4 showPage(Size viewport, Size content, Rect page, {double scale = 1}) {
    final t = Offset(
      -page.left * scale + (viewport.width - page.width * scale) / 2,
      -page.top * scale + (viewport.height - page.height * scale) / 2,
    );
    return clamp(make(scale, t), viewport, content);
  }

  /// The required render width (pixels) for a page drawn [pageWidth] logical
  /// pixels wide at [scale] on a screen with [dpr].
  static double renderWidth(double pageWidth, double scale, double dpr) => pageWidth * scale * dpr;
}
