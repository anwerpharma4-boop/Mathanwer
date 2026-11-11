import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import '../../app_scope.dart';
import '../../services/book_source.dart';

/// Displays one original textbook page, rasterised at (at least) [targetWidthPx].
/// While a sharper render is loading, the previous render stays visible.
class PdfPageImage extends StatefulWidget {
  const PdfPageImage({super.key, required this.page, required this.targetWidthPx, this.source});

  final int page;
  final double targetWidthPx;

  /// Optional explicit source (defaults to the app's book).
  final BookSource? source;

  @override
  State<PdfPageImage> createState() => _PdfPageImageState();
}

class _PdfPageImageState extends State<PdfPageImage> {
  Uint8List? _bytes;
  int _loadedTier = 0;
  int _requestedTier = 0;
  bool _failed = false;

  BookSource get _source => widget.source ?? AppScope.read(context).book;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensure();
  }

  @override
  void didUpdateWidget(PdfPageImage old) {
    super.didUpdateWidget(old);
    if (old.page != widget.page) {
      _bytes = null;
      _loadedTier = 0;
      _requestedTier = 0;
      _failed = false;
    }
    _ensure();
  }

  void _ensure() {
    final tier = tierFor(widget.targetWidthPx);
    if (tier <= _loadedTier || tier == _requestedTier) return;
    _requestedTier = tier;
    final page = widget.page;
    _source.render(page, tier, isWanted: () => mounted && widget.page == page).then((bytes) {
      if (!mounted || widget.page != page) return;
      if (bytes == null) {
        if (_bytes == null) setState(() => _failed = true);
        _requestedTier = _loadedTier;
        return;
      }
      if (tier >= _loadedTier) {
        setState(() {
          _bytes = bytes;
          _loadedTier = tier;
          _failed = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    return Semantics(
      label: 'Textbook page ${widget.page}',
      image: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: bytes != null
            ? Image.memory(
                bytes,
                key: ValueKey('img_${widget.page}'),
                fit: BoxFit.fill,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
              )
            : Center(
                child: _failed
                    ? IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 40),
                        onPressed: () {
                          setState(() => _failed = false);
                          _requestedTier = 0;
                          _ensure();
                        },
                      )
                    : Column(mainAxisSize: MainAxisSize.min, children: [
                        const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)),
                        const SizedBox(height: 8),
                        Text('${widget.page}', style: const TextStyle(color: Colors.black38, fontSize: 18)),
                      ]),
              ),
      ),
    );
  }
}
