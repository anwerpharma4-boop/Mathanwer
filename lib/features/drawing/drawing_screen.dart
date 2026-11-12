import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app_scope.dart';
import '../../content/book_data.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../services/audio_service.dart';
import '../../widgets/common.dart';
import '../alphabet/alphabet_screen.dart';
import 'outlines.dart';

/// Colours named in the textbook (Units 1 and 5) plus purple (story p.79).
const List<Color> drawingColours = [
  Color(0xFFE53935), // red
  Color(0xFF2F6FD6), // blue
  Color(0xFFFFD60A), // yellow
  Color(0xFFFF8C1A), // orange
  Color(0xFF2EAD5B), // green
  Color(0xFFF06AB0), // pink
  Color(0xFF1D1D1F), // black
  Color(0xFF8B5A2B), // brown
  Color(0xFF9AA0A6), // grey
  Color(0xFF8E5CC9), // purple
];

class SavedDrawing {
  const SavedDrawing(this.id, this.bytes);
  final String id;
  final Uint8List bytes;
}

/// Where finished drawings are kept: app files on Android, the browser's
/// local storage on the web (iPad Safari).
abstract class DrawingStore {
  Future<void> save(Uint8List png);
  Future<List<SavedDrawing>> list();
  Future<void> delete(String id);

  /// Size of saved images (smaller on the web to fit in local storage).
  int get pixels;

  static DrawingStore of(BuildContext context) =>
      kIsWeb ? _PrefsDrawingStore(AppScope.read(context).settings.prefs) : _FileDrawingStore();
}

class _FileDrawingStore extends DrawingStore {
  @override
  int get pixels => 1024;

  Future<Directory> _dir() async {
    final d = Directory(p.join((await getApplicationDocumentsDirectory()).path, 'drawings'));
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  @override
  Future<void> save(Uint8List png) async {
    final d = await _dir();
    await File(p.join(d.path, 'drawing_${DateTime.now().millisecondsSinceEpoch}.png')).writeAsBytes(png);
  }

  @override
  Future<List<SavedDrawing>> list() async {
    final d = await _dir();
    final files = d.listSync().whereType<File>().where((f) => f.path.endsWith('.png')).toList()
      ..sort((a, b) => b.path.compareTo(a.path));
    return [for (final f in files) SavedDrawing(f.path, f.readAsBytesSync())];
  }

  @override
  Future<void> delete(String id) => File(id).delete();
}

class _PrefsDrawingStore extends DrawingStore {
  _PrefsDrawingStore(this.prefs);
  final SharedPreferences prefs;
  static const _key = 'drawings_v1';
  static const _max = 12;

  @override
  int get pixels => 512;

  List<String> get _raw => prefs.getStringList(_key) ?? [];

  @override
  Future<void> save(Uint8List png) async {
    final entry = '${DateTime.now().millisecondsSinceEpoch}:${base64Encode(png)}';
    final all = [entry, ..._raw];
    await prefs.setStringList(_key, all.take(_max).toList());
  }

  @override
  Future<List<SavedDrawing>> list() async => [
    for (final e in _raw) SavedDrawing(e.substring(0, e.indexOf(':')), base64Decode(e.substring(e.indexOf(':') + 1))),
  ];

  @override
  Future<void> delete(String id) async => prefs.setStringList(_key, _raw.where((e) => !e.startsWith('$id:')).toList());
}

class DrawingHomeScreen extends StatelessWidget {
  const DrawingHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: context.tr('drawing'),
      colour: AppColors.coral,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 130,
                  child: BigTile(
                    key: const ValueKey('freeDraw'),
                    title: context.tr('freeDraw'),
                    icon: Icons.brush_rounded,
                    colour: AppColors.coral,
                    onTap: () =>
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DrawingCanvasScreen())),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 130,
                  child: BigTile(
                    title: context.tr('trace'),
                    icon: Icons.gesture_rounded,
                    colour: AppColors.grape,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AlphabetScreen())),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(context.tr('colouring'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, c) {
              final cols = gridColumns(c.maxWidth, minTile: 140);
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: cols,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  for (final page in colouringPages)
                    Material(
                      key: ValueKey('colour_${page.id}'),
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () =>
                            Navigator.of(context)
                                .push(MaterialPageRoute(builder: (_) => DrawingCanvasScreen(outline: page))),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            children: [
                              Expanded(
                                child: CustomPaint(painter: _OutlinePreview(page), size: Size.infinite),
                              ),
                              EnglishContent(child: Text(page.word, style: learningText(18))),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          Text(context.tr('myDrawings'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const _Gallery(),
        ],
      ),
    );
  }
}

class _OutlinePreview extends CustomPainter {
  _OutlinePreview(this.page);
  final ColouringPage page;
  @override
  void paint(Canvas canvas, Size size) => paintOutline(canvas, Size.square(size.shortestSide), page.build());
  @override
  bool shouldRepaint(_OutlinePreview old) => false;
}

class _Gallery extends StatefulWidget {
  const _Gallery();
  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  List<SavedDrawing> _files = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final files = await DrawingStore.of(context).list();
      if (mounted) setState(() => _files = files);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_files.isEmpty) return Text(context.tr('noData'), style: const TextStyle(color: AppColors.inkSoft));
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final f in _files)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(f.bytes, width: 120, height: 120, fit: BoxFit.cover, cacheWidth: 240),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: IconButton(
                  icon: const Icon(Icons.delete_rounded, color: Colors.white),
                  style: IconButton.styleFrom(backgroundColor: Colors.black38, minimumSize: const Size(36, 36)),
                  onPressed: () async {
                    await DrawingStore.of(context).delete(f.id);
                    _load();
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class Stroke {
  Stroke(this.colour, this.width, this.eraser);
  final Color colour;
  final double width;
  final bool eraser;
  final List<Offset> points = [];
}

/// Finger drawing / colouring canvas. Strokes are stored in unit coordinates
/// so drawings survive rotation and resizing.
class DrawingCanvasScreen extends StatefulWidget {
  const DrawingCanvasScreen({super.key, this.outline});
  final ColouringPage? outline;

  @override
  State<DrawingCanvasScreen> createState() => DrawingCanvasScreenState();
}

class DrawingCanvasScreenState extends State<DrawingCanvasScreen> {
  final List<Stroke> strokes = [];
  Color _colour = drawingColours.first;
  double _width = 0.025;
  bool _eraser = false;
  double _side = 1;

  void undo() => setState(() {
    if (strokes.isNotEmpty) strokes.removeLast();
  });

  void clear() => setState(strokes.clear);

  Future<bool> save() async {
    final store = DrawingStore.of(context);
    final px = store.pixels.toDouble();
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    _DrawingPainter(strokes, widget.outline).paint(canvas, Size(px, px));
    final img = await rec.endRecording().toImage(px.toInt(), px.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    if (bytes == null) return false;
    try {
      await store.save(bytes.buffer.asUint8List());
      if (!mounted) return true;
      final services = AppScope.read(context);
      services.audio.sfx(Sfx.star);
      await services.progress.recordResult(kind: 'drawing', ref: widget.outline?.id ?? 'free', score: 1, total: 1);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('saved'))));
      }
      return true;
    } catch (e) {
      debugPrint('Saving drawing failed: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final word = widget.outline == null ? null : vocabularyById[wordId(widget.outline!.word)];
    return AppPage(
      title: widget.outline == null ? context.tr('freeDraw') : '${context.tr('colouring')}: ${widget.outline!.word}',
      colour: AppColors.coral,
      actions: [
        if (word != null) SpeakButton(text: word.spoken, size: 44),
        IconButton(
          key: const ValueKey('drawUndo'),
          tooltip: 'Undo',
          onPressed: undo,
          icon: const Icon(Icons.undo_rounded),
        ),
        IconButton(
          key: const ValueKey('drawClear'),
          tooltip: context.tr('clear'),
          onPressed: clear,
          icon: const Icon(Icons.delete_sweep_rounded),
        ),
        IconButton(
          key: const ValueKey('drawSave'),
          tooltip: context.tr('save'),
          onPressed: save,
          icon: const Icon(Icons.save_alt_rounded),
        ),
      ],
      body: LayoutBuilder(
        builder: (context, c) {
          final landscape = c.maxWidth > c.maxHeight;
          final tools = _Tools(
            colour: _colour,
            width: _width,
            eraser: _eraser,
            vertical: landscape,
            onColour: (col) => setState(() {
              _colour = col;
              _eraser = false;
            }),
            onWidth: (w) => setState(() => _width = w),
            onEraser: () => setState(() => _eraser = !_eraser),
          );
          final canvasArea = LayoutBuilder(
            builder: (context, cc) {
              _side = (cc.maxWidth < cc.maxHeight ? cc.maxWidth : cc.maxHeight) - 16;
              return Center(
                child: Container(
                  width: _side,
                  height: _side,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10)],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: GestureDetector(
                      key: const ValueKey('drawingSurface'),
                      onPanStart: (d) => setState(
                        () => strokes.add(
                          Stroke(_colour, _eraser ? _width * 2 : _width, _eraser)..points.add(d.localPosition / _side),
                        ),
                      ),
                      onPanUpdate: (d) => setState(() => strokes.last.points.add(d.localPosition / _side)),
                      child: CustomPaint(size: Size.square(_side), painter: _DrawingPainter(strokes, widget.outline)),
                    ),
                  ),
                ),
              );
            },
          );
          return landscape
              ? Row(
                  children: [
                    tools,
                    Expanded(child: canvasArea),
                  ],
                )
              : Column(
                  children: [
                    Expanded(child: canvasArea),
                    tools,
                  ],
                );
        },
      ),
    );
  }
}

class _Tools extends StatelessWidget {
  const _Tools({
    required this.colour,
    required this.width,
    required this.eraser,
    required this.vertical,
    required this.onColour,
    required this.onWidth,
    required this.onEraser,
  });
  final Color colour;
  final double width;
  final bool eraser;
  final bool vertical;
  final ValueChanged<Color> onColour;
  final ValueChanged<double> onWidth;
  final VoidCallback onEraser;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      for (final c in drawingColours)
        GestureDetector(
          onTap: () => onColour(c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.all(4),
            width: !eraser && c == colour ? 46 : 38,
            height: !eraser && c == colour ? 46 : 38,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
            ),
          ),
        ),
      const SizedBox(width: 8, height: 8),
      for (final w in [0.012, 0.025, 0.05])
        IconButton(
          tooltip: context.tr('brush'),
          isSelected: width == w,
          onPressed: () => onWidth(w),
          icon: Icon(Icons.circle, size: 8 + w * 360),
        ),
      IconButton(
        key: const ValueKey('eraser'),
        tooltip: context.tr('eraser'),
        isSelected: eraser,
        onPressed: onEraser,
        icon: Icon(Icons.auto_fix_normal_rounded, color: eraser ? AppColors.coral : null),
      ),
    ];
    return Material(
      color: Colors.white,
      elevation: 2,
      child: SafeArea(
        top: false,
        child: vertical
            ? SizedBox(
                width: 120,
                child: SingleChildScrollView(
                  child: Wrap(alignment: WrapAlignment.center, children: children),
                ),
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(6),
                child: Row(children: children),
              ),
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  _DrawingPainter(this.strokes, this.outline);
  final List<Stroke> strokes;
  final ColouringPage? outline;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    canvas.saveLayer(Offset.zero & size, Paint());
    for (final st in strokes) {
      final paint = Paint()
        ..color = st.eraser ? Colors.transparent : st.colour
        ..blendMode = st.eraser ? BlendMode.clear : BlendMode.srcOver
        ..strokeWidth = st.width * s
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      if (st.points.length == 1) {
        canvas.drawCircle(st.points.first * s, st.width * s / 2, paint..style = PaintingStyle.fill);
        continue;
      }
      final path = Path()..moveTo(st.points.first.dx * s, st.points.first.dy * s);
      for (final pt in st.points.skip(1)) {
        path.lineTo(pt.dx * s, pt.dy * s);
      }
      canvas.drawPath(path, paint);
    }
    canvas.restore();
    // The outline stays on top so colouring never hides the lines.
    if (outline != null) paintOutline(canvas, Size(s, s), outline!.build());
  }

  @override
  bool shouldRepaint(_DrawingPainter old) => true;
}
