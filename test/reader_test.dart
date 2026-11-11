import 'package:english_for_iraq/features/reader/reader_screen.dart';
import 'package:english_for_iraq/features/reader/zoom_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';

ReaderScreenState _reader(WidgetTester t) => t.state<ReaderScreenState>(find.byType(ReaderScreen));

Future<void> _pinch(WidgetTester tester, Offset centre, double from, double to) async {
  final a = await tester.startGesture(centre - Offset(from, 0), pointer: 1);
  final b = await tester.startGesture(centre + Offset(from, 0), pointer: 2);
  await tester.pump();
  const steps = 10;
  for (var i = 1; i <= steps; i++) {
    final d = from + (to - from) * i / steps;
    await a.moveTo(centre - Offset(d, 0));
    await b.moveTo(centre + Offset(d, 0));
    await tester.pump(const Duration(milliseconds: 16));
  }
  await a.up();
  await b.up();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('opens at the requested page and navigates with buttons and slider', (tester) async {
    await pumpApp(tester, home: const ReaderScreen(initialPage: 8, continuous: false));
    await tester.pumpAndSettle();
    expect(find.text('Page 8 / 96'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('nextPage')));
    await tester.pumpAndSettle();
    expect(_reader(tester).page, 9);
    await tester.tap(find.byKey(const ValueKey('prevPage')));
    await tester.tap(find.byKey(const ValueKey('prevPage')));
    await tester.pumpAndSettle();
    expect(_reader(tester).page, 7);
    _reader(tester).goTo(96);
    await tester.pumpAndSettle();
    expect(find.text('Page 96 / 96'), findsOneWidget);
    _reader(tester).goTo(500);
    await tester.pumpAndSettle();
    expect(_reader(tester).page, 96, reason: 'clamped to the last page');
  });

  testWidgets('every one of the 96 pages can be displayed', (tester) async {
    final s = await pumpApp(tester, home: const ReaderScreen(initialPage: 1, continuous: false));
    await tester.pumpAndSettle();
    for (var p = 1; p <= 96; p++) {
      _reader(tester).goTo(p);
      await tester.pump();
    }
    await tester.pumpAndSettle();
    final requested = (s.book as FakeBookSource).requests.map((r) => int.parse(r.split('@').first)).toSet();
    expect(requested, containsAll(List.generate(96, (i) => i + 1)));
  });

  testWidgets('two-finger pinch zooms in continuously and one-finger drag pans', (tester) async {
    await pumpApp(tester, home: const ReaderScreen(initialPage: 10, continuous: false));
    await tester.pumpAndSettle();
    final viewer = find.byKey(const ValueKey('singleViewer'));
    final centre = tester.getCenter(viewer);
    await _pinch(tester, centre, 40, 140);
    final r = _reader(tester);
    expect(r.scale, greaterThan(2.5), reason: 'pinch should zoom (got ${r.scale})');
    expect(r.page, 10, reason: 'zooming must not change the page');

    final before = ZoomMath.translationOf(r.transformation.value);
    await tester.timedDrag(viewer, const Offset(-80, -120), const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    final after = ZoomMath.translationOf(r.transformation.value);
    expect(after.dx, lessThan(before.dx), reason: 'horizontal pan');
    expect(after.dy, lessThan(before.dy), reason: 'vertical pan');
    expect(r.scale, greaterThan(2.5), reason: 'panning must not reset zoom');
    expect(r.page, 10, reason: 'panning while zoomed must not turn the page');

    // Drag far beyond the edge: movement is constrained at the page boundary.
    await tester.timedDrag(viewer, const Offset(3000, 3000), const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    final t = ZoomMath.translationOf(r.transformation.value);
    expect(t.dx, closeTo(0, 1));
    expect(t.dy, closeTo(0, 1));

    // Pinch out again (zoom out).
    await _pinch(tester, centre, 140, 50);
    expect(r.scale, lessThan(2.0));
  });

  testWidgets('double-tap zooms in and double-tap again resets', (tester) async {
    await pumpApp(tester, home: const ReaderScreen(initialPage: 20, continuous: false));
    await tester.pumpAndSettle();
    final viewer = find.byKey(const ValueKey('singleViewer'));
    await tester.tap(viewer);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tap(viewer);
    await tester.pumpAndSettle();
    expect(_reader(tester).scale, closeTo(ZoomMath.doubleTapScale, 0.05));
    await tester.tap(viewer);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tap(viewer);
    await tester.pumpAndSettle();
    expect(_reader(tester).scale, closeTo(1, 0.01));
  });

  testWidgets('swipe turns pages when not zoomed', (tester) async {
    await pumpApp(tester, home: const ReaderScreen(initialPage: 30, continuous: false));
    await tester.pumpAndSettle();
    final viewer = find.byKey(const ValueKey('singleViewer'));
    await tester.fling(viewer, const Offset(-250, 0), 1200);
    await tester.pumpAndSettle();
    expect(_reader(tester).page, 31);
    await tester.fling(viewer, const Offset(250, 0), 1200);
    await tester.pumpAndSettle();
    expect(_reader(tester).page, 30);
  });

  testWidgets('zoom buttons: +, fit width, fit page, reset', (tester) async {
    await pumpApp(tester, home: const ReaderScreen(initialPage: 12, continuous: false), size: const Size(900, 500));
    await tester.pumpAndSettle();
    final r = _reader(tester);
    await tester.tap(find.byKey(const ValueKey('zoomIn')));
    await tester.pumpAndSettle();
    expect(r.scale, closeTo(1.5, 0.01));
    await tester.tap(find.byKey(const ValueKey('fitWidth')));
    await tester.pumpAndSettle();
    expect(r.scale, greaterThan(2), reason: 'landscape fit-width enlarges the page');
    await tester.tap(find.byKey(const ValueKey('fitPage')));
    await tester.pumpAndSettle();
    expect(r.scale, closeTo(1, 0.01));
    await tester.tap(find.byKey(const ValueKey('zoomIn')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('resetZoom')));
    await tester.pumpAndSettle();
    expect(r.scale, closeTo(1, 0.01));
  });

  testWidgets('continuous mode scrolls through pages and supports pinch zoom', (tester) async {
    await pumpApp(tester, home: const ReaderScreen(initialPage: 1, continuous: true));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('continuousViewer')), findsOneWidget);
    final viewer = find.byKey(const ValueKey('continuousViewer'));
    for (var i = 0; i < 4; i++) {
      await tester.drag(viewer, const Offset(0, -500));
      await tester.pumpAndSettle();
    }
    expect(_reader(tester).page, greaterThan(1), reason: 'scrolling moves to later pages');
    final p = _reader(tester).page;
    // Scaling starts after the touch slop, so measure from a wide pinch.
    await _pinch(tester, tester.getCenter(viewer), 40, 170);
    expect(_reader(tester).scale, greaterThan(2));
    expect((_reader(tester).page - p).abs(), lessThanOrEqualTo(1));
    _reader(tester).goTo(60);
    await tester.pumpAndSettle();
    expect(_reader(tester).page, 60);
  });

  testWidgets('mode toggle, fullscreen and bookmark', (tester) async {
    final s = await pumpApp(tester, home: const ReaderScreen(initialPage: 44, continuous: false));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bookmarkButton')));
    await settle(tester);
    expect(s.progress.isBookmarked(44), isTrue);
    await tester.tap(find.byKey(const ValueKey('modeButton')));
    await tester.pumpAndSettle();
    expect(_reader(tester).continuous, isTrue);
    expect(_reader(tester).page, 44);
    await tester.tap(find.byKey(const ValueKey('fullscreenButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('nextPage')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('exitFullscreen')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('nextPage')), findsOneWidget);
  });

  testWidgets('navigator: thumbnails and search jump to pages', (tester) async {
    await pumpApp(tester, home: const ReaderScreen(initialPage: 1, continuous: false));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('navigatorButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();
    expect(_reader(tester).page, 3);

    await tester.tap(find.byKey(const ValueKey('navigatorButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.search_rounded).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('pageSearchField')), 'family');
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('My family').first);
    await tester.pumpAndSettle();
    expect(_reader(tester).page, 64);
  });
}
