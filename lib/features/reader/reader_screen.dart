import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../app_scope.dart';
import '../../content/book_data.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/progress_store.dart';
import 'page_image.dart';
import 'reader_navigator_sheet.dart';
import 'zoom_math.dart';

/// Reader for the original, unmodified 96-page textbook PDF.
///
/// Gestures: two-finger pinch zoom (continuous, 1x-12x), one-finger panning
/// in every direction (clamped at the page edges), double-tap zoom, swipe to
/// turn pages in single-page mode.
class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, this.initialPage = 1, this.continuous});

  /// PDF page index (1-based). In this book PDF index == printed page number.
  final int initialPage;
  final bool? continuous;

  @override
  State<ReaderScreen> createState() => ReaderScreenState();
}

class ReaderScreenState extends State<ReaderScreen> with SingleTickerProviderStateMixin {
  static const double _gap = 12;

  late int _page;
  late bool _continuous;
  bool _fullscreen = false;
  bool _chromeVisible = true;
  final TransformationController _tc = TransformationController();
  late final AnimationController _anim =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
  Animation<Matrix4>? _matrixAnim;
  Size _viewport = Size.zero;
  double _settledScale = 1;
  Offset _doubleTapPos = Offset.zero;
  int _pointers = 0;
  double _dragDx = 0;
  double _dragDy = 0;
  Timer? _saveTimer;
  bool _openedBook = false;
  bool _bookError = false;
  late ProgressStore _progress;

  int get pageCount => AppScope.read(context).book.pageCount;
  int get page => _page;
  bool get continuous => _continuous;
  double get scale => ZoomMath.scaleOf(_tc.value);
  TransformationController get transformation => _tc;

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage.clamp(1, bookPageCount);
    _anim.addListener(() {
      final a = _matrixAnim;
      if (a != null) _tc.value = a.value;
    });
    _anim.addStatusListener((s) {
      if (s == AnimationStatus.completed) _settle();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_openedBook) {
      _openedBook = true;
      final services = AppScope.read(context);
      _progress = services.progress;
      _continuous = widget.continuous ?? services.settings.readerContinuous;
      services.book.open().catchError((Object e) {
        if (mounted) setState(() => _bookError = true);
      });
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _progress.setLastReaderPage(_page);
    if (_fullscreen) SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _anim.dispose();
    _tc.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------ layout
  Rect get _singlePageRect => ZoomMath.fitPage(_viewport, AppScope.read(context).book.aspectRatio);

  Size get _pageSize => _singlePageRect.size;

  Rect pageRectContinuous(int p) {
    final s = _pageSize;
    return Rect.fromLTWH((_viewport.width - s.width) / 2, _gap + (p - 1) * (s.height + _gap), s.width, s.height);
  }

  Size get _contentSize => _continuous
      ? Size(_viewport.width, _gap + pageCount * (_pageSize.height + _gap))
      : _viewport;

  Rect get _currentPageRect => _continuous ? pageRectContinuous(_page) : _singlePageRect;

  // ------------------------------------------------------------------ zoom
  void _animateTo(Matrix4 target) {
    _matrixAnim = Matrix4Tween(begin: _tc.value.clone(), end: target)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _anim.forward(from: 0);
  }

  void _settle() {
    final s = scale;
    if ((s - _settledScale).abs() > 0.01) setState(() => _settledScale = s);
  }

  void fitWidth() => _animateTo(ZoomMath.fitWidth(_viewport, _contentSize, _currentPageRect));

  void fitPage() => _animateTo(_continuous
      ? ZoomMath.showPage(_viewport, _contentSize, pageRectContinuous(_page))
      : Matrix4.identity());

  void resetZoom() => fitPage();

  void zoomBy(double factor) {
    final c = Offset(_viewport.width / 2, _viewport.height / 2);
    _animateTo(ZoomMath.zoomAt(_tc.value, c, scale * factor, _viewport, _contentSize));
  }

  void _onDoubleTap() {
    if (scale > 1.05) {
      fitPage();
    } else {
      _animateTo(ZoomMath.zoomAt(_tc.value, _doubleTapPos, ZoomMath.doubleTapScale, _viewport, _contentSize));
    }
  }

  // ------------------------------------------------------------------ paging
  void goTo(int p, {bool animate = false}) {
    final target = p.clamp(1, pageCount);
    _anim.stop();
    setState(() {
      _page = target;
      if (!_continuous) {
        _tc.value = Matrix4.identity();
        _settledScale = 1;
      }
    });
    if (_continuous && _viewport != Size.zero) {
      final s = math.max(1.0, scale);
      final r = pageRectContinuous(target);
      final m = ZoomMath.clamp(ZoomMath.make(s, Offset(ZoomMath.translationOf(_tc.value).dx, -r.top * s + _gap)),
          _viewport, _contentSize);
      if (animate) {
        _animateTo(m);
      } else {
        _tc.value = m;
      }
    }
    _scheduleSave();
  }

  void next() => goTo(_page + 1);
  void previous() => goTo(_page - 1);

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) _progress.setLastReaderPage(_page);
    });
  }

  void setContinuous(bool v) {
    if (v == _continuous) return;
    AppScope.read(context).settings.setReaderContinuous(v);
    setState(() {
      _continuous = v;
      _tc.value = Matrix4.identity();
      _settledScale = 1;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) goTo(_page);
    });
  }

  void _toggleFullscreen() {
    setState(() {
      _fullscreen = !_fullscreen;
      _chromeVisible = !_fullscreen;
    });
    SystemChrome.setEnabledSystemUIMode(_fullscreen ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge);
  }

  Future<void> _openNavigator() async {
    final p = await showReaderNavigator(context, currentPage: _page);
    if (p != null && mounted) goTo(p);
  }

  // ------------------------------------------------------------------ build
  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final showChrome = !_fullscreen || _chromeVisible;
    return Scaffold(
      backgroundColor: const Color(0xFFE9EDF3),
      body: SafeArea(
        top: !_fullscreen,
        bottom: !_fullscreen,
        child: Column(
          children: [
            if (showChrome) _topBar(context, services),
            Expanded(
              child: _bookError
                  ? Center(child: Text(context.tr('bookError'), style: const TextStyle(fontSize: 18)))
                  : LayoutBuilder(builder: (context, c) {
                      final size = Size(c.maxWidth, c.maxHeight);
                      if (size != _viewport) {
                        final first = _viewport == Size.zero;
                        _viewport = size;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          if (first || _continuous) {
                            goTo(_page);
                          } else {
                            _tc.value = ZoomMath.clamp(_tc.value, _viewport, _contentSize);
                          }
                        });
                      }
                      return Stack(children: [
                        Positioned.fill(child: _continuous ? _continuousView(context) : _singleView(context)),
                        if (scale > 1.01)
                          Positioned(
                            left: 12,
                            top: 12,
                            child: IgnorePointer(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(14)),
                                child: Text('${scale.toStringAsFixed(1)}×',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ),
                        if (_fullscreen)
                          Positioned(
                            right: 12,
                            top: 12,
                            child: Material(
                              color: Colors.black45,
                              shape: const CircleBorder(),
                              child: IconButton(
                                key: const ValueKey('exitFullscreen'),
                                icon: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white),
                                onPressed: _toggleFullscreen,
                              ),
                            ),
                          ),
                      ]);
                    }),
            ),
            if (showChrome) _bottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context, AppServices services) {
    return ListenableBuilder(
      listenable: services.progress,
      builder: (context, _) {
        final marked = services.progress.isBookmarked(_page);
        return Material(
          color: Colors.white,
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(children: [
              IconButton(
                tooltip: context.tr('back'),
                icon: const BackButtonIcon(),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text('${context.tr('page')} $_page / $pageCount',
                      key: const ValueKey('pageLabel'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  EnglishContent(
                    child: Text(describePage(_page),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                  ),
                ]),
              ),
              IconButton(
                key: const ValueKey('bookmarkButton'),
                tooltip: context.tr('bookmarks'),
                icon: Icon(marked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: marked ? AppColors.coral : null),
                onPressed: () => services.progress.toggleBookmark(_page),
              ),
              IconButton(
                key: const ValueKey('navigatorButton'),
                tooltip: '${context.tr('thumbnails')} / ${context.tr('search')}',
                icon: const Icon(Icons.grid_view_rounded),
                onPressed: _openNavigator,
              ),
              IconButton(
                key: const ValueKey('modeButton'),
                tooltip: _continuous ? context.tr('singlePage') : context.tr('continuous'),
                icon: Icon(_continuous ? Icons.crop_portrait_rounded : Icons.view_day_rounded),
                onPressed: () => setContinuous(!_continuous),
              ),
              IconButton(
                key: const ValueKey('fullscreenButton'),
                tooltip: context.tr('fullscreen'),
                icon: const Icon(Icons.fullscreen_rounded),
                onPressed: _toggleFullscreen,
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _bottomBar(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 2, 4, 4),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            IconButton(
              key: const ValueKey('prevPage'),
              tooltip: context.tr('previousPage'),
              icon: const Icon(Icons.chevron_left_rounded, size: 34),
              onPressed: _page > 1 ? previous : null,
            ),
            Expanded(
              child: Slider(
                value: _page.toDouble(),
                min: 1,
                max: pageCount.toDouble(),
                divisions: pageCount - 1,
                label: '$_page',
                onChanged: (v) => goTo(v.round()),
              ),
            ),
            IconButton(
              key: const ValueKey('nextPage'),
              tooltip: context.tr('nextPage'),
              icon: const Icon(Icons.chevron_right_rounded, size: 34),
              onPressed: _page < pageCount ? next : null,
            ),
          ]),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _zoomButton(Icons.zoom_out_rounded, '−', () => zoomBy(1 / 1.5), const ValueKey('zoomOut')),
              _zoomButton(Icons.zoom_in_rounded, '+', () => zoomBy(1.5), const ValueKey('zoomIn')),
              _zoomButton(Icons.width_full_rounded, context.tr('fitWidth'), fitWidth, const ValueKey('fitWidth')),
              _zoomButton(Icons.fit_screen_rounded, context.tr('fitPage'), fitPage, const ValueKey('fitPage')),
              _zoomButton(Icons.restart_alt_rounded, context.tr('resetZoom'), resetZoom, const ValueKey('resetZoom')),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _zoomButton(IconData icon, String label, VoidCallback onTap, Key key) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: TextButton.icon(
          key: key,
          onPressed: onTap,
          icon: Icon(icon),
          label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      );

  double get _dpr => MediaQuery.devicePixelRatioOf(context);

  Widget _gestures({required Widget child}) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _fullscreen ? () => setState(() => _chromeVisible = !_chromeVisible) : null,
        onDoubleTapDown: (d) => _doubleTapPos = d.localPosition,
        onDoubleTap: _onDoubleTap,
        child: child,
      );

  Widget _singleView(BuildContext context) {
    final rect = _singlePageRect;
    return _gestures(
      child: InteractiveViewer(
        key: const ValueKey('singleViewer'),
        transformationController: _tc,
        minScale: ZoomMath.minScale,
        maxScale: ZoomMath.maxScale,
        boundaryMargin: EdgeInsets.zero,
        clipBehavior: Clip.hardEdge,
        onInteractionStart: (d) {
          _anim.stop();
          _pointers = d.pointerCount;
          _dragDx = 0;
          _dragDy = 0;
        },
        onInteractionUpdate: (d) {
          _pointers = math.max(_pointers, d.pointerCount);
          _dragDx += d.focalPointDelta.dx;
          _dragDy += d.focalPointDelta.dy;
          if (scale > 1.01 || _settledScale > 1.01) setState(() {});
        },
        onInteractionEnd: (d) {
          final zoomed = scale > 1.02;
          final v = d.velocity.pixelsPerSecond;
          final horizontal = _dragDx.abs() > _dragDy.abs() * 1.3;
          if (!zoomed && _pointers == 1 && horizontal) {
            final fast = v.dx.abs() > 350;
            final far = _dragDx.abs() > _viewport.width * 0.22;
            if (fast || far) {
              final dir = (fast ? v.dx : _dragDx) < 0 ? 1 : -1;
              // The book is English (left-to-right): swipe left = next page.
              goTo(_page + dir);
              return;
            }
          }
          _settle();
        },
        child: SizedBox.fromSize(
          size: _viewport,
          child: Stack(children: [
            Positioned.fromRect(
              rect: rect,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: PdfPageImage(
                  key: ValueKey('page_$_page'),
                  page: _page,
                  targetWidthPx: ZoomMath.renderWidth(rect.width, _settledScale, _dpr),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _continuousView(BuildContext context) {
    final content = _contentSize;
    final ps = _pageSize;
    return _gestures(
      child: InteractiveViewer.builder(
        key: const ValueKey('continuousViewer'),
        transformationController: _tc,
        minScale: ZoomMath.minScale,
        maxScale: ZoomMath.maxScale,
        boundaryMargin: EdgeInsets.zero,
        onInteractionStart: (_) => _anim.stop(),
        onInteractionEnd: (_) => _settle(),
        builder: (context, quad) {
          final xs = [quad.point0.x, quad.point1.x, quad.point2.x, quad.point3.x];
          final ys = [quad.point0.y, quad.point1.y, quad.point2.y, quad.point3.y];
          final top = ys.reduce(math.min);
          final bottom = ys.reduce(math.max);
          final unit = ps.height + _gap;
          final first = (((top - _gap) / unit).floor() + 1).clamp(1, pageCount);
          final last = (((bottom - _gap) / unit).floor() + 1).clamp(1, pageCount);
          final centre = ((((top + bottom) / 2 - _gap) / unit).floor() + 1).clamp(1, pageCount);
          if (centre != _page) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && centre != _page) {
                setState(() => _page = centre);
                _scheduleSave();
              }
            });
          }
          // xs is unused for layout but documents the viewport quad.
          assert(xs.length == 4);
          return SizedBox(
            width: content.width,
            height: content.height,
            child: Stack(children: [
              for (var p = math.max(1, first - 1); p <= math.min(pageCount, last + 1); p++)
                Positioned.fromRect(
                  key: ValueKey('cpage_$p'),
                  rect: pageRectContinuous(p),
                  child: PdfPageImage(
                    page: p,
                    // Only the centre page gets the sharpest render (memory).
                    targetWidthPx: ZoomMath.renderWidth(ps.width, p == centre ? _settledScale : math.min(_settledScale, 1.5), _dpr),
                  ),
                ),
            ]),
          );
        },
      ),
    );
  }
}
